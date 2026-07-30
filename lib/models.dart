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
  /// presets are gram multiples of this.
  final double? servingGrams;

  /// Household portions shown as chips in the add sheet. Empty for foods
  /// not yet populated (top staples first; refined with beta data).
  final List<PortionPreset> presets;

  /// Servings equivalent of [preset], rounded to 2 decimals so displayed
  /// serving counts stay tidy. Requires [servingGrams].
  double servingsFor(PortionPreset preset) =>
      ((preset.grams / servingGrams!) * 100).round() / 100;

  /// Ways to log this food's quantity: its own named serving, plus any
  /// household presets it already defines. NOT a universal gram picker —
  /// each food scales on its own terms (decision: never invent a weight
  /// for foods whose label states none, e.g. "1 cone", "2 eggs").
  List<ServingUnit> get servingUnits => [
    ServingUnit(
      id: 'serving',
      labelEn: servingEn,
      labelAr: servingAr,
      grams: servingGrams,
    ),
    for (final p in presets)
      ServingUnit(id: p.nameEn, labelEn: p.nameEn, labelAr: p.nameAr, grams: p.grams),
  ];

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
  });
}

enum FoodCategory { snack, main, breakfast, sweet, drink }

/// One way to log a food's quantity — the food's OWN serving scale (its
/// named serving, or one of its household presets), never a universal
/// gram unit. [grams] is null when the label carries no weight at all.
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

  const LogEntry({
    required this.id,
    required this.foodId,
    required this.servings,
    required this.meal,
    this.unitId = 'serving',
    double? quantity,
  }) : quantity = quantity ?? servings;

  Map<String, dynamic> toJson() => {
    'id': id,
    'foodId': foodId,
    'servings': servings,
    'meal': meal,
    'unitId': unitId,
    'quantity': quantity,
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
