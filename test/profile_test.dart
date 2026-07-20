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
  WeightGoal goal = WeightGoal.maintain,
}) => Profile(
  name: '',
  sex: sex,
  age: age,
  weightKg: weightKg,
  heightCm: heightCm,
  activity: activity,
  goal: goal,
);

Future<AppState> _pumpProfileScreen(
  WidgetTester tester, {
  String locale = 'en',
}) async {
  tester.view.physicalSize = const Size(375, 812);
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
  await tester.tap(find.byIcon(Icons.calculate_outlined));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  group('calculateMaintenance', () {
    test('male calculation matches Mifflin St Jeor exactly', () {
      // BMR = 10×80 + 6.25×180 − 5×30 + 5 = 1780; ×1.55 = 2759;
      // −500 (lose) = 2259 → 2250 to the nearest 50.
      final r = calculateMaintenance(_profile(goal: WeightGoal.lose));
      expect(r.goals.kcal, 2250);
      expect(r.maintenanceKcal, 2750); // 2759 → nearest 50
      expect(r.clamped, isFalse);
      expect(r.maintenanceOnly, isFalse);
      // Macros: 25/30/45% at 4/9/4 kcal per gram, whole grams.
      expect(r.goals.protein, (2250 * 0.25 / 4).round());
      expect(r.goals.fat, (2250 * 0.30 / 9).round());
      expect(r.goals.carbs, (2250 * 0.45 / 4).round());
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

    test('deficit clamps at the goal floors', () {
      // BMR = 400 + 906.25 − 300 − 161 = 845.25; ×1.2 = 1014.3;
      // −500 = 514.3 → 500, below the 1200 floor → clamped to 1200.
      final r = calculateMaintenance(
        _profile(
          sex: Sex.female,
          age: 60,
          weightKg: 40,
          heightCm: 145,
          activity: ActivityLevel.sedentary,
          goal: WeightGoal.lose,
        ),
      );
      expect(r.clamped, isTrue);
      expect(r.goals.kcal, goalFloors.kcal);
      expect(r.goals.protein, greaterThanOrEqualTo(goalFloors.protein));
      expect(r.goals.fat, greaterThanOrEqualTo(goalFloors.fat));
      expect(r.goals.carbs, greaterThanOrEqualTo(goalFloors.carbs));
    });

    test('under 18 gets maintenance only, deficit ignored', () {
      final withDeficit = calculateMaintenance(
        _profile(age: 16, goal: WeightGoal.lose),
      );
      final maintain = calculateMaintenance(
        _profile(age: 16, goal: WeightGoal.maintain),
      );
      expect(withDeficit.maintenanceOnly, isTrue);
      expect(withDeficit.goals.kcal, maintain.goals.kcal);
    });

    test('gentle option applies −250 and gain +300', () {
      final base = calculateMaintenance(_profile()).goals.kcal;
      final gentle = calculateMaintenance(
        _profile(goal: WeightGoal.loseGently),
      ).goals.kcal;
      final gain = calculateMaintenance(
        _profile(goal: WeightGoal.gain),
      ).goals.kcal;
      expect(base - gentle, 250);
      expect(gain - base, 300);
    });

    test('profile JSON round trip is null tolerant', () {
      final p = _profile(sex: Sex.female, goal: WeightGoal.gain);
      final back = Profile.fromJson(p.toJson());
      expect(back.sex, Sex.female);
      expect(back.goal, WeightGoal.gain);
      // Malformed input falls back instead of throwing.
      final fallback = Profile.fromJson({'sex': 'bogus', 'age': 'x'});
      expect(fallback.sex, Sex.male);
      expect(fallback.age, 30);
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

    testWidgets('wizard end to end produces the same Goals as before', (
      tester,
    ) async {
      final state = await _pumpProfileScreen(tester);

      expect(find.text("What's your name? (optional)"), findsOneWidget);
      expect(find.text('1/7'), findsOneWidget);
      await walkToAge(tester);
      expect(find.text('How old are you?'), findsOneWidget);
      expect(find.text('3/7'), findsOneWidget);
      await enterAndContinue(tester, '30');
      await enterAndContinue(tester, '80');
      await enterAndContinue(tester, '180');

      // Activity step: descriptions and the exercise helper line.
      expect(find.text('What is your training intensity?'), findsOneWidget);
      expect(find.text('Exercise 4 to 5 times a week'), findsOneWidget);
      expect(
        find.textContaining('elevated heart rate activity'),
        findsOneWidget,
      );
      await tester.tap(find.text('Moderate'));
      await tester.pumpAndSettle();

      // Goal step: plain-language descriptions.
      expect(find.text('A moderate daily deficit'), findsOneWidget);
      await tester.tap(find.text('Lose weight'));
      await tester.pumpAndSettle();

      // Result summary (title shows in both the header slot and the card):
      // the math must not have changed with the UX rework.
      expect(find.text('Your suggested daily goal'), findsWidgets);
      await tester.tap(find.text('Use this goal'));
      await tester.pumpAndSettle();

      expect(state.goals.kcal, 2250); // same inputs, same result as v1
      expect(state.goals.protein, (2250 * 0.25 / 4).round());
      expect(state.profile, isNotNull);
      expect(state.profile!.weightKg, 80);
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
      await tester.tap(find.text('Maintain'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use this goal'));
      await tester.pumpAndSettle();

      expect(state.profile!.weightKg, 81.5);
      expect(state.profile!.heightCm, 175.5);
      // Mifflin with decimals: 10×81.5 + 6.25×175.5 − 150 + 5 = 1766.875;
      // ×1.55 = 2738.66 → 2750 to the nearest 50.
      expect(state.goals.kcal, 2750);
    });

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
      expect(find.text('ما مستوى نشاطك؟'), findsOneWidget);
      // All five cards with descriptions plus the helper line.
      expect(find.text('خامل'), findsOneWidget);
      expect(find.text('تمرين 4 إلى 5 مرات في الأسبوع'), findsOneWidget);
      expect(find.textContaining('يرفع نبض القلب'), findsOneWidget);
      expect(find.text('6/7'), findsOneWidget);
      final context = tester.element(find.text('ما مستوى نشاطك؟'));
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
      expect(find.text('How old are you?'), findsOneWidget); // still here
      expect(state.goals.kcal, 2000); // unchanged
    });

    testWidgets('back arrow steps backward, first step pops the screen', (
      tester,
    ) async {
      await _pumpProfileScreen(tester);
      await walkToAge(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('What is your sex?'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsNothing); // popped to settings
    });
  });
}
