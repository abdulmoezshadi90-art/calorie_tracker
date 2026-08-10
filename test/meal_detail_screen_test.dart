import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/meal_detail_screen.dart';
import 'package:calorie_tracker/models.dart';

Future<AppState> _pumpMealDetail(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
  await state.load();
  await tester.pumpWidget(
    MaterialApp(
      home: AppScope(
        state: state,
        child: const MealDetailScreen(meal: MealType.lunch),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('shows the logged time when an entry has one', (tester) async {
    final state = await _pumpMealDetail(tester);
    await state.addEntry(
      state.selectedDate,
      'sample_main_1',
      1,
      MealType.lunch,
      loggedAt: DateTime(2026, 7, 15, 9, 30),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 × 1 serving (350 g) · 09:30'), findsOneWidget);
  });

  testWidgets('shows no time for an entry logged before this field existed', (
    tester,
  ) async {
    final state = await _pumpMealDetail(tester);
    await state.addEntry(
      state.selectedDate,
      'sample_main_1',
      1,
      MealType.lunch,
    );
    await tester.pumpAndSettle();

    expect(find.text('1 × 1 serving (350 g)'), findsOneWidget);
  });
}
