import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';

/// Navigates nav-add → Lunch → search for the sample main dish → tap the
/// row to open the food detail page, at the given viewport size and locale.
Future<AppState> _openSampleMainDetail(
  WidgetTester tester, {
  String locale = 'en',
  Size size = const Size(375, 812),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
  await state.load();
  state.localeCode = locale;
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('nav-add')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(locale == 'ar' ? 'الغداء' : 'Lunch').last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextField),
    locale == 'ar' ? 'طبق رئيسي تجريبي أ' : 'sample main dish a',
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .text(locale == 'ar' ? 'طبق رئيسي تجريبي أ' : 'Sample Main Dish A')
        .last,
  );
  await tester.pumpAndSettle();
  return state;
}

void main() {
  for (final size in [const Size(375, 812), const Size(320, 640)]) {
    testWidgets('food detail page renders without overflow at '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await _openSampleMainDetail(tester, size: size);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Add ·'), findsOneWidget);
    });
  }

  testWidgets('food detail page is RTL with Western digits', (tester) async {
    await _openSampleMainDetail(tester, locale: 'ar');
    expect(tester.takeException(), isNull);

    final context = tester.element(find.text('طبق رئيسي تجريبي أ').first);
    expect(Directionality.of(context), TextDirection.rtl);

    // No Eastern-Arabic-Indic digit ever appears; numbers render Western.
    for (final digit in '٠١٢٣٤٥٦٧٨٩'.split('')) {
      expect(find.textContaining(digit), findsNothing, reason: digit);
    }
    expect(find.textContaining('540'), findsWidgets); // Add button total
    expect(find.text('540'), findsOneWidget); // donut-center kcal, always on
  });

  testWidgets(
    'fractional and decimal modes produce the same total for the same value',
    (tester) async {
      await _openSampleMainDetail(tester);

      // Decimal mode: default 1 → step +0.5 → 1.5 servings × 540 kcal = 810.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('1.5'), findsOneWidget);
      expect(find.textContaining('Add · 810 kcal'), findsOneWidget);

      // Switch to fraction mode: the value CONVERTS (1.5 → 1 whole + ½),
      // it does not reset — same total with no further chip taps.
      await tester.tap(find.text('Fraction'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Add · 810 kcal'), findsOneWidget);

      // And back to decimal: converts again, doesn't reset to 1.
      await tester.tap(find.text('Decimal'));
      await tester.pumpAndSettle();
      expect(find.text('1.5'), findsOneWidget);
      expect(find.textContaining('Add · 810 kcal'), findsOneWidget);
    },
  );

  testWidgets('fractional 2 and 1/2 equals decimal 2.5 in the logged entry', (
    tester,
  ) async {
    final state = await _openSampleMainDetail(tester);

    await tester.tap(find.text('Fraction'));
    await tester.pumpAndSettle();
    // Default whole is 1 — bump to 2, then add the ½ chip.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('½'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Add · 1,350 kcal'), findsOneWidget); // 2.5×540

    await tester.tap(find.textContaining('Add · 1,350 kcal'));
    await tester.pumpAndSettle();
    await tester.pump();

    final entry = state.entriesFor(state.selectedDate).single;
    expect(entry.quantity, 2.5);
    expect(entry.servings, 2.5); // base 'serving' unit: multiplier == quantity
  });

  testWidgets(
    'picking a generic weight unit changes kcal and macro grams by the right ratio',
    (tester) async {
      await _openSampleMainDetail(tester);
      // Base: 1 serving (350 g) = 540 kcal, 75 c / 15 f / 25 p.
      expect(find.text('1 serving (350 g)'), findsOneWidget);

      await tester.tap(find.text('1 serving (350 g)'));
      await tester.pumpAndSettle();
      expect(find.text('This food\'s servings'), findsOneWidget);
      expect(find.text('Weight units'), findsOneWidget);

      await tester.tap(find.text('100 g'));
      await tester.pumpAndSettle();

      // 100/350 of the base serving.
      expect(find.textContaining('Add · 154 kcal'), findsOneWidget);
      expect(find.text('21g'), findsOneWidget); // carbs: 75 × 100/350 ≈ 21
    },
  );

  testWidgets('a liquid food\'s picker sheet offers volume units, not weight', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
    await state.load();
    await tester.pumpWidget(CalorieApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'hawaa full cream');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hawaa Full Cream Milk (UHT)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1 glass (250 ml)'));
    await tester.pumpAndSettle();
    expect(find.text('Volume units'), findsOneWidget);
    expect(find.text('Weight units'), findsNothing);
    expect(find.text('cup'), findsOneWidget);
    expect(find.text('oz'), findsNothing);
  });

  group('no overflow with the unit picker sheet open', () {
    for (final locale in ['en', 'ar']) {
      for (final size in [const Size(375, 812), const Size(320, 640)]) {
        testWidgets('$locale at ${size.width.toInt()}x${size.height.toInt()}', (
          tester,
        ) async {
          await _openSampleMainDetail(tester, locale: locale, size: size);
          final servingLabel = locale == 'ar'
              ? 'حصة (350 جم)'
              : '1 serving (350 g)';
          await tester.tap(find.text(servingLabel));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets(
    'unit picker sheet and fraction chips stay Western-digit in Arabic',
    (tester) async {
      await _openSampleMainDetail(tester, locale: 'ar');
      await tester.tap(find.text('كسور')); // Fraction mode
      await tester.pumpAndSettle();
      await tester.tap(find.text('حصة (350 جم)'));
      await tester.pumpAndSettle();

      for (final digit in '٠١٢٣٤٥٦٧٨٩'.split('')) {
        expect(find.textContaining(digit), findsNothing, reason: digit);
      }
    },
  );

  testWidgets('no verified badge for an unverified food', (tester) async {
    await _openSampleMainDetail(tester);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets(
    'verified badge shows for a verified food and explains itself on tap',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'onboarding_done': true});
      final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
      await state.load();
      await tester.pumpWidget(CalorieApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lunch').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hawaa full cream');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hawaa Full Cream Milk (UHT)'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(
        find.text('Verified against a real product label'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Time row defaults to the injected clock and opens a picker', (
    tester,
  ) async {
    await _openSampleMainDetail(tester);
    expect(find.text('09:30'), findsOneWidget);
    await tester.tap(find.text('09:30'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
  });

  testWidgets('confirming a log attaches loggedAt from the Time row', (
    tester,
  ) async {
    final state = await _openSampleMainDetail(tester);
    await tester.tap(find.textContaining('Add ·'));
    await tester.pumpAndSettle();
    await tester.pump();

    final entry = state.entriesFor(state.selectedDate).single;
    expect(entry.loggedAt, DateTime(2026, 7, 15, 9, 30));
  });
}
