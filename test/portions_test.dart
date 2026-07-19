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

Future<void> _openFoodSheet(WidgetTester tester, String query, String name) async {
  await tester.tap(find.text('Log your first meal'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lunch').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
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

  testWidgets('tapping a preset chip sets servings and kcal math', (
    tester,
  ) async {
    final state = await _pumpApp(tester);
    await _openFoodSheet(tester, 'bazin', 'Bazin with Sauce');

    // Chips are visible with gram labels.
    expect(find.textContaining('Modest share · 250 g'), findsOneWidget);

    await tester.tap(find.textContaining('Modest share'));
    await tester.pumpAndSettle();
    // 0.71 servings × 540 kcal = 383.4 → 383.
    expect(find.text('0.71'), findsOneWidget);
    expect(find.textContaining('Add · 383 kcal'), findsOneWidget);

    // Stepper still fine-adjusts from the preset value.
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    expect(find.text('1.21'), findsOneWidget);

    // Log it and confirm the preset-based entry persists across reload.
    await tester.tap(find.textContaining('Add · 653 kcal'));
    await tester.pumpAndSettle();
    await tester.pump();
    final reloaded = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
    await reloaded.load();
    expect(
      reloaded.entriesFor(state.selectedDate).single.servings,
      1.21,
    );
  });

  testWidgets('preset chips render RTL without overflow', (tester) async {
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
    expect(find.textContaining('حصة صغيرة · 250 جم'), findsOneWidget);
    final context = tester.element(find.textContaining('حصة صغيرة'));
    expect(Directionality.of(context), TextDirection.rtl);
    // Digits in chip labels stay Western.
    expect(find.textContaining('٢'), findsNothing);
  });
}
