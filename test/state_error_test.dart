import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

void main() {
  group('corrupted local data on launch', () {
    test('malformed goals/profile/logs all fall back, app does not crash',
        () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_done': true,
        'goals': 'not json at all {{{',
        'profile': '["wrong", "shape"]',
        'logs_v1': '{ this is broken',
      });
      final state = AppState();
      await state.load(); // must not throw

      expect(state.goals, Goals.defaults);
      expect(state.profile, isNull);
      expect(state.loggedDates(), isEmpty);
    });

    test('one bad entry is dropped, the rest of the diary survives', () async {
      // Valid day with one good + one malformed entry, plus a day whose
      // key is not a date at all.
      final logs = {
        '2026-07-15': [
          {'id': 'a', 'foodId': 'bazin', 'servings': 1, 'meal': 'lunch'},
          {'id': 'b', 'bogus': true}, // malformed → skipped
        ],
        'not-a-date': [
          {'id': 'c', 'foodId': 'bazin', 'servings': 1, 'meal': 'lunch'},
        ],
      };
      SharedPreferences.setMockInitialValues({
        'onboarding_done': true,
        'logs_v1': jsonEncode(logs),
      });
      final state = AppState();
      await state.load();

      final day = DateTime(2026, 7, 15);
      expect(state.entriesFor(day).length, 1); // good entry kept
      expect(state.loggedDates().length, 1); // bad-key day dropped
    });
  });

  testWidgets('write failure shows inline error and does not log the entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    state.debugFailWrites = true; // simulate disk full / permission error
    await tester.pumpWidget(CalorieApp(state: state));
    await tester.pumpAndSettle();

    // Open Add → search bazin → tap it → confirm.
    await tester.tap(find.byKey(const Key('nav-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Breakfast').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bazin');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bazin with Sauce'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Add · 540'));
    await tester.pumpAndSettle();

    // Inline "couldn't save" error, sheet still open, nothing logged.
    expect(find.text("Couldn't save — try again"), findsOneWidget);
    expect(state.entriesFor(state.selectedDate), isEmpty);
    expect(state.totalsFor(state.selectedDate).kcal, 0);
  });

  test('a failed write rolls the in-memory model back', () async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    state.debugFailWrites = true;

    final added = await state.addEntry(
      state.selectedDate,
      'bazin',
      1,
      MealType.lunch,
    );
    expect(added, isFalse);
    expect(state.entriesFor(state.selectedDate), isEmpty);

    final saved = await state.setGoals(
      const Goals(kcal: 1800, carbs: 200, fat: 60, protein: 100),
    );
    expect(saved, isFalse);
    expect(state.goals, Goals.defaults); // rolled back
  });
}
