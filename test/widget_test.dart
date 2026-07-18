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
}
