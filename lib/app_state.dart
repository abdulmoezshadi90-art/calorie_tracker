import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'food_db.dart';
import 'l10n.dart';
import 'models.dart';
import 'profile.dart';

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
  static const _profileKey = 'profile';
  static const _weightsKey = 'weights_v1';
  static const _quantityModeKey = 'quantity_mode';
  static const _themeModeKey = 'theme_mode';

  Goals _goals = Goals.defaults;
  Goals get goals => _goals;

  /// Local profile (decision 8) — optional, never an account.
  Profile? _profile;
  Profile? get profile => _profile;

  String localeCode = 'en';
  bool onboardingDone = false;
  // Shown in the header greeting; sourced from the profile name (greeting
  // only, stored locally, never transmitted).
  String userName = '';
  late DateTime selectedDate;
  final Map<String, List<LogEntry>> _logsByDate = {};

  // One weight per day (kg), keyed yyyy-MM-dd — mirrors the day-log store.
  final Map<String, double> _weightByDate = {};

  // Monotonic suffix so entries logged in the same microsecond still get
  // unique ids (delete and undo target by id).
  int _idSeq = 0;

  /// 'fraction' or 'decimal' — the food detail page's quantity input mode,
  /// remembered across sessions like any other preference.
  String quantityMode = 'decimal';

  /// 'system' (default), 'light', or 'dark' — the settings appearance
  /// toggle. Stored as the raw preference string (like [quantityMode]) so
  /// an unrecognized future value can't crash [themeMode]'s mapping.
  String themeModeCode = 'system';

  ThemeMode get themeMode => switch (themeModeCode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

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

  /// Consecutive days with at least one logged entry, ending today — or
  /// yesterday, so an unlogged morning doesn't zero it. Derived from the
  /// day logs, no extra persistence; a broken streak just resets quietly
  /// (design decision 2: no guilt framing).
  int get streak {
    final t = now();
    var day = DateTime(t.year, t.month, t.day);
    if (entriesFor(day).isEmpty) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while (entriesFor(day).isNotEmpty) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  // ─────────────────────────── Weight log ───────────────────────────

  bool hasWeightOn(DateTime date) =>
      _weightByDate.containsKey(dateKey(date));

  /// All weight entries as (date, kg), oldest first — chart reading order.
  List<({DateTime date, double kg})> weightEntries() {
    final entries = [
      for (final e in _weightByDate.entries)
        (date: DateTime.parse(e.key), kg: e.value),
    ];
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  /// Logs (or overwrites) one weight for [date]. Write-safe: rolls back
  /// on a failed write. Callers confirm before overwriting an existing day.
  Future<bool> logWeight(DateTime date, double kg) async {
    final key = dateKey(date);
    final previous = _weightByDate[key];
    _weightByDate[key] = kg;
    notifyListeners();
    if (await _save()) return true;
    if (previous == null) {
      _weightByDate.remove(key);
    } else {
      _weightByDate[key] = previous;
    }
    notifyListeners();
    return false;
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

  // Every mutation applies in memory, persists, and ROLLS BACK on a
  // failed write (disk full, permission): the UI must never show success
  // for data that was not actually saved. Callers check the result and
  // surface the inline "couldn't save" error where it matters.

  /// Adds a log entry; false (and no visible entry) if the write failed.
  /// [servings] is the actual multiplier used everywhere in totals math;
  /// [unitId]/[quantity] are the serving-unit picker's inputs, carried
  /// along for display only (default to the legacy single-serving shape).
  Future<bool> addEntry(
    DateTime date,
    String foodId,
    double servings,
    MealType meal, {
    String unitId = 'serving',
    double? quantity,
  }) async {
    final entry = LogEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}',
      foodId: foodId,
      servings: servings,
      meal: meal.name,
      unitId: unitId,
      quantity: quantity ?? servings,
    );
    _logsByDate.putIfAbsent(dateKey(date), () => []).add(entry);
    notifyListeners();
    if (await _save()) return true;
    _logsByDate[dateKey(date)]?.removeWhere((e) => e.id == entry.id);
    notifyListeners();
    return false;
  }

  /// Removes an entry, returning it (with its position) so callers can
  /// offer undo via [restoreEntry]. Null if not found or write failed.
  Future<({LogEntry entry, int index})?> removeEntry(
    DateTime date,
    String entryId,
  ) async {
    final list = _logsByDate[dateKey(date)];
    final index = list?.indexWhere((e) => e.id == entryId) ?? -1;
    if (list == null || index < 0) return null;
    final removed = list.removeAt(index);
    notifyListeners();
    if (await _save()) return (entry: removed, index: index);
    list.insert(index, removed);
    notifyListeners();
    return null;
  }

  /// Puts an undone-deleted entry back where it was.
  Future<bool> restoreEntry(DateTime date, LogEntry entry, int index) async {
    final list = _logsByDate.putIfAbsent(dateKey(date), () => []);
    list.insert(index.clamp(0, list.length), entry);
    notifyListeners();
    if (await _save()) return true;
    list.removeWhere((e) => e.id == entry.id);
    notifyListeners();
    return false;
  }

  Future<bool> setGoals(Goals goals) async {
    final previous = _goals;
    _goals = goals;
    notifyListeners();
    if (await _save()) return true;
    _goals = previous;
    notifyListeners();
    return false;
  }

  Future<bool> setProfile(Profile profile) async {
    final previousProfile = _profile;
    final previousName = userName;
    // Seed the weight log from the wizard answer so the trend graph is
    // never empty for profile users. Only when there are no entries yet
    // and today has none, so recalculating never overwrites a real log.
    final today = dateKey(now());
    final seedWeight =
        _weightByDate.isEmpty && !_weightByDate.containsKey(today);
    _profile = profile;
    userName = profile.name.trim();
    if (seedWeight) _weightByDate[today] = profile.weightKg;
    notifyListeners();
    if (await _save()) return true;
    _profile = previousProfile;
    userName = previousName;
    if (seedWeight) _weightByDate.remove(today);
    notifyListeners();
    return false;
  }

  Future<bool> setQuantityMode(String mode) async {
    final previous = quantityMode;
    quantityMode = mode;
    notifyListeners();
    if (await _save()) return true;
    quantityMode = previous;
    notifyListeners();
    return false;
  }

  Future<bool> setThemeMode(String code) async {
    final previous = themeModeCode;
    themeModeCode = code;
    notifyListeners();
    if (await _save()) return true;
    themeModeCode = previous;
    notifyListeners();
    return false;
  }

  Future<bool> toggleLocale() => setLocale(localeCode == 'en' ? 'ar' : 'en');

  Future<bool> setLocale(String code) async {
    final previous = localeCode;
    localeCode = code;
    notifyListeners();
    if (await _save()) return true;
    localeCode = previous;
    notifyListeners();
    return false;
  }

  Future<bool> completeOnboarding() async {
    onboardingDone = true;
    notifyListeners();
    // Never trap the user in onboarding over a failed flag write; worst
    // case it replays next launch.
    return _save();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    localeCode = prefs.getString(_localeKey) ?? 'en';
    onboardingDone = prefs.getBool(_onboardingKey) ?? false;
    quantityMode = prefs.getString(_quantityModeKey) ?? 'decimal';
    themeModeCode = prefs.getString(_themeModeKey) ?? 'system';
    // Corrupted storage (interrupted write, flaky flash on cheap phones)
    // must never brick startup: with no backend, an unlaunchable app means
    // reinstall and total data loss. Fall back per key instead of throwing.
    final rawGoals = prefs.getString(_goalsKey);
    if (rawGoals != null) {
      try {
        _goals = Goals.fromJson(jsonDecode(rawGoals) as Map<String, dynamic>);
      } catch (_) {
        _goals = Goals.defaults;
      }
    }
    final rawProfile = prefs.getString(_profileKey);
    if (rawProfile != null) {
      try {
        _profile = Profile.fromJson(
          jsonDecode(rawProfile) as Map<String, dynamic>,
        );
        userName = _profile!.name.trim();
      } catch (_) {
        _profile = null;
      }
    }
    final rawWeights = prefs.getString(_weightsKey);
    if (rawWeights != null) {
      // Salvage per entry like the diary: skip malformed, keep the rest.
      try {
        final decoded = jsonDecode(rawWeights) as Map<String, dynamic>;
        decoded.forEach((date, kg) {
          if (DateTime.tryParse(date) != null && kg is num) {
            _weightByDate[date] = kg.toDouble();
          }
        });
      } catch (_) {
        _weightByDate.clear();
      }
    }
    final raw = prefs.getString(_logsKey);
    if (raw != null) {
      // Salvage per day and per entry: one malformed record must not
      // discard the rest of the diary (same spirit as Goals.fromJson).
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((date, list) {
          if (DateTime.tryParse(date) == null || list is! List) return;
          final entries = <LogEntry>[];
          for (final e in list) {
            try {
              entries.add(LogEntry.fromJson(e as Map<String, dynamic>));
            } catch (_) {
              // Skip the bad entry, keep the day.
            }
          }
          if (entries.isNotEmpty) _logsByDate[date] = entries;
        });
      } catch (_) {
        _logsByDate.clear();
      }
    }
  }

  /// Simulates a storage write failure (disk full etc.) in tests.
  @visibleForTesting
  bool debugFailWrites = false;

  /// True when everything persisted; false swallows nothing silently —
  /// mutators roll back and their callers show the inline error.
  Future<bool> _save() async {
    try {
      if (debugFailWrites) throw StateError('simulated write failure');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, localeCode);
      await prefs.setString(_goalsKey, jsonEncode(_goals.toJson()));
      await prefs.setBool(_onboardingKey, onboardingDone);
      await prefs.setString(_quantityModeKey, quantityMode);
      await prefs.setString(_themeModeKey, themeModeCode);
      if (_profile != null) {
        await prefs.setString(_profileKey, jsonEncode(_profile!.toJson()));
      }
      await prefs.setString(_weightsKey, jsonEncode(_weightByDate));
      await prefs.setString(
        _logsKey,
        jsonEncode(
          _logsByDate.map(
            (date, list) =>
                MapEntry(date, list.map((e) => e.toJson()).toList()),
          ),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Exposes [AppState] to the widget tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing — safe in initState and callbacks.
  static AppState read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget
              as AppScope)
          .notifier!;
}
