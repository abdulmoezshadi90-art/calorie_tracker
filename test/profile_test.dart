import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';
import 'package:calorie_tracker/profile.dart';
import 'package:calorie_tracker/profile_screen.dart';

Profile _profile({
  Sex sex = Sex.male,
  int age = 30,
  double weightKg = 80,
  double heightCm = 180,
  ActivityLevel activity = ActivityLevel.moderate,
  GoalDirection goalDirection = GoalDirection.maintain,
  GoalRate? goalRate,
}) => Profile(
  name: '',
  sex: sex,
  age: age,
  weightKg: weightKg,
  heightCm: heightCm,
  activity: activity,
  goalDirection: goalDirection,
  goalRate: goalRate,
);

Future<AppState> _pumpProfileScreen(
  WidgetTester tester, {
  String locale = 'en',
  Size size = const Size(375, 812),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState();
  await state.load();
  state.localeCode = locale;
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  group('calculateMaintenance', () {
    test('male calculation matches Mifflin St Jeor exactly', () {
      // BMR = 10×80 + 6.25×180 − 5×30 + 5 = 1780; ×1.55 = 2759;
      // lose + normal rate (0.5 kg/wk = −550/day) → 2209 → 2200.
      final r = calculateMaintenance(
        _profile(goalDirection: GoalDirection.lose, goalRate: GoalRate.normal),
      );
      expect(r.goals.kcal, 2200);
      expect(r.maintenanceKcal, 2750); // 2759 → nearest 50
      expect(r.clamped, isFalse);
      expect(r.maintenanceOnly, isFalse);
      // Macros: 25/30/45% at 4/9/4 kcal per gram, whole grams.
      expect(r.goals.protein, (2200 * 0.25 / 4).round());
      expect(r.goals.fat, (2200 * 0.30 / 9).round());
      expect(r.goals.carbs, (2200 * 0.45 / 4).round());
    });

    test('female calculation uses the −161 constant', () {
      // BMR = 10×55 + 6.25×160 − 5×25 − 161 = 1264; ×1.375 = 1738 → 1750.
      final r = calculateMaintenance(
        _profile(
          sex: Sex.female,
          age: 25,
          weightKg: 55,
          heightCm: 160,
          activity: ActivityLevel.light,
        ),
      );
      expect(r.goals.kcal, 1750);
      expect(r.clamped, isFalse);
    });

    test('deficit clamps at the female floor (1200)', () {
      // BMR = 400 + 906.25 − 300 − 161 = 845.25; ×1.2 = 1014.3;
      // normal rate (−550) = 464.3 → 450, below the 1200 floor → clamped.
      final r = calculateMaintenance(
        _profile(
          sex: Sex.female,
          age: 60,
          weightKg: 40,
          heightCm: 145,
          activity: ActivityLevel.sedentary,
          goalDirection: GoalDirection.lose,
          goalRate: GoalRate.normal,
        ),
      );
      expect(r.clamped, isTrue);
      expect(r.goals.kcal, 1200);
      expect(r.goals.protein, greaterThanOrEqualTo(goalFloors.protein));
      expect(r.goals.fat, greaterThanOrEqualTo(goalFloors.fat));
      expect(r.goals.carbs, greaterThanOrEqualTo(goalFloors.carbs));
    });

    test(
      'deficit clamps at the male floor (1500); a normal target is untouched',
      () {
        // BMR = 550 + 1031.25 − 225 + 5 = 1361.25; ×1.2 = 1633.5;
        // extreme rate (−1100) = 533.5 → 550, below the 1500 male floor.
        final small = calculateMaintenance(
          _profile(
            sex: Sex.male,
            age: 45,
            weightKg: 55,
            heightCm: 165,
            activity: ActivityLevel.sedentary,
            goalDirection: GoalDirection.lose,
            goalRate: GoalRate.extreme,
          ),
        );
        expect(small.clamped, isTrue);
        expect(small.goals.kcal, 1500);

        // A comfortably-above-floor male target is untouched.
        final normal = calculateMaintenance(
          _profile(goalDirection: GoalDirection.lose, goalRate: GoalRate.mild),
        );
        expect(normal.clamped, isFalse);
      },
    );

    test('under 18 gets maintenance only, deficit ignored', () {
      final withDeficit = calculateMaintenance(
        _profile(
          age: 16,
          goalDirection: GoalDirection.lose,
          goalRate: GoalRate.normal,
        ),
      );
      final maintain = calculateMaintenance(
        _profile(age: 16, goalDirection: GoalDirection.maintain),
      );
      expect(withDeficit.maintenanceOnly, isTrue);
      expect(withDeficit.goals.kcal, maintain.goals.kcal);
    });

    test('profile JSON round trip is null tolerant', () {
      final p = _profile(
        sex: Sex.female,
        goalDirection: GoalDirection.gain,
        goalRate: GoalRate.mild,
      );
      final back = Profile.fromJson(p.toJson());
      expect(back.sex, Sex.female);
      expect(back.goalDirection, GoalDirection.gain);
      expect(back.goalRate, GoalRate.mild);
      // Malformed input falls back instead of throwing.
      final fallback = Profile.fromJson({'sex': 'bogus', 'age': 'x'});
      expect(fallback.sex, Sex.male);
      expect(fallback.age, 30);
      expect(fallback.goalDirection, GoalDirection.maintain);
    });

    test('legacy single-field "goal" JSON still decodes', () {
      Map<String, dynamic> legacy(String goal) => {
        'name': '',
        'sex': 'female',
        'age': 40,
        'weightKg': 65,
        'heightCm': 165,
        'activity': 'light',
        'goal': goal,
      };

      final maintain = Profile.fromJson(legacy('maintain'));
      expect(maintain.goalDirection, GoalDirection.maintain);
      expect(maintain.goalRate, isNull);

      final loseGently = Profile.fromJson(legacy('loseGently'));
      expect(loseGently.goalDirection, GoalDirection.lose);
      expect(loseGently.goalRate, GoalRate.mild);

      final lose = Profile.fromJson(legacy('lose'));
      expect(lose.goalDirection, GoalDirection.lose);
      expect(lose.goalRate, GoalRate.normal);

      final gain = Profile.fromJson(legacy('gain'));
      expect(gain.goalDirection, GoalDirection.gain);
      expect(gain.goalRate, GoalRate.mild); // nearest to the old +300
    });
  });

  group('dailyKcalDelta', () {
    test('rates produce the spec deltas per direction', () {
      expect(dailyKcalDelta(GoalDirection.lose, GoalRate.mild), -275);
      expect(dailyKcalDelta(GoalDirection.lose, GoalRate.normal), -550);
      expect(dailyKcalDelta(GoalDirection.lose, GoalRate.extreme), -1100);
      expect(dailyKcalDelta(GoalDirection.gain, GoalRate.mild), 275);
      expect(dailyKcalDelta(GoalDirection.gain, GoalRate.normal), 550);
      expect(dailyKcalDelta(GoalDirection.gain, GoalRate.extreme), 1100);
      expect(dailyKcalDelta(GoalDirection.maintain, null), 0);
    });

    test('gain mirrors loss with the sign flipped', () {
      for (final rate in GoalRate.values) {
        expect(
          dailyKcalDelta(GoalDirection.gain, rate),
          -dailyKcalDelta(GoalDirection.lose, rate),
        );
      }
    });
  });

  group('profile wizard', () {
    /// Walks the wizard through the sex step (EN locale): name skipped via
    /// Continue, then taps the given sex (auto-advances to age).
    Future<void> walkToAge(WidgetTester tester, {String sex = 'Male'}) async {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(sex));
      await tester.pumpAndSettle();
    }

    /// Enters a numeric value on the current step and taps Continue.
    Future<void> enterAndContinue(WidgetTester tester, String value) async {
      await tester.enterText(find.byType(TextField), value);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    /// Walks name → sex → age/weight/height → activity (Moderate), landing
    /// on the direction step. Matches the standard test profile.
    Future<void> walkToDirection(WidgetTester tester) async {
      await walkToAge(tester);
      await enterAndContinue(tester, '30');
      await enterAndContinue(tester, '80');
      await enterAndContinue(tester, '180');
      await tester.tap(find.text('Moderate'));
      await tester.pumpAndSettle();
    }

    testWidgets('wizard end to end produces the same-shape Goals as before', (
      tester,
    ) async {
      final state = await _pumpProfileScreen(tester);

      expect(find.text('Name (optional)'), findsOneWidget);
      expect(find.text('1/7'), findsOneWidget);
      await walkToAge(tester);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('3/7'), findsOneWidget);
      await enterAndContinue(tester, '30');
      await enterAndContinue(tester, '80');
      await enterAndContinue(tester, '180');

      // Activity step: descriptions and the exercise helper line.
      expect(find.text('Training intensity'), findsOneWidget);
      expect(find.text('Exercise 4 to 5 times a week'), findsOneWidget);
      expect(
        find.textContaining('elevated heart rate activity'),
        findsOneWidget,
      );
      await tester.tap(find.text('Moderate'));
      await tester.pumpAndSettle();

      // Direction step: plain labels, no kcal leaked into the options yet.
      expect(find.text('7/7'), findsOneWidget);
      expect(find.text('Lose weight'), findsOneWidget);
      expect(find.text('Maintain weight'), findsOneWidget);
      expect(find.text('Gain weight'), findsOneWidget);
      expect(find.textContaining('kcal'), findsNothing);
      await tester.tap(find.text('Lose weight'));
      await tester.pumpAndSettle();

      // Rate step: mirrored, weekly-rate phrasing, live kcal per card.
      expect(find.text('8/8'), findsOneWidget);
      expect(find.text('0.5 kg per week'), findsOneWidget);
      expect(find.textContaining('kcal'), findsWidgets);
      await tester.tap(find.text('Weight loss'));
      await tester.pumpAndSettle();

      // Result summary (title shows in both the header slot and the card):
      // the math must not have changed shape with the UX rework.
      expect(find.text('Your suggested daily goal'), findsWidgets);
      await tester.tap(find.text('Use this goal'));
      await tester.pumpAndSettle();

      // 2759 maintenance − 550 (normal rate) = 2209 → 2200.
      expect(state.goals.kcal, 2200);
      expect(state.goals.protein, (2200 * 0.25 / 4).round());
      expect(state.profile, isNotNull);
      expect(state.profile!.weightKg, 80);
      expect(state.profile!.goalDirection, GoalDirection.lose);
      expect(state.profile!.goalRate, GoalRate.normal);
    });

    testWidgets('every activity option shows its description, incl. High', (
      tester,
    ) async {
      // Regression guard for a device report of a missing High line — not
      // reproducible in this code (the string exists per decision 8), the
      // report likely came from a pre-wizard build. This pins it forever.
      await _pumpProfileScreen(tester);
      await walkToAge(tester);
      await enterAndContinue(tester, '30');
      await enterAndContinue(tester, '80');
      await enterAndContinue(tester, '180');

      expect(find.text('Desk life, little or no exercise'), findsOneWidget);
      expect(find.text('Exercise 1 to 3 times a week'), findsOneWidget);
      expect(find.text('Exercise 4 to 5 times a week'), findsOneWidget);
      expect(
        find.text('Daily exercise, or intense exercise 3 to 6 times a week'),
        findsOneWidget,
      );
      expect(
        find.text('Very intense daily training or a physical job'),
        findsOneWidget,
      );
    });

    testWidgets('weight and height accept one decimal point', (tester) async {
      final state = await _pumpProfileScreen(tester);
      await walkToAge(tester);
      await enterAndContinue(tester, '30');

      // Second '.' and other separators are normalized/stripped.
      await tester.enterText(find.byType(TextField), '8١٫5'); // mixed input
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '81.5',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await enterAndContinue(tester, '175.5');

      await tester.tap(find.text('Moderate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maintain weight'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use this goal'));
      await tester.pumpAndSettle();

      expect(state.profile!.weightKg, 81.5);
      expect(state.profile!.heightCm, 175.5);
      // Mifflin with decimals: 10×81.5 + 6.25×175.5 − 150 + 5 = 1766.875;
      // ×1.55 = 2738.66 → 2750 to the nearest 50 (maintain, no adjustment).
      expect(state.goals.kcal, 2750);
    });

    testWidgets('choosing maintain skips the rate step entirely', (
      tester,
    ) async {
      final state = await _pumpProfileScreen(tester);
      await walkToDirection(tester);

      expect(find.text('7/7'), findsOneWidget);
      await tester.tap(find.text('Maintain weight'));
      await tester.pumpAndSettle();

      // Lands directly on the result step — no rate cards, no "8/8".
      expect(find.text('8/8'), findsNothing);
      expect(find.textContaining('kg per week'), findsNothing);
      expect(find.text('Your suggested daily goal'), findsWidgets);
      await tester.tap(find.text('Use this goal'));
      await tester.pumpAndSettle();

      expect(state.goals.kcal, 2750); // maintenance only, no adjustment
      expect(state.profile!.goalDirection, GoalDirection.maintain);
      expect(state.profile!.goalRate, isNull);
    });

    testWidgets('gain mirrors loss with the sign flipped, in the wizard UI', (
      tester,
    ) async {
      final state = await _pumpProfileScreen(tester);
      await walkToDirection(tester);
      await tester.tap(find.text('Gain weight'));
      await tester.pumpAndSettle();

      expect(find.text('Mild weight gain'), findsOneWidget);
      expect(find.text('Weight gain'), findsOneWidget);
      expect(find.text('Fast weight gain'), findsOneWidget);
      await tester.tap(find.text('Weight gain'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use this goal'));
      await tester.pumpAndSettle();

      // 2759 + 550 (normal rate) = 3309 → 3300.
      expect(state.goals.kcal, 3300);
    });

    testWidgets(
      'back from the rate step preserves direction; switching clears the rate',
      (tester) async {
        await _pumpProfileScreen(tester);
        await walkToDirection(tester);
        await tester.tap(find.text('Lose weight'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Mild weight loss'));
        await tester.pumpAndSettle();
        expect(find.text('Your suggested daily goal'), findsWidgets);

        // Back to the rate step, back again to direction: still "Lose".
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.text('Mild weight loss'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.text('Lose weight'), findsOneWidget);

        // Switch to Gain: the stale "lose" rate must not carry over — the
        // gain cards start with nothing selected (no accent border check
        // available via text finders, so assert the mirrored labels show
        // instead of the old lose ones).
        await tester.tap(find.text('Gain weight'));
        await tester.pumpAndSettle();
        expect(find.text('Mild weight gain'), findsOneWidget);
        expect(find.text('Mild weight loss'), findsNothing);
      },
    );

    testWidgets('age field still rejects a decimal point', (tester) async {
      await _pumpProfileScreen(tester);
      await walkToAge(tester);

      await tester.enterText(find.byType(TextField), '2.5');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '25',
      );
    });

    testWidgets('activity step renders RTL at 375x812 without overflow', (
      tester,
    ) async {
      await _pumpProfileScreen(tester, locale: 'ar');

      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ذكر'));
      await tester.pumpAndSettle();
      for (final v in ['30', '80', '180']) {
        await tester.enterText(find.byType(TextField), v);
        await tester.tap(find.text('متابعة'));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
      expect(find.text('مستوى النشاط'), findsOneWidget);
      // All five cards with descriptions plus the helper line.
      expect(find.text('خامل'), findsOneWidget);
      expect(find.text('تمرين 4 إلى 5 مرات في الأسبوع'), findsOneWidget);
      expect(find.textContaining('يرفع نبض القلب'), findsOneWidget);
      expect(find.text('6/7'), findsOneWidget);
      final context = tester.element(find.text('مستوى النشاط'));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Eastern Arabic input ٢٥ stores 25 on the age step', (
      tester,
    ) async {
      await _pumpProfileScreen(tester);
      await walkToAge(tester);

      await tester.enterText(find.byType(TextField), '٢٥');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '25',
      );
    });

    testWidgets('out of range age shows error and does not advance', (
      tester,
    ) async {
      final state = await _pumpProfileScreen(tester);
      await walkToAge(tester);

      await tester.enterText(find.byType(TextField), '9');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid number'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget); // still here
      expect(state.goals.kcal, 2000); // unchanged
    });

    testWidgets('age, weight and height steps show no visible range hint', (
      tester,
    ) async {
      await _pumpProfileScreen(tester);
      expect(find.textContaining('–'), findsNothing);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      for (final value in ['30', '80', '180']) {
        expect(find.textContaining('–'), findsNothing);
        await tester.enterText(find.byType(TextField), value);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('back arrow steps backward, first step pops the screen', (
      tester,
    ) async {
      await _pumpProfileScreen(tester);
      await walkToAge(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Sex'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsNothing); // popped to settings
    });

    testWidgets('rate step and maintain result use only Western digits', (
      tester,
    ) async {
      await _pumpProfileScreen(tester, locale: 'ar');
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ذكر'));
      await tester.pumpAndSettle();
      for (final v in ['30', '80', '180']) {
        await tester.enterText(find.byType(TextField), v);
        await tester.tap(find.text('متابعة'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('متوسط')); // Moderate
      await tester.pumpAndSettle();
      await tester.tap(find.text('إنقاص الوزن')); // Lose weight
      await tester.pumpAndSettle();

      for (final digit in '٠١٢٣٤٥٦٧٨٩'.split('')) {
        expect(find.textContaining(digit), findsNothing, reason: digit);
      }
      expect(find.textContaining('0.5'), findsOneWidget);
      expect(find.textContaining('2,200'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تثبيت الوزن')); // Maintain weight
      await tester.pumpAndSettle();

      for (final digit in '٠١٢٣٤٥٦٧٨٩'.split('')) {
        expect(find.textContaining(digit), findsNothing, reason: digit);
      }
      // Headline number only — the maintenance line below it also
      // contains "2,750" (maintain has zero adjustment, so they match).
      expect(find.text('2,750 سعرة'), findsOneWidget);
    });

    for (final size in [const Size(375, 812), const Size(320, 640)]) {
      for (final locale in ['en', 'ar']) {
        testWidgets('no overflow across every step at '
            '${size.width.toInt()}x${size.height.toInt()} ($locale)', (
          tester,
        ) async {
          await _pumpProfileScreen(tester, locale: locale, size: size);
          expect(tester.takeException(), isNull);

          final continueLabel = locale == 'ar' ? 'متابعة' : 'Continue';
          final maleLabel = locale == 'ar' ? 'ذكر' : 'Male';
          final moderateLabel = locale == 'ar' ? 'متوسط' : 'Moderate';
          final loseLabel = locale == 'ar' ? 'إنقاص الوزن' : 'Lose weight';
          final gainLabel = locale == 'ar' ? 'زيادة الوزن' : 'Gain weight';
          final maintainLabel = locale == 'ar'
              ? 'تثبيت الوزن'
              : 'Maintain weight';
          final mildLoss = locale == 'ar' ? 'إنقاص خفيف' : 'Mild weight loss';

          await tester.tap(find.text(continueLabel)); // name
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(maleLabel));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final v in ['30', '80', '180']) {
            await tester.enterText(find.byType(TextField), v);
            await tester.tap(find.text(continueLabel));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.tap(find.text(moderateLabel));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Lose path: direction + rate step.
          await tester.tap(find.text(loseLabel));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(mildLoss));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Back to direction (result → rate → direction), try Gain,
          // then Maintain (shortest path).
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
          expect(find.text(gainLabel), findsOneWidget); // back on direction
          await tester.tap(find.text(gainLabel));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
          await tester.tap(find.text(maintainLabel));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
