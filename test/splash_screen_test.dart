import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_shell.dart';
import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/onboarding_screen.dart';
import 'package:calorie_tracker/splash_screen.dart';

Future<AppState> _pump(
  WidgetTester tester, {
  bool onboardingDone = false,
  String locale = 'en',
}) async {
  SharedPreferences.setMockInitialValues({
    if (onboardingDone) 'onboarding_done': true,
  });
  final state = AppState(clock: () => DateTime(2026, 7, 20, 9, 30));
  await state.load();
  state.localeCode = locale;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      builder: (context, child) =>
          AppScope(state: state, child: child ?? const SizedBox.shrink()),
      home: const AppStartup(),
    ),
  );
  return state;
}

void main() {
  // flutter_test_config.dart zeroes AppStartup.splashDuration for the whole
  // suite so tests elsewhere stay fast. These tests exist specifically to
  // observe the splash before it hands off, so they need it to actually
  // hold for a moment, restored after each test so the override doesn't
  // leak into unrelated tests run in the same process.
  setUp(() => AppStartup.splashDuration = const Duration(milliseconds: 200));
  tearDown(() => AppStartup.splashDuration = Duration.zero);

  testWidgets('shows the logo, app name, and loading dots on launch', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    // Fixed bilingual wordmark, shown together regardless of locale — not
    // "Zibda" in English mode and "زبدة" in Arabic mode separately.
    expect(find.text('Zibda · زبدة'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Drains the pending splashDuration timer — the test framework treats
    // a still-pending Timer at teardown as a failure, even when (as here)
    // the assertions above only cared about the state before it fires.
    await tester.pumpAndSettle();
  });

  testWidgets(
    'renders without error in Arabic, wordmark stays bilingual there too',
    (tester) async {
      await _pump(tester, locale: 'ar');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Zibda · زبدة'), findsOneWidget);

      // Fixed English-left/Arabic-right lockup — without forcing LTR
      // here, Arabic mode's RTL paragraph direction flips the bidi
      // algorithm's visual order (Zibda ends up on the right instead).
      final wordmark = tester.widget<Text>(find.text('Zibda · زبدة'));
      final directionality = tester.widget<Directionality>(
        find.ancestor(
          of: find.byWidget(wordmark),
          matching: find.byType(Directionality),
        ).first,
      );
      expect(directionality.textDirection, TextDirection.ltr);

      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'transitions to onboarding after the splash duration when onboarding is not done',
    (tester) async {
      await _pump(tester, onboardingDone: false);
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );

  testWidgets(
    'transitions to the app shell after the splash duration when onboarding is done',
    (tester) async {
      await _pump(tester, onboardingDone: true);
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
    },
  );

  testWidgets(
    'the logo stays pinned to true screen center throughout the entrance, '
    'not shifted up to make room for the not-yet-visible name and dots',
    (tester) async {
      await _pump(tester);
      await tester.pump();

      final screenCenter = tester.view.physicalSize /
          tester.view.devicePixelRatio /
          2;
      final expectedCenter = Offset(screenCenter.width, screenCenter.height);

      // Sample across the entrance: right at frame 0 (logo alone, before
      // the name/dots would have reserved any space under the old
      // group-centered Column layout), then again once everything has
      // faded in and settled. Same center both times is the actual bug
      // fix — it used to be ~50px too high at frame 0 specifically.
      expect(tester.getRect(find.byType(Image)).center, expectedCenter);

      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getRect(find.byType(Image)).center, expectedCenter);

      await tester.pumpAndSettle();
    },
  );

  testWidgets('no overflow at a short screen size', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester);
    await tester.pump();

    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
  });
}
