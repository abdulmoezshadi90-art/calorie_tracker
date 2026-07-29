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
    testWidgets(
      'food detail page renders without overflow at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _openSampleMainDetail(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Add ·'), findsOneWidget);
      },
    );
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
    expect(find.text('540'), findsOneWidget); // donut-center kcal
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

      // Switch to fraction mode: 1 whole + ½ = 1.5 — same total.
      await tester.tap(find.text('Fraction'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('½'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('½'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Add · 810 kcal'), findsOneWidget);
    },
  );
}
