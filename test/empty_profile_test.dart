import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/profile.dart';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('unset profile shows a setup prompt, not a bare recalculate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(CalorieApp(state: state));
    await tester.pumpAndSettle();
    await _openSettings(tester);

    expect(find.text('Set up your profile'), findsOneWidget);
    expect(find.text('for a personalized daily goal'), findsOneWidget);
    expect(find.text('Recalculate my goal'), findsNothing);
  });

  testWidgets('a set profile shows the recalculate wording', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    await state.setProfile(
      const Profile(
        name: '',
        sex: Sex.male,
        age: 30,
        weightKg: 80,
        heightCm: 180,
        activity: ActivityLevel.moderate,
        goalDirection: GoalDirection.maintain,
      ),
    );
    await tester.pumpWidget(CalorieApp(state: state));
    await tester.pumpAndSettle();
    await _openSettings(tester);

    expect(find.text('Recalculate my goal'), findsOneWidget);
    expect(find.text('Set up your profile'), findsNothing);
  });
}
