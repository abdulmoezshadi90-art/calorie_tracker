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
  static const _savedMealsKey = 'saved_meals';
  static const _foodTabKey = 'food_tab_index';
  static const _historyFilterKey = 'history_filter';
  static const _historySortKey = 'history_sort';
  static const _mealsFilterKey = 'saved_meals_filter';
  static const _mealsSortKey = 'saved_meals_sort';

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

  List<SavedMeal> _savedMeals = [];
  List<SavedMeal> get savedMeals => List.unmodifiable(_savedMeals);

  /// Which food-selection tab was last open (0 = History, 1 = My Meals) —
  /// search_screen.dart's tab selector, persisted like any other pref.
  int foodTabIndex = 0;

  /// Single-select meal filter for each tab; null means "All meals". Kept
  /// independent per tab per the feature spec.
  MealType? historyFilter;
  SortOption historySort = SortOption.mostRecent;
  MealType? mealsFilter;
  SortOption mealsSort = SortOption.mostRecent;

  /// Aggregated per-food logging history, built from [_logsByDate] and
  /// cached here — see [historyEntries]. Cleared (never lazily patched) by
  /// every log mutation, so a stale cache can never leak past one rebuild.
  List<HistoryEntry>? _historyCache;

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

  /// Every food ever logged, aggregated across all days — never a separate
  /// store, always derived from [_logsByDate] and cached until the next log
  /// mutation invalidates it (search_screen.dart's History tab; do not call
  /// this inside build() on every frame, it's cheap but still O(entries)).
  /// Days are walked newest-first; within a food, the most recent DAY it
  /// appears wins for [HistoryEntry.lastLoggedAt]/[HistoryEntry.lastServings]
  /// (last entry that day, by list order), while count and meal types
  /// accumulate across every occurrence regardless of day.
  List<HistoryEntry> get historyEntries {
    final cached = _historyCache;
    if (cached != null) return cached;

    final dateKeys = _logsByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    final agg = <String, _HistoryAgg>{};
    for (final key in dateKeys) {
      final date = DateTime.parse(key);
      for (final entry in _logsByDate[key]!) {
        final meal = MealType.values.byName(entry.meal);
        final existing = agg[entry.foodId];
        if (existing == null) {
          agg[entry.foodId] = _HistoryAgg(
            lastLoggedAt: date,
            lastServings: entry.servings,
            logCount: 1,
            mealTypes: {meal},
          );
        } else {
          existing.logCount++;
          existing.mealTypes.add(meal);
          if (existing.lastLoggedAt == date) {
            // Same (most recent) day, a later entry in list order — wins.
            existing.lastServings = entry.servings;
          }
        }
      }
    }

    final result = [
      for (final e in agg.entries)
        if (foodById[e.key] != null)
          HistoryEntry(
            food: foodById[e.key]!,
            lastLoggedAt: e.value.lastLoggedAt,
            logCount: e.value.logCount,
            mealTypes: e.value.mealTypes,
            lastServings: e.value.lastServings,
          ),
    ];
    _historyCache = result;
    return result;
  }

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

  bool hasWeightOn(DateTime date) => _weightByDate.containsKey(dateKey(date));

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
    DateTime? loggedAt,
  }) async {
    final entry = LogEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}',
      foodId: foodId,
      servings: servings,
      meal: meal.name,
      unitId: unitId,
      quantity: quantity ?? servings,
      loggedAt: loggedAt,
    );
    _logsByDate.putIfAbsent(dateKey(date), () => []).add(entry);
    _historyCache = null;
    notifyListeners();
    if (await _save()) return true;
    _logsByDate[dateKey(date)]?.removeWhere((e) => e.id == entry.id);
    _historyCache = null;
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
    _historyCache = null;
    notifyListeners();
    if (await _save()) return (entry: removed, index: index);
    list.insert(index, removed);
    _historyCache = null;
    notifyListeners();
    return null;
  }

  /// Puts an undone-deleted entry back where it was.
  Future<bool> restoreEntry(DateTime date, LogEntry entry, int index) async {
    final list = _logsByDate.putIfAbsent(dateKey(date), () => []);
    list.insert(index.clamp(0, list.length), entry);
    _historyCache = null;
    notifyListeners();
    if (await _save()) return true;
    list.removeWhere((e) => e.id == entry.id);
    _historyCache = null;
    notifyListeners();
    return false;
  }

  /// Logs every item in [meal] into [date]/[targetMeal] at once (My Meals
  /// tab quick-add / detail-sheet add-all), then bumps the saved meal's
  /// usage stats for "Most recent"/"Most frequent" sorting. Returns the
  /// newly created entries' ids on success (so the caller can offer undo,
  /// same as every other mutation in this app — local storage has no
  /// backup for a mis-tap), or null if the write failed and everything was
  /// rolled back, log entries and usage-stat bump together.
  Future<List<String>?> logSavedMeal(
    DateTime date,
    MealType targetMeal,
    SavedMeal meal,
  ) async {
    final addedIds = <String>[];
    for (final item in meal.items) {
      final entry = LogEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}',
        foodId: item.foodId,
        servings: item.servings,
        meal: targetMeal.name,
      );
      _logsByDate.putIfAbsent(dateKey(date), () => []).add(entry);
      addedIds.add(entry.id);
    }
    _historyCache = null;
    final index = _savedMeals.indexWhere((m) => m.id == meal.id);
    final previousMeal = index >= 0 ? _savedMeals[index] : null;
    if (index >= 0) {
      _savedMeals[index] = meal.copyWith(
        lastUsedAt: now(),
        useCount: meal.useCount + 1,
      );
    }
    notifyListeners();
    if (await _save()) return addedIds;
    _logsByDate[dateKey(date)]?.removeWhere((e) => addedIds.contains(e.id));
    _historyCache = null;
    if (index >= 0 && previousMeal != null) _savedMeals[index] = previousMeal;
    notifyListeners();
    return null;
  }

  /// Removes several entries at once (undo for a multi-food add-all) — one
  /// [removeEntry] call per id, same rollback behavior as a single delete.
  Future<void> removeEntries(DateTime date, List<String> entryIds) async {
    for (final id in entryIds) {
      await removeEntry(date, id);
    }
  }

  /// Copies every entry from [fromDate]'s [fromMeal] into [toDate]'s
  /// [toMeal], preserving serving amounts — the Copy Previous Meal sheet.
  /// The source day is read only; it is never mutated, on success or
  /// rollback. Returns the new entries' ids (for undo) on success, null if
  /// the source meal was empty or the write failed.
  Future<List<String>?> copyMealEntries(
    DateTime fromDate,
    MealType fromMeal,
    DateTime toDate,
    MealType toMeal,
  ) async {
    final source = entriesFor(fromDate, meal: fromMeal);
    if (source.isEmpty) return null;
    final addedIds = <String>[];
    for (final e in source) {
      final entry = LogEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}',
        foodId: e.foodId,
        servings: e.servings,
        meal: toMeal.name,
        unitId: e.unitId,
        quantity: e.quantity,
      );
      _logsByDate.putIfAbsent(dateKey(toDate), () => []).add(entry);
      addedIds.add(entry.id);
    }
    _historyCache = null;
    notifyListeners();
    if (await _save()) return addedIds;
    _logsByDate[dateKey(toDate)]?.removeWhere((e) => addedIds.contains(e.id));
    _historyCache = null;
    notifyListeners();
    return null;
  }

  // ─────────────────────────── Saved meals ───────────────────────────

  Future<bool> addSavedMeal(SavedMeal meal) async {
    _savedMeals.add(meal);
    notifyListeners();
    if (await _save()) return true;
    _savedMeals.removeWhere((m) => m.id == meal.id);
    notifyListeners();
    return false;
  }

  Future<bool> updateSavedMeal(SavedMeal meal) async {
    final index = _savedMeals.indexWhere((m) => m.id == meal.id);
    if (index < 0) return false;
    final previous = _savedMeals[index];
    _savedMeals[index] = meal;
    notifyListeners();
    if (await _save()) return true;
    _savedMeals[index] = previous;
    notifyListeners();
    return false;
  }

  Future<bool> deleteSavedMeal(String id) async {
    final index = _savedMeals.indexWhere((m) => m.id == id);
    if (index < 0) return false;
    final removed = _savedMeals.removeAt(index);
    notifyListeners();
    if (await _save()) return true;
    _savedMeals.insert(index, removed);
    notifyListeners();
    return false;
  }

  /// Fresh, unused id for a new [SavedMeal] — same monotonic-suffix trick
  /// as log entry ids.
  String newSavedMealId() =>
      'meal_${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';

  Future<bool> setFoodTabIndex(int index) async {
    final previous = foodTabIndex;
    foodTabIndex = index;
    notifyListeners();
    if (await _save()) return true;
    foodTabIndex = previous;
    notifyListeners();
    return false;
  }

  Future<bool> setHistoryFilter(MealType? meal) async {
    final previous = historyFilter;
    historyFilter = meal;
    notifyListeners();
    if (await _save()) return true;
    historyFilter = previous;
    notifyListeners();
    return false;
  }

  Future<bool> setHistorySort(SortOption sort) async {
    final previous = historySort;
    historySort = sort;
    notifyListeners();
    if (await _save()) return true;
    historySort = previous;
    notifyListeners();
    return false;
  }

  Future<bool> setMealsFilter(MealType? meal) async {
    final previous = mealsFilter;
    mealsFilter = meal;
    notifyListeners();
    if (await _save()) return true;
    mealsFilter = previous;
    notifyListeners();
    return false;
  }

  Future<bool> setMealsSort(SortOption sort) async {
    final previous = mealsSort;
    mealsSort = sort;
    notifyListeners();
    if (await _save()) return true;
    mealsSort = previous;
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
    final rawTab = prefs.getInt(_foodTabKey) ?? 0;
    foodTabIndex = (rawTab < 0 || rawTab > 1) ? 0 : rawTab;
    historyFilter = _mealTypeFromName(prefs.getString(_historyFilterKey));
    historySort = _sortOptionFromName(prefs.getString(_historySortKey));
    mealsFilter = _mealTypeFromName(prefs.getString(_mealsFilterKey));
    mealsSort = _sortOptionFromName(prefs.getString(_mealsSortKey));
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
    final rawSavedMeals = prefs.getString(_savedMealsKey);
    if (rawSavedMeals != null) {
      // Same salvage spirit as the day-log decode below: one malformed
      // saved meal must not discard the rest.
      try {
        final decoded = jsonDecode(rawSavedMeals) as List;
        final meals = <SavedMeal>[];
        for (final m in decoded) {
          try {
            meals.add(SavedMeal.fromJson(m as Map<String, dynamic>));
          } catch (_) {
            // Skip the bad entry, keep the rest.
          }
        }
        _savedMeals = meals;
      } catch (_) {
        _savedMeals = [];
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

  static MealType? _mealTypeFromName(String? name) {
    if (name == null) return null;
    for (final m in MealType.values) {
      if (m.name == name) return m;
    }
    return null;
  }

  static SortOption _sortOptionFromName(String? name) {
    for (final s in SortOption.values) {
      if (s.name == name) return s;
    }
    return SortOption.mostRecent;
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
      await prefs.setInt(_foodTabKey, foodTabIndex);
      if (historyFilter != null) {
        await prefs.setString(_historyFilterKey, historyFilter!.name);
      } else {
        await prefs.remove(_historyFilterKey);
      }
      await prefs.setString(_historySortKey, historySort.name);
      if (mealsFilter != null) {
        await prefs.setString(_mealsFilterKey, mealsFilter!.name);
      } else {
        await prefs.remove(_mealsFilterKey);
      }
      await prefs.setString(_mealsSortKey, mealsSort.name);
      await prefs.setString(
        _savedMealsKey,
        jsonEncode(_savedMeals.map((m) => m.toJson()).toList()),
      );
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

/// Mutable accumulator used only while building [AppState.historyEntries] —
/// never exposed outside that getter.
class _HistoryAgg {
  _HistoryAgg({
    required this.lastLoggedAt,
    required this.lastServings,
    required this.logCount,
    required this.mealTypes,
  });
  DateTime lastLoggedAt;
  double lastServings;
  int logCount;
  Set<MealType> mealTypes;
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
