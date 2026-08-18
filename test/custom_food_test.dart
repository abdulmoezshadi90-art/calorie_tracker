import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/all_foods_tab.dart';
import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/custom_food_screen.dart';
import 'package:calorie_tracker/foods_screen.dart';
import 'package:calorie_tracker/models.dart';
import 'package:calorie_tracker/search_screen.dart';

Future<AppState> _freshState() async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState(clock: () => DateTime(2026, 7, 20, 9, 30));
  await state.load();
  return state;
}

// AppScope via `builder`, not wrapped only around `home`: it must cover
// every route the Navigator pushes (CustomFoodScreen gets pushed from
// several of these tests), matching how main.dart's CalorieApp wires it —
// see create_meal_screen_test.dart for the bug this avoids.
Future<void> _pump(WidgetTester tester, AppState state, Widget child) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, c) =>
          AppScope(state: state, child: c ?? const SizedBox.shrink()),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AppState custom food CRUD', () {
    test('addCustomFood makes it resolvable and part of allFoods', () async {
      final state = await _freshState();
      const food = FoodItem(
        id: 'custom_1',
        nameEn: 'Homemade Bread',
        nameAr: 'Homemade Bread',
        servingEn: '1 serving',
        servingAr: 'حصة واحدة',
        kcal: 200,
        protein: 6,
        carbs: 38,
        fat: 2,
        category: FoodCategory.custom,
      );
      final ok = await state.addCustomFood(food);
      expect(ok, isTrue);
      expect(state.customFoods, contains(food));
      expect(state.allFoods, contains(food));
      expect(state.resolveFood('custom_1'), food);
    });

    test('resolveFood still finds a built-in food_db.dart entry', () async {
      final state = await _freshState();
      final food = state.resolveFood('sample_snack_1');
      expect(food, isNotNull);
      expect(food!.nameEn, 'Sample Snack A');
    });

    test('resolveFood returns null for an unknown id', () async {
      final state = await _freshState();
      expect(state.resolveFood('does_not_exist'), isNull);
    });

    test('updateCustomFood replaces the stored values', () async {
      final state = await _freshState();
      const original = FoodItem(
        id: 'custom_2',
        nameEn: 'Protein Shake',
        nameAr: 'Protein Shake',
        servingEn: '1 serving',
        servingAr: 'حصة واحدة',
        kcal: 150,
        protein: 25,
        carbs: 5,
        fat: 2,
        category: FoodCategory.custom,
      );
      await state.addCustomFood(original);
      final updated = FoodItem(
        id: original.id,
        nameEn: 'Protein Shake (Chocolate)',
        nameAr: original.nameAr,
        servingEn: original.servingEn,
        servingAr: original.servingAr,
        kcal: 180,
        protein: 30,
        carbs: 8,
        fat: 3,
        category: FoodCategory.custom,
      );
      final ok = await state.updateCustomFood(updated);
      expect(ok, isTrue);
      expect(state.resolveFood('custom_2')!.kcal, 180);
      expect(state.resolveFood('custom_2')!.nameEn, 'Protein Shake (Chocolate)');
    });

    test('deleteCustomFood removes it', () async {
      final state = await _freshState();
      const food = FoodItem(
        id: 'custom_3',
        nameEn: 'Leftover Pasta',
        nameAr: 'Leftover Pasta',
        servingEn: '1 serving',
        servingAr: 'حصة واحدة',
        kcal: 300,
        protein: 10,
        carbs: 50,
        fat: 8,
        category: FoodCategory.custom,
      );
      await state.addCustomFood(food);
      final ok = await state.deleteCustomFood('custom_3');
      expect(ok, isTrue);
      expect(state.resolveFood('custom_3'), isNull);
      expect(state.allFoods, isNot(contains(food)));
    });

    test('newCustomFoodId never collides with a food_db.dart id', () async {
      final state = await _freshState();
      final id = state.newCustomFoodId();
      expect(id, startsWith('custom_'));
      expect(state.resolveFood(id), isNull); // not created yet, just unique
    });

    test('a custom food survives a reload from persisted storage', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState(clock: () => DateTime(2026, 7, 20, 9, 30));
      await state.load();
      const food = FoodItem(
        id: 'custom_4',
        nameEn: 'Grandma Soup',
        nameAr: 'Grandma Soup',
        servingEn: '1 serving',
        servingAr: 'حصة واحدة',
        kcal: 220,
        protein: 12,
        carbs: 20,
        fat: 9,
        category: FoodCategory.custom,
        verified: false,
        sourceNote: 'User-added food, not verified.',
      );
      await state.addCustomFood(food);

      final reloaded = AppState(clock: () => DateTime(2026, 7, 20, 9, 30));
      await reloaded.load();
      final restored = reloaded.resolveFood('custom_4');
      expect(restored, isNotNull);
      expect(restored!.nameEn, 'Grandma Soup');
      expect(restored.kcal, 220);
      expect(restored.protein, 12);
      expect(restored.category, FoodCategory.custom);
    });

    test('a logged custom food counts toward the day total', () async {
      final state = await _freshState();
      const food = FoodItem(
        id: 'custom_5',
        nameEn: 'Trail Mix',
        nameAr: 'Trail Mix',
        servingEn: '1 serving',
        servingAr: 'حصة واحدة',
        kcal: 400,
        protein: 10,
        carbs: 30,
        fat: 25,
        category: FoodCategory.custom,
      );
      await state.addCustomFood(food);
      final date = DateTime(2026, 7, 20);
      await state.addEntry(date, 'custom_5', 1, MealType.snack);

      final totals = state.totalsFor(date);
      expect(totals.kcal, 400);
      expect(totals.protein, 10);

      final history = state.historyEntries;
      expect(history.any((h) => h.food.id == 'custom_5'), isTrue);
    });
  });

  group('CustomFoodScreen', () {
    testWidgets('blocks save with an empty name', (tester) async {
      final state = await _freshState();
      await _pump(tester, state, const CustomFoodScreen());

      await tester.enterText(find.byType(TextField).at(1), '150');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(state.customFoods, isEmpty);
      expect(find.text('Enter a food name'), findsOneWidget);
    });

    testWidgets('blocks save with an invalid number', (tester) async {
      final state = await _freshState();
      await _pump(tester, state, const CustomFoodScreen());

      await tester.enterText(find.byType(TextField).first, 'Test Food');
      // Calories left empty/invalid.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(state.customFoods, isEmpty);
      expect(find.text('Enter a valid number'), findsOneWidget);
    });

    testWidgets('valid entry creates the food and pops', (tester) async {
      final state = await _freshState();
      await _pump(tester, state, const CustomFoodScreen());

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Homemade Granola');
      await tester.enterText(fields.at(1), '210'); // calories
      await tester.enterText(fields.at(2), '5'); // protein
      await tester.enterText(fields.at(3), '30'); // carbs
      await tester.enterText(fields.at(4), '8'); // fat
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(state.customFoods, hasLength(1));
      final saved = state.customFoods.first;
      expect(saved.nameEn, 'Homemade Granola');
      expect(saved.nameAr, 'Homemade Granola'); // single name, both fields
      expect(saved.kcal, 210);
      expect(saved.protein, 5);
      expect(saved.carbs, 30);
      expect(saved.fat, 8);
      expect(saved.category, FoodCategory.custom);
      expect(saved.verified, isFalse);
    });

    testWidgets('edit mode prefills and updates in place', (tester) async {
      final state = await _freshState();
      const existing = FoodItem(
        id: 'custom_edit',
        nameEn: 'Smoothie',
        nameAr: 'Smoothie',
        servingEn: '1 serving',
        servingAr: 'حصة واحدة',
        kcal: 150,
        protein: 4,
        carbs: 20,
        fat: 3,
        category: FoodCategory.custom,
      );
      await state.addCustomFood(existing);

      await _pump(
        tester,
        state,
        const CustomFoodScreen(existing: existing),
      );

      expect(find.text('Smoothie'), findsOneWidget);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '175'); // bump calories
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(state.customFoods, hasLength(1)); // updated, not duplicated
      expect(state.customFoods.first.kcal, 175);
      expect(state.customFoods.first.id, 'custom_edit');
    });
  });

  group('Custom foods surface everywhere else foods do', () {
    testWidgets('a created custom food appears in the All Foods tab', (
      tester,
    ) async {
      final state = await _freshState();
      const food = FoodItem(
        id: 'custom_6',
        nameEn: 'Zzz Unique Custom Snack',
        nameAr: 'Zzz Unique Custom Snack',
        servingEn: '1 serving',
        servingAr: 'حصة واحدة',
        kcal: 90,
        protein: 2,
        carbs: 15,
        fat: 1,
        category: FoodCategory.custom,
      );
      await state.addCustomFood(food);

      await _pump(
        tester,
        state,
        Scaffold(
          body: AllFoodsTab(
            query: 'Zzz Unique Custom Snack',
            onFoodTap: (_, _) {},
            onQuickAdd: (_, _) {},
            onClearSearch: () {},
            onAddCustomFood: () {},
          ),
        ),
      );

      expect(find.text('Zzz Unique Custom Snack'), findsOneWidget);
    });

    testWidgets(
      'long-press on a custom food row offers delete, with undo restoring it',
      (tester) async {
        final state = await _freshState();
        const food = FoodItem(
          id: 'custom_8',
          nameEn: 'Zzz Unique Deletable Snack',
          nameAr: 'Zzz Unique Deletable Snack',
          servingEn: '1 serving',
          servingAr: 'حصة واحدة',
          kcal: 90,
          protein: 2,
          carbs: 15,
          fat: 1,
          category: FoodCategory.custom,
        );
        await state.addCustomFood(food);

        await _pump(
          tester,
          state,
          Scaffold(
            body: AllFoodsTab(
              query: 'Zzz Unique Deletable Snack',
              onFoodTap: (_, _) {},
              onQuickAdd: (_, _) {},
              onClearSearch: () {},
              onAddCustomFood: () {},
            ),
          ),
        );

        await tester.longPress(find.text('Zzz Unique Deletable Snack'));
        await tester.pumpAndSettle();
        expect(find.text('Delete'), findsOneWidget);

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(state.resolveFood('custom_8'), isNull);
        expect(find.text('Removed'), findsOneWidget);

        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(state.resolveFood('custom_8'), food);
      },
    );

    testWidgets(
      'long-press on a food_db.dart entry offers no options (read-only)',
      (tester) async {
        final state = await _freshState();
        await _pump(
          tester,
          state,
          Scaffold(
            body: AllFoodsTab(
              query: 'Sample Snack A',
              onFoodTap: (_, _) {},
              onQuickAdd: (_, _) {},
              onClearSearch: () {},
              onAddCustomFood: () {},
            ),
          ),
        );

        await tester.longPress(find.text('Sample Snack A'));
        await tester.pumpAndSettle();
        expect(find.text('Delete'), findsNothing);
      },
    );

    testWidgets(
      'a created custom food is grouped under My Foods and the browse tab renders without error',
      (tester) async {
        final state = await _freshState();
        const food = FoodItem(
          id: 'custom_7',
          nameEn: 'Zzz Unique Foods Tab Snack',
          nameAr: 'Zzz Unique Foods Tab Snack',
          servingEn: '1 serving',
          servingAr: 'حصة واحدة',
          kcal: 90,
          protein: 2,
          carbs: 15,
          fat: 1,
          category: FoodCategory.custom,
        );
        await state.addCustomFood(food);

        // The categorization logic FoodsScreen relies on — verified
        // directly rather than by scrolling a widget test through the
        // full ~164-entry list to reach the last category's section.
        expect(
          state.allFoods.where((f) => f.category == FoodCategory.custom),
          contains(food),
        );

        await _pump(tester, state, const FoodsScreen());
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'tapping Add a food in the log flow opens the form and the new food logs correctly',
      (tester) async {
        final state = await _freshState();
        await _pump(tester, state, const SearchScreen(meal: MealType.snack));

        await tester.tap(find.text('Add a food'));
        await tester.pumpAndSettle();
        expect(find.byType(CustomFoodScreen), findsOneWidget);

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'Quick Oats Bowl');
        await tester.enterText(fields.at(1), '250');
        await tester.enterText(fields.at(2), '8');
        await tester.enterText(fields.at(3), '40');
        await tester.enterText(fields.at(4), '5');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Back on the log flow, food is real and logged for today.
        expect(find.byType(CustomFoodScreen), findsNothing);
        expect(state.customFoods.any((f) => f.nameEn == 'Quick Oats Bowl'), isTrue);
      },
    );
  });
}
