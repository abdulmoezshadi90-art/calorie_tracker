import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/food_db.dart';
import 'package:calorie_tracker/main.dart';

Future<AppState> _pumpApp(WidgetTester tester, {String locale = 'en'}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
  await state.load();
  state.localeCode = locale;
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

Future<void> _openFoodDetail(WidgetTester tester, String query, String name) async {
  await tester.tap(find.text('Log your first meal'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lunch').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name)); // opens the food detail page
  await tester.pumpAndSettle();
}

void main() {
  test('servingsFor converts preset grams to tidy serving counts', () {
    final bazin = foodById['bazin']!;
    expect(bazin.servingGrams, 350);
    expect(bazin.servingsFor(bazin.presets[0]), 0.71); // 250g modest share
    expect(bazin.servingsFor(bazin.presets[1]), 1.0); // 350g = base serving
    expect(bazin.servingsFor(bazin.presets[2]), 1.43); // 500g generous
  });

  test('every preset food has servingGrams and 2+ presets', () {
    final withPresets = foodDatabase.where((f) => f.presets.isNotEmpty);
    expect(withPresets.length, greaterThanOrEqualTo(10));
    for (final f in withPresets) {
      expect(f.servingGrams, isNotNull, reason: f.id);
      expect(f.presets.length, greaterThanOrEqualTo(2), reason: f.id);
      for (final p in f.presets) {
        expect(p.nameAr, isNotEmpty, reason: f.id);
        expect(p.grams, greaterThan(0), reason: f.id);
      }
    }
  });

  testWidgets('tapping a unit chip switches kcal and serving math', (
    tester,
  ) async {
    final state = await _pumpApp(tester);
    await _openFoodDetail(tester, 'bazin', 'Bazin with Sauce');

    // Base serving unit is selected by default.
    expect(find.text('1 serving (350 g)'), findsOneWidget);
    expect(find.textContaining('Add · 540 kcal'), findsOneWidget);

    // Switch to the "Modest share" preset (250 g): 540 × 250/350 ≈ 386 kcal.
    await tester.tap(find.text('Modest share'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Add · 386 kcal'), findsOneWidget);

    // Decimal stepper still fine-adjusts from the new unit: +0.5 → 1.5.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('1.5'), findsOneWidget);
    // 1.5 × 250/350 × 540 ≈ 579 kcal.
    expect(find.textContaining('Add · 579 kcal'), findsOneWidget);

    // Log it and confirm the unit-scaled entry persists across reload.
    await tester.tap(find.textContaining('Add · 579 kcal'));
    await tester.pumpAndSettle();
    await tester.pump();
    final reloaded = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
    await reloaded.load();
    final entry = reloaded.entriesFor(state.selectedDate).single;
    expect(entry.unitId, 'Modest share');
    expect(entry.quantity, 1.5);
    expect(entry.servings, closeTo(1.0714285714285714, 1e-9));
  });

  testWidgets('unit chips render RTL without overflow', (tester) async {
    await _pumpApp(tester, locale: 'ar');
    await tester.tap(find.text('سجّل أول وجبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الغداء').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'بازين');
    await tester.pumpAndSettle();
    await tester.tap(find.text('بازين').last); // the tile, not the field text
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('حصة صغيرة'), findsOneWidget); // preset unit chip
    final context = tester.element(find.text('حصة صغيرة'));
    expect(Directionality.of(context), TextDirection.rtl);
    // Digits anywhere on the page stay Western.
    expect(find.textContaining('٥'), findsNothing);
  });
}
