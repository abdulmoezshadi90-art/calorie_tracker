import 'package:flutter_test/flutter_test.dart';

import 'package:calorie_tracker/food_db.dart';
import 'package:calorie_tracker/models.dart';

void main() {
  test('fmtInt adds thousands separators with Western digits', () {
    expect(fmtInt(0), '0');
    expect(fmtInt(680), '680');
    expect(fmtInt(1320), '1,320');
    expect(fmtInt(12345678), '12,345,678');
  });

  test('fmtGrams rounds sensibly', () {
    expect(fmtGrams(140), '140');
    expect(fmtGrams(6.5), '6.5');
    expect(fmtGrams(13.5), '14');
  });

  test('every food carries a sourceNote (data pipeline, issue #12)', () {
    // Early form of the pre-launch gate: zero foods ship without a source.
    for (final f in foodDatabase) {
      expect(f.sourceNote, isNotEmpty, reason: f.id);
    }
    // Nothing is verified until it passes the Phase 2 label pipeline.
    expect(foodDatabase.where((f) => f.verified), isEmpty);
  });

  test('fmtServings drops trailing .0', () {
    expect(fmtServings(1.0), '1');
    expect(fmtServings(1.5), '1.5');
  });

  test('kcalPercents always sums to 100, including a zero-fat food', () {
    final mixed = kcalPercents(carbsG: 75, fatG: 15, proteinG: 25);
    expect(mixed.carb + mixed.fat + mixed.protein, 100);

    // Zero protein and zero fat — an all-carb edge case.
    final zeroFatFood = foodById['sample_breakfast_4']!;
    final zeroFat = kcalPercents(
      carbsG: zeroFatFood.carbs,
      fatG: zeroFatFood.fat,
      proteinG: zeroFatFood.protein,
    );
    expect(zeroFat.fat, 0);
    expect(zeroFat.protein, 0);
    expect(zeroFat.carb, 100);

    for (final f in foodDatabase) {
      final pct = kcalPercents(carbsG: f.carbs, fatG: f.fat, proteinG: f.protein);
      final totalKcal = f.carbs * 4 + f.fat * 9 + f.protein * 4;
      final expectedSum = totalKcal <= 0 ? 0 : 100;
      expect(pct.carb + pct.fat + pct.protein, expectedSum, reason: f.id);
    }
  });

  test('legacy LogEntry JSON without unitId/quantity still decodes', () {
    final json = {
      'id': 'x1',
      'foodId': 'sample_main_1',
      'servings': 1.5,
      'meal': 'lunch',
    };
    final entry = LogEntry.fromJson(json);
    expect(entry.unitId, 'serving');
    expect(entry.quantity, 1.5);
    expect(entry.servings, 1.5);
  });
}
