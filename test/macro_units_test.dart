import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/food_db.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';
import 'package:calorie_tracker/theme.dart';

void main() {
  group('generic unit gating (solid vs liquid)', () {
    test('a solid food never offers ml or fl oz', () {
      final food = foodById['sample_main_1']!; // solid, has servingGrams
      expect(food.isLiquid, isFalse);
      final ids = food.genericUnits.map((u) => u.id).toList();
      expect(ids, contains('generic_gram'));
      expect(ids, contains('generic_kilogram'));
      expect(ids, contains('generic_ounce'));
      expect(ids, contains('generic_pound'));
      expect(ids, isNot(contains('generic_milliliter')));
      expect(ids, isNot(contains('generic_fluidOunce')));
      expect(ids, isNot(contains('generic_cup')));
    });

    test('a liquid food never offers oz or lb', () {
      final food = foodById['milk_hawaa_full_cream']!;
      expect(food.isLiquid, isTrue);
      final ids = food.genericUnits.map((u) => u.id).toList();
      expect(ids, contains('generic_milliliter'));
      expect(ids, contains('generic_liter'));
      expect(ids, contains('generic_cup'));
      expect(ids, contains('generic_tablespoon'));
      expect(ids, isNot(contains('generic_ounce')));
      expect(ids, isNot(contains('generic_pound')));
      expect(ids, isNot(contains('generic_gram')));
      expect(ids, isNot(contains('generic_kilogram')));
    });

    test('a food without servingGrams offers no generic units at all', () {
      final food = foodById['sample_snack_1']!;
      expect(food.servingGrams, isNull);
      expect(food.genericUnits, isEmpty);
    });

    test('liquid density converts ml to grams for the macro math', () {
      final food =
          foodById['milk_hawaa_full_cream']!; // 250 ml -> 250 g, density 1.0
      final literUnit = food.genericUnits.firstWhere(
        (u) => u.id == 'generic_liter',
      );
      expect(literUnit.grams, 1000); // 1 l * 1.0 g/ml
    });
  });

  group('kcalPercents', () {
    test('sums to exactly 100 for a typical food', () {
      final pct = kcalPercents(carbsG: 75, fatG: 15, proteinG: 25);
      expect(pct.carb + pct.fat + pct.protein, 100);
    });

    test('sums to exactly 100 for a zero-fat food', () {
      final pct = kcalPercents(carbsG: 40, fatG: 0, proteinG: 20);
      expect(pct.fat, 0);
      expect(pct.carb + pct.fat + pct.protein, 100);
    });

    test('handles the zero-calorie case without dividing by zero', () {
      final pct = kcalPercents(carbsG: 0, fatG: 0, proteinG: 0);
      expect(pct, (carb: 0, fat: 0, protein: 0));
    });

    test('sums to exactly 100 across several real foods', () {
      for (final food in [
        foodById['sample_main_1']!,
        foodById['sample_breakfast_4']!, // zero fat, zero protein
        foodById['milk_hawaa_full_cream']!,
      ]) {
        final pct = kcalPercents(
          carbsG: food.carbs,
          fatG: food.fat,
          proteinG: food.protein,
        );
        expect(pct.carb + pct.fat + pct.protein, 100, reason: food.id);
      }
    });
  });

  group('macro colors', () {
    Future<void> pumpDetail(WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'onboarding_done': true});
      final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
      await state.load();
      await tester.pumpWidget(CalorieApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lunch').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'sample main dish a');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample Main Dish A'));
      await tester.pumpAndSettle();
    }

    testWidgets('each macro renders with its named-constant color', (
      tester,
    ) async {
      await pumpDetail(tester);
      final c = AppColors.light;
      expect(c.carb, const Color(0xFFF59E0B));
      expect(c.fat, const Color(0xFF8B5CF6));
      expect(c.protein, const Color(0xFFEF4444));

      Color colorOf(String text) =>
          (tester.widget<Text>(find.text(text)).style!.color)!;

      // Sample Main Dish A: 75c/15f/25p per serving — macro chip gram
      // figures use the macro color directly.
      expect(colorOf('75g'), c.carb);
      expect(colorOf('15g'), c.fat);
      expect(colorOf('25g'), c.protein);
    });
  });

  group('legacy log entries', () {
    test('missing unitId/quantity fall back to the food default unit', () {
      // Shape written before serving units existed.
      final json = {
        'id': 'old_1',
        'foodId': 'sample_main_1',
        'servings': 1.0,
        'meal': 'lunch',
      };
      final entry = LogEntry.fromJson(json);
      expect(entry.unitId, 'serving');
      expect(entry.quantity, 1.0);
      expect(entry.loggedAt, isNull);
    });

    test('a legacy day log decodes through AppState.load', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_done': true,
        'logs_v1':
            '{"2026-07-15":[{"id":"old_1","foodId":"sample_main_1",'
            '"servings":1.0,"meal":"lunch"}]}',
      });
      final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
      await state.load();
      final entry = state.entriesFor(DateTime(2026, 7, 15)).single;
      expect(entry.unitId, 'serving');
      expect(entry.quantity, 1.0);
      expect(state.totalsFor(DateTime(2026, 7, 15)).kcal, 540);
    });
  });

  group('loggedAt', () {
    test('round-trips through JSON', () {
      final entry = LogEntry(
        id: '1',
        foodId: 'sample_main_1',
        servings: 1,
        meal: 'lunch',
        loggedAt: DateTime(2026, 7, 15, 9, 30),
      );
      final decoded = LogEntry.fromJson(entry.toJson());
      expect(decoded.loggedAt, DateTime(2026, 7, 15, 9, 30));
    });
  });
}
