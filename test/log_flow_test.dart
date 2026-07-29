import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // Record haptic calls (issue #10): log and delete must each vibrate.
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );

    // Open search for Snack via its + button (4th/last meal row; index 3 —
    // the very last Icons.add belongs to the "Add meal" button). The row sits
    // below the fold, so scroll it into view first.
    await tester.ensureVisible(find.byIcon(Icons.add).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).at(3));
    await tester.pumpAndSettle();

    // Search for the sample snacks.
    await tester.enterText(find.byType(TextField), 'sample snack');
    await tester.pumpAndSettle();
    expect(find.textContaining('Sample Snack'), findsNWidgets(4));

    // Pick the first one: opens the food detail page (the popup sheet
    // this used to open was replaced by a full page). Bump quantity to
    // 1.5 via the decimal stepper, then confirm.
    await tester.tap(find.text('Sample Snack A'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add)); // decimal stepper +0.5
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Add · 195 kcal'));
    await tester.pumpAndSettle();

    // Back on home: snack row shows 195 kcal (1.5 × 130).
    expect(find.text('195 kcal'), findsOneWidget);
    expect(find.text('1,805 kcal left today'), findsOneWidget);
    expect(find.text('Sample Snack A'), findsOneWidget); // row subtitle

    expect(haptics, ['HapticFeedbackType.lightImpact']); // logged → one tap

    // Entry persisted to storage.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('logs_v1'), contains('sample_snack_1'));

    // Let the confirmation snackbar dismiss so it doesn't cover the card.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Open meal detail and delete the entry.
    await tester.ensureVisible(find.text('Snack'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snack'));
    await tester.pumpAndSettle();
    expect(find.text('Sample Snack A'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Not logged yet'), findsOneWidget);

    expect(state.totalsFor(state.selectedDate).kcal, 0);
    expect(haptics.length, 2); // delete fired the second haptic
  });

  test('logs reload from storage across app restarts', () async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    state.addEntry(state.selectedDate, 'sample_main_1', 1, MealType.lunch);
    // _save is fire-and-forget; give it a beat.
    await Future<void>.delayed(Duration.zero);

    final reloaded = AppState();
    await reloaded.load();
    expect(reloaded.totalsFor(state.selectedDate).kcal, 540);
  });

  test('corrupted storage falls back to defaults instead of crashing', () async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'goals': '{definitely not json',
      'logs_v1': '###garbage###',
    });
    final state = AppState();
    await state.load(); // must not throw
    expect(state.goals.kcal, Goals.defaults.kcal);
    expect(state.loggedDates(), isEmpty);
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
