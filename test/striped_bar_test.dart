import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';
import 'package:calorie_tracker/striped_bar.dart';

void main() {
  testWidgets('over-goal shows striped bars and plain overage numbers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    state.setGoals(
      const Goals(kcal: 500, carbs: 50, fat: 20, protein: 30),
    );
    // sample_main_1: 540 kcal, 75c/15fat/25p per serving — over kcal, carbs.
    state.addEntry(state.selectedDate, 'sample_main_1', 1, MealType.lunch);
    await tester.pumpWidget(CalorieApp(state: state));
    await tester.pumpAndSettle();

    // Calorie + 3 macro bars all use the striped widget.
    expect(find.byType(StripedBar), findsNWidgets(4));
    // Carbs 75/50 → plain "+25" marker, no alarm wording.
    expect(find.textContaining('+25'), findsOneWidget);
    // Over-goal pill wording is the existing neutral string.
    expect(find.textContaining('40'), findsWidgets); // 540-500 over
  });

  testWidgets('within goal there are no overage markers', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(CalorieApp(state: state));
    await tester.pumpAndSettle();

    expect(find.byType(StripedBar), findsNWidgets(4));
    expect(find.textContaining('· +'), findsNothing);
  });
}
