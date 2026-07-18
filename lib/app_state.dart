import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'food_db.dart';
import 'l10n.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  /// Injectable clock so tests (goldens especially) can pin the date.
  AppState({DateTime Function()? clock}) : now = clock ?? DateTime.now {
    selectedDate = now();
  }

  final DateTime Function() now;

  static const _logsKey = 'logs_v1';
  static const _localeKey = 'locale';
  static const _goalsKey = 'goals';
  static const _onboardingKey = 'onboarding_done';

  Goals _goals = Goals.defaults;
  Goals get goals => _goals;

  String localeCode = 'en';
  bool onboardingDone = false;
  // Shown in the header greeting; empty until profiles land, then the greeting
  // renders on its own.
  String userName = '';
  late DateTime selectedDate;
  final Map<String, List<LogEntry>> _logsByDate = {};

  L10n get l => L10n(localeCode);

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<LogEntry> entriesFor(DateTime date, {MealType? meal}) {
    final all = _logsByDate[dateKey(date)] ?? const [];
    if (meal == null) return List.unmodifiable(all);
    return all.where((e) => e.meal == meal.name).toList();
  }

  /// Foods logged to a meal on a day, in log order (skips unknown ids).
  List<FoodItem> foodsFor(DateTime date, MealType meal) => [
    for (final e in entriesFor(date, meal: meal))
      if (foodById[e.foodId] != null) foodById[e.foodId]!,
  ];

  /// How many of the four meals have at least one entry.
  int loggedMealCount(DateTime date) =>
      MealType.values.where((m) => entriesFor(date, meal: m).isNotEmpty).length;

  DayTotals totalsFor(DateTime date) {
    final totals = DayTotals();
    for (final entry in _logsByDate[dateKey(date)] ?? const <LogEntry>[]) {
      final food = foodById[entry.foodId];
      if (food == null) continue;
      totals.kcal += food.kcal * entry.servings;
      totals.protein += food.protein * entry.servings;
      totals.carbs += food.carbs * entry.servings;
      totals.fat += food.fat * entry.servings;
      totals.kcalPerMeal.update(
        entry.meal,
        (v) => v + food.kcal * entry.servings,
        ifAbsent: () => food.kcal * entry.servings,
      );
    }
    return totals;
  }

  /// Days with at least one logged entry, newest first.
  List<DateTime> loggedDates() {
    final dates = <DateTime>[
      for (final e in _logsByDate.entries)
        if (e.value.isNotEmpty) DateTime.parse(e.key),
    ];
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void addEntry(DateTime date, String foodId, double servings, MealType meal) {
    final entry = LogEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      foodId: foodId,
      servings: servings,
      meal: meal.name,
    );
    _logsByDate.putIfAbsent(dateKey(date), () => []).add(entry);
    notifyListeners();
    _save();
  }

  void removeEntry(DateTime date, String entryId) {
    _logsByDate[dateKey(date)]?.removeWhere((e) => e.id == entryId);
    notifyListeners();
    _save();
  }

  void setGoals(Goals goals) {
    _goals = goals;
    notifyListeners();
    _save();
  }

  void toggleLocale() => setLocale(localeCode == 'en' ? 'ar' : 'en');

  void setLocale(String code) {
    localeCode = code;
    notifyListeners();
    _save();
  }

  void completeOnboarding() {
    onboardingDone = true;
    notifyListeners();
    _save();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    localeCode = prefs.getString(_localeKey) ?? 'en';
    onboardingDone = prefs.getBool(_onboardingKey) ?? false;
    final rawGoals = prefs.getString(_goalsKey);
    if (rawGoals != null) {
      _goals = Goals.fromJson(jsonDecode(rawGoals) as Map<String, dynamic>);
    }
    final raw = prefs.getString(_logsKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((date, list) {
        _logsByDate[date] = (list as List)
            .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, localeCode);
    await prefs.setString(_goalsKey, jsonEncode(_goals.toJson()));
    await prefs.setBool(_onboardingKey, onboardingDone);
    await prefs.setString(
      _logsKey,
      jsonEncode(
        _logsByDate.map(
          (date, list) => MapEntry(date, list.map((e) => e.toJson()).toList()),
        ),
      ),
    );
  }
}

/// Exposes [AppState] to the widget tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
