import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

void main() {
  testWidgets('search, log and delete a food via the UI', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(CalorieApp(state: state));
    await tester.pumpAndSettle();

    // Open search for Snack via its + button (4th/last meal row; index 3 —
    // the very last Icons.add belongs to the "Add meal" button). The row sits
    // below the fold, so scroll it into view first.
    await tester.ensureVisible(find.byIcon(Icons.add).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).at(3));
    await tester.pumpAndSettle();

    // Search for Kalee.
    await tester.enterText(find.byType(TextField), 'kalee');
    await tester.pumpAndSettle();
    expect(find.textContaining('Kalee'), findsNWidgets(4));

    // Pick the cheese chips, bump to 1.5 servings, add.
    await tester.tap(find.text('Kalee Chips — Cheese'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).last); // stepper +
    await tester.pumpAndSettle();
    expect(find.text('1.5'), findsOneWidget);
    await tester.tap(find.textContaining('Add · 195 kcal'));
    await tester.pumpAndSettle();

    // Back on home: snack row shows 195 kcal (1.5 × 130).
    expect(find.text('195 kcal'), findsOneWidget);
    expect(find.text('1,805 kcal left today'), findsOneWidget);
    expect(find.text('Kalee Chips — Cheese'), findsOneWidget); // row subtitle

    // Entry persisted to storage.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('logs_v1'), contains('kalee_cheese'));

    // Let the confirmation snackbar dismiss so it doesn't cover the card.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Open meal detail and delete the entry.
    await tester.ensureVisible(find.text('Snack'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snack'));
    await tester.pumpAndSettle();
    expect(find.text('Kalee Chips — Cheese'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Not logged yet'), findsOneWidget);

    expect(state.totalsFor(state.selectedDate).kcal, 0);
  });

  test('logs reload from storage across app restarts', () async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    state.addEntry(state.selectedDate, 'bazin', 1, MealType.lunch);
    // _save is fire-and-forget; give it a beat.
    await Future<void>.delayed(Duration.zero);

    final reloaded = AppState();
    await reloaded.load();
    expect(reloaded.totalsFor(state.selectedDate).kcal, 540);
  });

  test('goals reload from storage across app restarts', () async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    expect(state.goals.kcal, Goals.defaults.kcal);

    state.setGoals(const Goals(kcal: 1800, carbs: 200, fat: 60, protein: 120));
    // _save is fire-and-forget; give it a beat.
    await Future<void>.delayed(Duration.zero);

    final reloaded = AppState();
    await reloaded.load();
    expect(reloaded.goals.kcal, 1800);
    expect(reloaded.goals.carbs, 200);
    expect(reloaded.goals.fat, 60);
    expect(reloaded.goals.protein, 120);
  });
}
