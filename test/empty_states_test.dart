import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

Future<AppState> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
  await state.load();
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('home banner shows when day is empty and opens meal chooser', (
    tester,
  ) async {
    final state = await _pumpApp(tester);

    expect(find.text('Nothing logged today yet'), findsOneWidget);
    await tester.tap(find.text('Log your first meal'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a meal'), findsOneWidget);
    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();
    expect(find.text('Search foods…'), findsOneWidget);

    // Banner disappears once something is logged.
    await tester.pageBack();
    await tester.pumpAndSettle();
    state.addEntry(state.selectedDate, 'kalee_cheese', 1, MealType.snack);
    await tester.pumpAndSettle();
    expect(find.text('Nothing logged today yet'), findsNothing);
  });

  testWidgets('empty search results offer a clear-search action', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Log your first meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Breakfast').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pumpAndSettle();
    expect(find.text('No foods found'), findsOneWidget);
    expect(
      find.text('Try another name, in Arabic or English'),
      findsOneWidget,
    );

    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('No foods found'), findsNothing);
    expect(find.byType(ListTile), findsWidgets); // full list is back
  });

  testWidgets('empty history offers back-to-today which pops', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.text('No logged days yet'), findsOneWidget);
    expect(find.text('Days you log meals will show up here'), findsOneWidget);
    await tester.tap(find.text('Back to today'));
    await tester.pumpAndSettle();
    expect(find.text("Today's calories"), findsOneWidget);
  });

  testWidgets('empty meal detail offers add-a-food into search', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.ensureVisible(find.text('Dinner'));
    await tester.tap(find.text('Dinner'));
    await tester.pumpAndSettle();

    expect(find.text('Add a food'), findsOneWidget);
    await tester.tap(find.text('Add a food'));
    await tester.pumpAndSettle();
    expect(find.text('Search foods…'), findsOneWidget);
  });
}
