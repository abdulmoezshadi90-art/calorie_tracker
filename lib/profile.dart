import 'models.dart';

/// Local profile with maintenance calculation (design decision 8).
///
/// NOT an account: no login, no sign up, nothing transmitted. Answers live
/// in shared_preferences like everything else. The name feeds the home
/// greeting only.

enum Sex { male, female }

enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  high(1.725),
  athlete(1.9);

  const ActivityLevel(this.multiplier);
  final double multiplier;
}

enum WeightGoal {
  lose(-500),
  loseGently(-250),
  maintain(0),
  gain(300);

  const WeightGoal(this.kcalAdjustment);
  final int kcalAdjustment;
}

/// Validation ranges for the profile inputs (decision 8).
const profileRanges = (
  age: (min: 13, max: 100),
  weight: (min: 30, max: 250),
  height: (min: 120, max: 230),
);

class Profile {
  final String name; // greeting only, stored locally, never transmitted
  final Sex sex;
  final int age;
  // Weight and height accept decimals (81.5 kg); age stays integer-only.
  final double weightKg;
  final double heightCm;
  final ActivityLevel activity;
  final WeightGoal goal;

  const Profile({
    required this.name,
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.activity,
    required this.goal,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'sex': sex.name,
    'age': age,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'activity': activity.name,
    'goal': goal.name,
  };

  static int _intOr(Object? v, int fallback) =>
      v is num ? v.round() : fallback;
  static double _doubleOr(Object? v, double fallback) =>
      v is num ? v.toDouble() : fallback;

  /// Null tolerant like Goals.fromJson: malformed fields fall back to
  /// harmless defaults so older saves keep loading as fields are added.
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    name: json['name'] is String ? json['name'] as String : '',
    sex: Sex.values.asNameMap()[json['sex']] ?? Sex.male,
    age: _intOr(json['age'], 30),
    weightKg: _doubleOr(json['weightKg'], 70),
    heightCm: _doubleOr(json['heightCm'], 170),
    activity:
        ActivityLevel.values.asNameMap()[json['activity']] ??
        ActivityLevel.moderate,
    goal: WeightGoal.values.asNameMap()[json['goal']] ?? WeightGoal.maintain,
  );
}

class MaintenanceResult {
  /// Maintenance (BMR × activity), rounded to the nearest 50 for display.
  final int maintenanceKcal;

  /// Final daily goal: maintenance + adjustment, rounded to the nearest 50,
  /// clamped so it never lands below the goal floors.
  final Goals goals;

  /// True when the deficit was clamped at the floors.
  final bool clamped;

  /// True when age < 18: maintenance only, no deficit (decision 8).
  final bool maintenanceOnly;

  const MaintenanceResult({
    required this.maintenanceKcal,
    required this.goals,
    required this.clamped,
    required this.maintenanceOnly,
  });
}

int _roundTo50(double v) => (v / 50).round() * 50;

/// Mifflin St Jeor with the exact multipliers, adjustments, rounding and
/// clamps from design decision 8. Pure function so tests pin the math.
MaintenanceResult calculateMaintenance(Profile p) {
  final bmr =
      10 * p.weightKg +
      6.25 * p.heightCm -
      5 * p.age +
      (p.sex == Sex.male ? 5 : -161);
  final maintenance = bmr * p.activity.multiplier;

  final maintenanceOnly = p.age < 18;
  final adjustment = maintenanceOnly ? 0 : p.goal.kcalAdjustment;

  var kcal = _roundTo50(maintenance + adjustment);
  var clamped = false;
  if (kcal < goalFloors.kcal) {
    kcal = goalFloors.kcal;
    clamped = true;
  }

  // Macros from the final kcal: protein 25%, fat 30%, carbs 45% at 4/9/4
  // kcal per gram, whole grams. At kcal >= the floor these sit above the
  // macro floors by construction; the max() keeps that guarantee explicit.
  final protein = (kcal * 0.25 / 4).round();
  final fat = (kcal * 0.30 / 9).round();
  final carbs = (kcal * 0.45 / 4).round();

  return MaintenanceResult(
    maintenanceKcal: _roundTo50(maintenance),
    goals: Goals(
      kcal: kcal,
      carbs: carbs < goalFloors.carbs ? goalFloors.carbs : carbs,
      fat: fat < goalFloors.fat ? goalFloors.fat : fat,
      protein: protein < goalFloors.protein ? goalFloors.protein : protein,
    ),
    clamped: clamped,
    maintenanceOnly: maintenanceOnly,
  );
}
