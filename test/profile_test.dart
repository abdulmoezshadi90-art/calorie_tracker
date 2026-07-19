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
  int weightKg = 80,
  int heightCm = 180,
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

  group('profile screen', () {
    testWidgets('renders RTL at 375x812 without overflow', (tester) async {
      await _pumpProfileScreen(tester, locale: 'ar');

      expect(tester.takeException(), isNull);
      expect(find.text('ملفك الشخصي'), findsOneWidget);
      // The button sits below the fold in the lazy ListView; scroll to it.
      await tester.scrollUntilVisible(
        find.text('احسب هدفي'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('احسب هدفي'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final context = tester.element(find.text('ملفك الشخصي'));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('Eastern Arabic input ٢٥ stores 25 in the age field', (
      tester,
    ) async {
      await _pumpProfileScreen(tester);

      final ageField = find.widgetWithText(TextField, 'Age');
      await tester.enterText(ageField, '٢٥');
      expect(tester.widget<TextField>(ageField).controller!.text, '25');
    });

    testWidgets('calculate and use saves through the Goals object', (
      tester,
    ) async {
      final state = await _pumpProfileScreen(tester);

      await tester.tap(find.text('Male'));
      await tester.enterText(find.widgetWithText(TextField, 'Age'), '30');
      await tester.enterText(
        find.widgetWithText(TextField, 'Weight (kg)'),
        '80',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Height (cm)'),
        '180',
      );
      await tester.scrollUntilVisible(
        find.text('Lose weight'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lose weight'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Calculate my goal'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Calculate my goal'));
      await tester.pumpAndSettle();

      expect(find.text('Your suggested daily goal'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Use this goal'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Use this goal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use this goal'));
      await tester.pumpAndSettle();

      expect(state.goals.kcal, 2250);
      expect(state.profile, isNotNull);
      expect(state.profile!.weightKg, 80);
    });

    testWidgets('out of range age shows error, nothing saved', (tester) async {
      final state = await _pumpProfileScreen(tester);

      await tester.tap(find.text('Male'));
      await tester.enterText(find.widgetWithText(TextField, 'Age'), '9');
      await tester.enterText(
        find.widgetWithText(TextField, 'Weight (kg)'),
        '80',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Height (cm)'),
        '180',
      );
      await tester.scrollUntilVisible(
        find.text('Calculate my goal'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Calculate my goal'));
      await tester.pumpAndSettle();

      expect(find.text('Complete the fields above'), findsOneWidget);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(state.goals.kcal, 2000); // unchanged
    });
  });
}
