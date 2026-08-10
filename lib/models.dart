import 'package:flutter/material.dart';

/// A household portion with an exact gram definition (Phase 4): users pick
/// "ladle" or "small plate"; the app knows the grams. Precision lives in
/// the data, simplicity in the UI.
class PortionPreset {
  final String nameEn;
  final String nameAr;
  final double grams;
  const PortionPreset(this.nameEn, this.nameAr, this.grams);
}

/// A food item in the local database. Nutrition values are per one serving.
///
/// [verified] and [sourceNote] exist ahead of the Phase 2 data pipeline so
/// verified entries land in final shape. Values change ONLY through that
/// pipeline (label photo → extraction → owner verification) — never edited
/// ad hoc. Home dishes stay computed-from-recipe and display as approximate.
class FoodItem {
  final String id;
  final String nameEn;
  final String nameAr;
  final String servingEn;
  final String servingAr;
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;
  final FoodCategory category;

  /// True only once the owner has verified the values against a label
  /// (packaged) or a documented reference recipe (home dishes).
  final bool verified;

  /// Where the numbers come from: label basis (e.g. "per 100g drained"),
  /// recipe reference, or the placeholder marker. Never empty.
  final String sourceNote;

  /// EAN/UPC from the label, collected now for the Phase 9 barcode scanner
  /// (see CLAUDE.md → DATA PIPELINE). Not read anywhere in the app yet; null
  /// when the label's barcode wasn't captured.
  final String? barcode;

  /// Grams of ONE base serving, transcribed from the serving label (null
  /// when the label has no gram weight). Nutrition stays per serving;
  /// presets are gram multiples of this. Also the anchor [genericUnits]
  /// needs to convert a generic weight/volume quantity into base servings —
  /// foods without it get named servings only (see [genericUnits]).
  final double? servingGrams;

  /// Household portions shown as chips in the add sheet. Empty for foods
  /// not yet populated (top staples first; refined with beta data).
  final List<PortionPreset> presets;

  /// True for foods measured by volume (milk, drinks) rather than weight —
  /// gates which [GenericUnitKind] set [genericUnits] offers. Defaults to
  /// false (solid); set explicitly per food in food_db.dart.
  final bool isLiquid;

  /// Grams per millilitre for [isLiquid] foods — the only thing standing
  /// between a generic volume unit (ml, cup, tbsp…) and the grams the
  /// macro math runs on. Defaults to water's density (1 g/ml) until a
  /// specific food's label states otherwise; override per food when that
  /// data lands (do not guess it now).
  final double densityGPerMl;

  /// Servings equivalent of [preset], rounded to 2 decimals so displayed
  /// serving counts stay tidy. Requires [servingGrams].
  double servingsFor(PortionPreset preset) =>
      ((preset.grams / servingGrams!) * 100).round() / 100;

  /// Ways to log this food's quantity via its OWN named serving, plus any
  /// household presets it already defines. Never invents a weight for foods
  /// whose label states none (e.g. "1 cone", "2 eggs") — see [genericUnits]
  /// for the separate, opt-in-when-anchored universal weight/volume picker.
  List<ServingUnit> get servingUnits => [
    ServingUnit(
      id: 'serving',
      labelEn: servingEn,
      labelAr: servingAr,
      grams: servingGrams,
    ),
    for (final p in presets)
      ServingUnit(
        id: p.nameEn,
        labelEn: p.nameEn,
        labelAr: p.nameAr,
        grams: p.grams,
      ),
  ];

  /// Standard weight or volume units alongside this food's named servings —
  /// the conversion factors in [GenericUnitKind] are fixed physical
  /// constants, never per-food data, so offering them never risks inventing
  /// a number. Empty when [servingGrams] is null: there is no anchor to
  /// convert a gram/ml quantity into base servings, so offering these units
  /// would silently compute wrong macros rather than merely looking odd.
  List<ServingUnit> get genericUnits {
    if (servingGrams == null) return const [];
    final kinds = isLiquid
        ? GenericUnitKind.liquidKinds
        : GenericUnitKind.solidKinds;
    return [
      for (final k in kinds)
        ServingUnit(
          id: GenericUnitKind.idFor(k),
          // Real display text comes from L10n.unitLabel, which recognizes
          // this id and overrides it with the localized generic label;
          // these are just non-displayed structural fallbacks.
          labelEn: k.name,
          labelAr: k.name,
          grams: isLiquid ? k.unitsPerBase * densityGPerMl : k.unitsPerBase,
        ),
    ];
  }

  /// Multiplier against the base serving for [quantity] of [unit]. Foods
  /// with no known gram weight (unit.grams or servingGrams null) treat
  /// quantity as a plain count of the base serving — identical to the
  /// stepper behavior that existed before serving units did.
  double multiplierFor(ServingUnit unit, double quantity) {
    if (unit.grams == null || servingGrams == null) return quantity;
    return quantity * unit.grams! / servingGrams!;
  }

  const FoodItem({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.servingEn,
    required this.servingAr,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.category,
    this.verified = false,
    this.sourceNote = 'Placeholder — unverified development estimate',
    this.barcode,
    this.servingGrams,
    this.presets = const [],
    this.isLiquid = false,
    this.densityGPerMl = 1.0,
  });
}

enum FoodCategory { snack, main, breakfast, sweet, drink }

/// Sort options shared by the History and My Meals tabs (search_screen.dart).
/// "Most recent"/"Most frequent" read different underlying fields per tab
/// (lastLoggedAt/logCount for history, lastUsedAt-or-createdAt/useCount for
/// saved meals) — sorting itself happens in each tab's State, memoized
/// against AppState.historyEntries/savedMeals + the active filter/sort.
enum SortOption { mostRecent, mostFrequent, aToZ, zToA }

/// One way to log a food's quantity — the food's OWN serving scale (its
/// named serving, or one of its household presets), or a generic
/// weight/volume unit (id `generic_<kind name>`, see
/// [FoodItem.genericUnits]). [grams] is null only for a food-specific unit
/// whose label carries no weight at all; generic units always have one.
class ServingUnit {
  final String id;
  final String labelEn;
  final String labelAr;
  final double? grams;
  const ServingUnit({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    this.grams,
  });
}

/// Universal weight/volume units offered alongside a food's own named
/// servings (see [FoodItem.genericUnits]). [unitsPerBase] is grams for the
/// solid kinds, millilitres for the liquid ones — fixed physical
/// conversion factors, never per-food nutrition data.
enum GenericUnitKind {
  gram(1),
  hundredGrams(100),
  kilogram(1000),
  ounce(28.3495),
  pound(453.592),
  milliliter(1),
  hundredMilliliters(100),
  liter(1000),
  // Nutrition-label reference amounts (FDA-style rounding), matching the
  // convention this app's own data already uses (e.g. "1 cup (240 ml)")
  // rather than the precise US customary fluid ounce (29.5735 ml).
  fluidOunce(30),
  cup(240),
  tablespoon(15),
  teaspoon(5);

  const GenericUnitKind(this.unitsPerBase);
  final double unitsPerBase;

  static const solidKinds = [gram, hundredGrams, kilogram, ounce, pound];
  static const liquidKinds = [
    milliliter,
    hundredMilliliters,
    liter,
    fluidOunce,
    cup,
    tablespoon,
    teaspoon,
  ];

  static String idFor(GenericUnitKind k) => 'generic_${k.name}';

  /// Null when [id] isn't a generic-unit id (a food-specific ServingUnit).
  static GenericUnitKind? fromUnitId(String id) {
    for (final k in values) {
      if (id == idFor(k)) return k;
    }
    return null;
  }
}

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  /// Bundled tintable glyph (issue #8) — render via [MealIcon], not Image
  /// directly, so sizing and tinting stay consistent.
  String get asset => 'assets/icons/meal_$name.png';
}

/// The bundled meal glyph, tinted like an [Icon].
class MealIcon extends StatelessWidget {
  const MealIcon(this.meal, {super.key, required this.size, this.color});
  final MealType meal;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Image.asset(
    meal.asset,
    width: size,
    height: size,
    color: color ?? IconTheme.of(context).color,
    // Screen readers announce the meal, not "image".
    semanticLabel: meal.name,
  );
}

/// One logged food, tied to a meal on a given day.
///
/// [servings] is the actual multiplier against the food's per-serving
/// macros — every totals calculation in the app reads only this, so it
/// never changes meaning. [unitId] and [quantity] are the serving-unit
/// picker's own inputs, kept alongside for display ("2 × 100 g") and
/// carried through unchanged; legacy entries (pre serving-units) have
/// neither, so they fall back to unit 'serving' with quantity = servings.
class LogEntry {
  final String id;
  final String foodId;
  final double servings;
  final String meal; // MealType.name
  final String unitId;
  final double quantity;

  /// Wall-clock time of day the food was eaten/logged, set from the food
  /// detail screen's Time row. Null for every entry logged before that row
  /// existed — decode never fails on a missing key, and display falls back
  /// to showing nothing rather than a placeholder time.
  final DateTime? loggedAt;

  const LogEntry({
    required this.id,
    required this.foodId,
    required this.servings,
    required this.meal,
    this.unitId = 'serving',
    double? quantity,
    this.loggedAt,
  }) : quantity = quantity ?? servings;

  Map<String, dynamic> toJson() => {
    'id': id,
    'foodId': foodId,
    'servings': servings,
    'meal': meal,
    'unitId': unitId,
    'quantity': quantity,
    'loggedAt': loggedAt?.toIso8601String(),
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    final servings = (json['servings'] as num).toDouble();
    return LogEntry(
      id: json['id'] as String,
      foodId: json['foodId'] as String,
      servings: servings,
      meal: json['meal'] as String,
      unitId: json['unitId'] as String? ?? 'serving',
      quantity: (json['quantity'] as num?)?.toDouble() ?? servings,
      loggedAt: switch (json['loggedAt']) {
        final String s => DateTime.tryParse(s),
        _ => null,
      },
    );
  }
}

/// One food's aggregated logging history across every day. Never stored on
/// its own — always derived from day logs by AppState.historyEntries, which
/// caches the result and invalidates it on any log mutation. [lastLoggedAt]
/// is day-resolution only (LogEntry itself carries no wall-clock timestamp,
/// only the day-key it lives under), which is the finest recency this data
/// can honestly support.
class HistoryEntry {
  const HistoryEntry({
    required this.food,
    required this.lastLoggedAt,
    required this.logCount,
    required this.mealTypes,
    required this.lastServings,
  });
  final FoodItem food;
  final DateTime lastLoggedAt;
  final int logCount;
  final Set<MealType> mealTypes;
  final double lastServings;
}

/// One food line inside a [SavedMeal] — a plain (foodId, servings) pair,
/// the same shape LogEntry uses for its own servings multiplier.
class SavedMealItem {
  const SavedMealItem({required this.foodId, required this.servings});
  final String foodId;
  final double servings;

  Map<String, dynamic> toJson() => {'foodId': foodId, 'servings': servings};

  factory SavedMealItem.fromJson(Map<String, dynamic> json) => SavedMealItem(
    foodId: json['foodId'] as String,
    servings: (json['servings'] as num).toDouble(),
  );
}

/// A user-built combo of foods, saved once and logged again with one tap.
/// [name] is a single string the user typed themselves — unlike [FoodItem],
/// there is no EN/AR pair here and it is never translated.
class SavedMeal {
  const SavedMeal({
    required this.id,
    required this.name,
    required this.mealType,
    required this.items,
    required this.createdAt,
    this.lastUsedAt,
    this.useCount = 0,
  });
  final String id;
  final String name;

  /// Null means no meal-type tag; such a meal only shows up under the "All
  /// meals" filter, never under a specific meal filter.
  final MealType? mealType;
  final List<SavedMealItem> items;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int useCount;

  SavedMeal copyWith({
    String? name,
    MealType? mealType,
    bool clearMealType = false,
    List<SavedMealItem>? items,
    DateTime? lastUsedAt,
    int? useCount,
  }) => SavedMeal(
    id: id,
    name: name ?? this.name,
    mealType: clearMealType ? null : (mealType ?? this.mealType),
    items: items ?? this.items,
    createdAt: createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    useCount: useCount ?? this.useCount,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mealType': mealType?.name,
    'items': items.map((i) => i.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'lastUsedAt': lastUsedAt?.toIso8601String(),
    'useCount': useCount,
  };

  factory SavedMeal.fromJson(Map<String, dynamic> json) {
    final mealTypeName = json['mealType'] as String?;
    final lastUsed = json['lastUsedAt'] as String?;
    return SavedMeal(
      id: json['id'] as String,
      name: json['name'] as String,
      mealType: mealTypeName == null
          ? null
          : MealType.values.byName(mealTypeName),
      items: [
        for (final i in json['items'] as List)
          SavedMealItem.fromJson(i as Map<String, dynamic>),
      ],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: lastUsed == null ? null : DateTime.parse(lastUsed),
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Anti-eating-disorder floors: values below these get a gentle confirm,
/// never a hard block (design decision 2). The maintenance calculation
/// clamps to these too (decision 8).
const goalFloors = (kcal: 1200, carbs: 50, fat: 20, protein: 30);

/// Daily nutrition goals. Values are whole units: kcal and grams.
class Goals {
  final int kcal;
  final int carbs;
  final int fat;
  final int protein;

  const Goals({
    required this.kcal,
    required this.carbs,
    required this.fat,
    required this.protein,
  });

  static const Goals defaults = Goals(
    kcal: 2000,
    carbs: 220,
    fat: 65,
    protein: 110,
  );

  Map<String, dynamic> toJson() => {
    'kcal': kcal,
    'carbs': carbs,
    'fat': fat,
    'protein': protein,
  };

  /// Null tolerant: any missing or malformed field falls back to its default,
  /// so goals saved by older app versions keep working as fields are added.
  factory Goals.fromJson(Map<String, dynamic> json) => Goals(
    kcal: (json['kcal'] as num?)?.round() ?? defaults.kcal,
    carbs: (json['carbs'] as num?)?.round() ?? defaults.carbs,
    fat: (json['fat'] as num?)?.round() ?? defaults.fat,
    protein: (json['protein'] as num?)?.round() ?? defaults.protein,
  );
}

class DayTotals {
  double kcal = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;
  final Map<String, double> kcalPerMeal = {};
}

/// Formats an integer with thousands separators, always Western digits.
String fmtInt(num value) {
  final s = value.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final remaining = s.length - 1 - i;
    if (remaining > 0 && remaining % 3 == 0 && s[i] != '-') buf.write(',');
  }
  return buf.toString();
}

/// Grams shown as a whole number, or one decimal when < 10 and fractional.
String fmtGrams(double value) {
  if (value == value.roundToDouble() || value >= 10) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}

String fmtServings(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

/// Western-digit percent, e.g. "42%".
String fmtPercent(num value) => '${fmtInt(value)}%';

/// 24-hour "HH:MM", always Western digits — never a locale-aware clock
/// format (which can inject AM/PM or non-Western digits).
String fmtTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// Unicode vulgar fraction glyphs for the app's five quantity presets —
/// not a general float-to-fraction converter, just these exact values
/// (Western digits either side by construction: only the glyph varies).
const _fractionGlyphs = {1: '¼', 2: '⅓', 3: '½', 4: '⅔', 5: '¾'};

/// [whole] plus a preset fraction (1=1/4, 2=1/3, 3=1/2, 4=2/3, 5=3/4, or
/// 0 for none), e.g. fmtFraction(2, 3) → "2 ½".
String fmtFraction(int whole, int fractionPreset) {
  final glyph = _fractionGlyphs[fractionPreset];
  if (glyph == null) return fmtInt(whole);
  return whole == 0 ? glyph : '${fmtInt(whole)} $glyph';
}

/// Calorie-share percentages for carbs/fat/protein (4/9/4 kcal per gram)
/// that always sum to exactly 100: round each, then push the rounding
/// remainder onto whichever macro contributes the most calories.
({int carb, int fat, int protein}) kcalPercents({
  required double carbsG,
  required double fatG,
  required double proteinG,
}) {
  final carbKcal = carbsG * 4;
  final fatKcal = fatG * 9;
  final proteinKcal = proteinG * 4;
  final total = carbKcal + fatKcal + proteinKcal;
  if (total <= 0) return (carb: 0, fat: 0, protein: 0);

  var carb = (carbKcal / total * 100).round();
  var fat = (fatKcal / total * 100).round();
  var protein = (proteinKcal / total * 100).round();
  final diff = 100 - (carb + fat + protein);
  if (diff != 0) {
    if (carbKcal >= fatKcal && carbKcal >= proteinKcal) {
      carb += diff;
    } else if (fatKcal >= carbKcal && fatKcal >= proteinKcal) {
      fat += diff;
    } else {
      protein += diff;
    }
  }
  return (carb: carb, fat: fat, protein: protein);
}
