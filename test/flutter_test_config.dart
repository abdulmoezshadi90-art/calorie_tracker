import 'dart:async';

import 'package:calorie_tracker/splash_screen.dart';

/// Applies to every test file in this directory (Flutter's own convention,
/// no per-file imports needed). Zeroes out AppStartup's artificial splash
/// delay — every test that pumps CalorieApp goes through it, and the real
/// 1200ms cost real wall-clock time across the whole suite even though
/// it's fake-clock time from the test framework's point of view.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppStartup.splashDuration = Duration.zero;
  await testMain();
}
