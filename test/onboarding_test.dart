import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';

Future<AppState> _pumpFirstLaunch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final state = AppState();
  await state.load();
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('first launch shows onboarding, language page first', (
    tester,
  ) async {
    await _pumpFirstLaunch(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    // Home is not shown yet.
    expect(find.text("Today's calories"), findsNothing);
  });

  testWidgets('skip completes onboarding with defaults and persists', (
    tester,
  ) async {
    final state = await _pumpFirstLaunch(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text("Today's calories"), findsOneWidget);
    expect(state.onboardingDone, isTrue);
    expect(state.goals.kcal, 2000); // defaults carry a skipped onboarding

    // Persisted: a fresh AppState skips straight to home. (pump flushes the
    // fire-and-forget _save; Future.delayed would hang under fake async.)
    await tester.pump();
    final reloaded = AppState();
    await reloaded.load();
    expect(reloaded.onboardingDone, isTrue);
  });

  testWidgets('choosing Arabic flips the app to RTL immediately', (
    tester,
  ) async {
    final state = await _pumpFirstLaunch(tester);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(state.localeCode, 'ar');
    expect(find.text('اختر اللغة'), findsOneWidget);
    final context = tester.element(find.text('اختر اللغة'));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('full flow: language, intro with disclaimer, goals, done', (
    tester,
  ) async {
    final state = await _pumpFirstLaunch(tester);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Intro page carries the disclaimer.
    expect(find.text('Log what you eat'), findsOneWidget);
    expect(
      find.textContaining('does not provide medical advice'),
      findsOneWidget,
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Profile step (decision 8): local profile pitch, skippable via Next.
    expect(find.text('Your profile'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Goals page reuses the goals editor sheet.
    expect(find.text('Set your daily goals'), findsOneWidget);
    await tester.tap(find.textContaining('Daily goals'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '1900');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(state.goals.kcal, 1900);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.textContaining('of 1,900 kcal'), findsOneWidget);
    expect(state.onboardingDone, isTrue);
  });

  testWidgets('onboarding can be replayed from settings', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(CalorieApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replay intro'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);

    // Skip pops back to where the user was (settings tab; the nav label
    // and the app bar title both read Settings).
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNWidgets(2));
  });
}
