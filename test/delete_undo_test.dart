import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

Future<AppState> _pumpWithLunch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState();
  await state.load();
  await state.addEntry(state.selectedDate, 'bazin', 1, MealType.lunch);
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('delete shows Removed/Undo and undo restores the entry', (
    tester,
  ) async {
    final state = await _pumpWithLunch(tester);
    final date = state.selectedDate;
    expect(state.entriesFor(date, meal: MealType.lunch).length, 1);

    // Open the Lunch meal detail from the home meal row.
    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();

    // Delete the entry.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Undo snackbar shows; entry is gone from state meanwhile.
    expect(find.text('Removed'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(state.entriesFor(date, meal: MealType.lunch), isEmpty);

    // Tap Undo → entry restored.
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(state.entriesFor(date, meal: MealType.lunch).length, 1);
    expect(
      state.entriesFor(date, meal: MealType.lunch).first.foodId,
      'bazin',
    );
  });

  test('restoreEntry puts the entry back at its original index', () async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    final day = DateTime(2026, 7, 15);
    await state.addEntry(day, 'bazin', 1, MealType.lunch);
    await state.addEntry(day, 'kalee_cheese', 1, MealType.lunch);
    await state.addEntry(day, 'ful', 1, MealType.lunch);

    // Remove the middle one, then restore it.
    final middle = state.entriesFor(day, meal: MealType.lunch)[1];
    final removed = await state.removeEntry(day, middle.id);
    expect(removed!.index, 1);
    await state.restoreEntry(day, removed.entry, removed.index);

    final foods = state
        .entriesFor(day, meal: MealType.lunch)
        .map((e) => e.foodId)
        .toList();
    expect(foods, ['bazin', 'kalee_cheese', 'ful']); // order preserved
  });
}
