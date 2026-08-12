import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

/// Phase 7 overflow audit: the two device sizes and the text-scale factor
/// named in the brief, each in both languages, against every bottom-nav
/// screen. Individual screens already carry their own narrower overflow
/// tests (search_screen_test.dart, profile_test.dart, etc.) — this file's
/// job is the specific 320x568 / 1.3x-scale combinations those don't cover.
Future<AppState> _pumpAt(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  String locale = 'en',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
  await state.load();
  state.localeCode = locale;
  // A couple of logged entries so the meal rows, calorie card and macro
  // bars all render real (non-empty) content, not just empty states.
  await state.addEntry(state.selectedDate, 'sample_main_1', 1, MealType.lunch);
  await state.addEntry(state.selectedDate, 'sample_snack_1', 2, MealType.snack);
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

const _smallPhone = Size(320, 568);
const _basePhone = Size(375, 812);

void main() {
  for (final locale in ['en', 'ar']) {
    group('locale=$locale', () {
      testWidgets('home at 320x568', (tester) async {
        await _pumpAt(
          tester,
          size: _smallPhone,
          textScale: 1.0,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('home at 375x812, 1.3x text scale', (tester) async {
        await _pumpAt(tester, size: _basePhone, textScale: 1.3, locale: locale);
        expect(tester.takeException(), isNull);
      });

      testWidgets('progress tab at 320x568', (tester) async {
        await _pumpAt(
          tester,
          size: _smallPhone,
          textScale: 1.0,
          locale: locale,
        );
        await tester.tap(find.byIcon(Icons.insights_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('progress tab at 375x812, 1.3x text scale', (tester) async {
        await _pumpAt(tester, size: _basePhone, textScale: 1.3, locale: locale);
        await tester.tap(find.byIcon(Icons.insights_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('foods (search) tab at 320x568', (tester) async {
        await _pumpAt(
          tester,
          size: _smallPhone,
          textScale: 1.0,
          locale: locale,
        );
        await tester.tap(find.byIcon(Icons.restaurant_menu_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('foods (search) tab at 375x812, 1.3x text scale', (
        tester,
      ) async {
        await _pumpAt(tester, size: _basePhone, textScale: 1.3, locale: locale);
        await tester.tap(find.byIcon(Icons.restaurant_menu_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('settings tab at 320x568', (tester) async {
        await _pumpAt(
          tester,
          size: _smallPhone,
          textScale: 1.0,
          locale: locale,
        );
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('settings tab at 375x812, 1.3x text scale', (tester) async {
        await _pumpAt(tester, size: _basePhone, textScale: 1.3, locale: locale);
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('meal detail at 320x568', (tester) async {
        await _pumpAt(
          tester,
          size: _smallPhone,
          textScale: 1.0,
          locale: locale,
        );
        final mealRow = find.text(locale == 'ar' ? 'الغداء' : 'Lunch');
        await tester.ensureVisible(mealRow);
        await tester.tap(mealRow);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('meal detail at 375x812, 1.3x text scale', (tester) async {
        await _pumpAt(tester, size: _basePhone, textScale: 1.3, locale: locale);
        final mealRow = find.text(locale == 'ar' ? 'الغداء' : 'Lunch');
        await tester.ensureVisible(mealRow);
        await tester.tap(mealRow);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });
  }
}
