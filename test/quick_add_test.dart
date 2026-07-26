import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

Future<AppState> _openSearchForLunch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
  await state.load();
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('nav-add')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lunch').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'bazin');
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets(
    'quick add logs exactly one entry with default unit and correct meal',
    (tester) async {
      final state = await _openSearchForLunch(tester);

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

      // Tap the row's own + button — logs without leaving the list.
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // Still on the search screen: no navigation happened.
      expect(find.textContaining('Add · Lunch'), findsOneWidget);

      final date = state.selectedDate;
      final entries = state.entriesFor(date, meal: MealType.lunch);
      expect(entries.length, 1);
      expect(entries.single.foodId, 'bazin');
      expect(entries.single.unitId, 'serving');
      expect(entries.single.quantity, 1.0);
      expect(entries.single.servings, 1.0);
      expect(haptics, ['HapticFeedbackType.lightImpact']);

      expect(find.textContaining('Bazin with Sauce'), findsWidgets);
      expect(find.textContaining('540'), findsWidgets);
      expect(find.text('Undo'), findsOneWidget);
    },
  );

  testWidgets('undo removes the quick-added entry', (tester) async {
    final state = await _openSearchForLunch(tester);
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    final date = state.selectedDate;
    expect(state.entriesFor(date, meal: MealType.lunch).length, 1);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(state.entriesFor(date, meal: MealType.lunch), isEmpty);
  });
}
