import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

Future<AppState> _pumpApp(WidgetTester tester, {String locale = 'en'}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
  await state.load();
  state.localeCode = locale;
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

Future<void> _openHistory(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.history));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('history shows empty message with no logged days', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openHistory(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('No logged days yet'), findsOneWidget);
  });

  testWidgets('history lists one day and opens its read-only view', (
    tester,
  ) async {
    final state = await _pumpApp(tester);
    final day = DateTime(2026, 7, 10);
    state.addEntry(day, 'bazin', 1, MealType.lunch); // 540 kcal
    state.addEntry(day, 'kalee_cheese', 2, MealType.snack); // 260 kcal
    await tester.pumpAndSettle();

    await _openHistory(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Friday, July 10 · 2026'), findsOneWidget);
    expect(find.text('800 / 2,000 kcal'), findsOneWidget);
    expect(find.text('Within goal'), findsOneWidget);

    // Read-only day view: meals, foods, total — and no delete buttons.
    await tester.tap(find.text('Friday, July 10 · 2026'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Snack'), findsOneWidget);
    expect(find.text('Bazin with Sauce'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('800 kcal'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('over-goal day gets the neutral over chip', (tester) async {
    final state = await _pumpApp(tester);
    final day = DateTime(2026, 7, 9);
    for (var i = 0; i < 5; i++) {
      state.addEntry(day, 'bazin', 1, MealType.lunch); // 5 × 540 = 2,700
    }
    await tester.pumpAndSettle();

    await _openHistory(tester);
    expect(find.text('Over goal'), findsOneWidget);
    expect(find.text('2,700 / 2,000 kcal'), findsOneWidget);
  });

  testWidgets('30 logged days render newest-first without overflow', (
    tester,
  ) async {
    final state = await _pumpApp(tester);
    for (var i = 1; i <= 30; i++) {
      state.addEntry(
        DateTime(2026, 7, 15).subtract(Duration(days: i)),
        'kalee_cheese',
        1,
        MealType.snack,
      );
    }
    await tester.pumpAndSettle();

    await _openHistory(tester);
    expect(tester.takeException(), isNull);
    // Newest logged day first.
    final firstTile = tester.getTopLeft(find.text('Tuesday, July 14 · 2026'));
    final laterTile = tester.getTopLeft(find.text('Sunday, July 12 · 2026'));
    expect(firstTile.dy, lessThan(laterTile.dy));
    // Scroll to the bottom; list must survive the full range.
    await tester.fling(find.byType(ListView), const Offset(0, -4000), 3000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Monday, June 15 · 2026'), findsOneWidget);
  });

  testWidgets('history renders RTL with Western digits', (tester) async {
    final state = await _pumpApp(tester, locale: 'ar');
    state.addEntry(DateTime(2026, 7, 10), 'bazin', 1, MealType.lunch);
    await tester.pumpAndSettle();

    await _openHistory(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('السجل'), findsOneWidget);
    expect(find.text('الجمعة، 10 يوليو · 2026'), findsOneWidget);
    final context = tester.element(find.text('السجل'));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(find.textContaining('٢'), findsNothing);
  });
}
