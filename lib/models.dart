import 'package:flutter/material.dart';

/// A food item in the local database. Nutrition values are per one serving.
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
  });
}

enum FoodCategory { snack, main, breakfast, sweet, drink }

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
  );
}

/// One logged food, tied to a meal on a given day.
class LogEntry {
  final String id;
  final String foodId;
  final double servings;
  final String meal; // MealType.name

  const LogEntry({
    required this.id,
    required this.foodId,
    required this.servings,
    required this.meal,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'foodId': foodId,
    'servings': servings,
    'meal': meal,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    id: json['id'] as String,
    foodId: json['foodId'] as String,
    servings: (json['servings'] as num).toDouble(),
    meal: json['meal'] as String,
  );
}

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
