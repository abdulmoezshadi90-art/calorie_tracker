import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/models.dart';

void main() {
  final today = DateTime(2026, 7, 15, 9, 30);

  AppState state() {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    return AppState(clock: () => today);
  }

  void log(AppState s, DateTime day) =>
      s.addEntry(day, 'bazin', 1, MealType.lunch);

  test('no logs → streak 0', () {
    expect(state().streak, 0);
  });

  test('today plus two prior days → 3', () {
    final s = state();
    log(s, today);
    log(s, DateTime(2026, 7, 14));
    log(s, DateTime(2026, 7, 13));
    expect(s.streak, 3);
  });

  test('unlogged today keeps the running streak (counts from yesterday)', () {
    final s = state();
    log(s, DateTime(2026, 7, 14));
    log(s, DateTime(2026, 7, 13));
    expect(s.streak, 2);
  });

  test('a gap resets quietly — only the run ending now counts', () {
    final s = state();
    log(s, today);
    // 14th missing.
    log(s, DateTime(2026, 7, 13));
    log(s, DateTime(2026, 7, 12));
    expect(s.streak, 1);
  });

  test('logs ending before yesterday do not count', () {
    final s = state();
    log(s, DateTime(2026, 7, 12));
    log(s, DateTime(2026, 7, 11));
    expect(s.streak, 0);
  });
}
