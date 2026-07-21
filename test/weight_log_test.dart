import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/profile.dart';

void main() {
  group('weight persistence', () {
    test('logged weights survive an AppState reload', () async {
      SharedPreferences.setMockInitialValues({'onboarding_done': true});
      final state = AppState(clock: () => DateTime(2026, 7, 15));
      await state.load();

      await state.logWeight(DateTime(2026, 7, 13), 81.5);
      await state.logWeight(DateTime(2026, 7, 15), 80);

      final reloaded = AppState(clock: () => DateTime(2026, 7, 15));
      await reloaded.load();
      final entries = reloaded.weightEntries();
      expect(entries.length, 2);
      expect(entries.first.kg, 81.5); // oldest first
      expect(entries.last.kg, 80);
    });

    test('same day overwrites, one entry per day', () async {
      SharedPreferences.setMockInitialValues({'onboarding_done': true});
      final state = AppState(clock: () => DateTime(2026, 7, 15));
      await state.load();

      await state.logWeight(DateTime(2026, 7, 15), 80);
      expect(state.hasWeightOn(DateTime(2026, 7, 15)), isTrue);
      await state.logWeight(DateTime(2026, 7, 15), 79.5);

      final entries = state.weightEntries();
      expect(entries.length, 1);
      expect(entries.single.kg, 79.5);
    });

    test('profile save seeds the first weight entry, once', () async {
      SharedPreferences.setMockInitialValues({'onboarding_done': true});
      final state = AppState(clock: () => DateTime(2026, 7, 15));
      await state.load();
      expect(state.weightEntries(), isEmpty);

      await state.setProfile(
        const Profile(
          name: '',
          sex: Sex.male,
          age: 30,
          weightKg: 82,
          heightCm: 180,
          activity: ActivityLevel.moderate,
          goal: WeightGoal.maintain,
        ),
      );
      expect(state.weightEntries().single.kg, 82);

      // A real log then a recalculate must not re-seed / overwrite it.
      await state.logWeight(DateTime(2026, 7, 15), 81);
      await state.setProfile(
        const Profile(
          name: '',
          sex: Sex.male,
          age: 31,
          weightKg: 70, // different profile weight
          heightCm: 180,
          activity: ActivityLevel.high,
          goal: WeightGoal.lose,
        ),
      );
      expect(state.weightEntries().single.kg, 81); // real log preserved
    });
  });

  testWidgets('same-day log asks to replace before overwriting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final state = AppState();
    await state.load();
    await state.logWeight(state.now(), 80);
    await tester.pumpWidget(CalorieApp(state: state));
    await tester.pumpAndSettle();

    // Settings → Log weight.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log weight'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '79.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Replace confirm appears; confirm applies the new value.
    expect(
      find.text("You already logged today's weight. Replace it?"),
      findsOneWidget,
    );
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(state.weightEntries().single.kg, 79.5);
  });
}
