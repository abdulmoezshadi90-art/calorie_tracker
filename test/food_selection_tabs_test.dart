import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/food_history_tab.dart';
import 'package:calorie_tracker/models.dart';
import 'package:calorie_tracker/saved_meals_tab.dart';

Future<AppState> _freshState({String locale = 'en'}) async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState(clock: () => DateTime(2026, 7, 20, 9, 30));
  await state.load();
  state.localeCode = locale;
  return state;
}

/// Pumps [tab] (HistoryTab or MyMealsTab) alone, wrapped exactly like it
/// would be inside search_screen.dart's Scaffold, without needing the full
/// app shell — a focused widget test target, same spirit as the food
/// detail / settings tests pumping one screen directly.
Future<void> _pumpTab(
  WidgetTester tester,
  AppState state,
  Widget tab, {
  TextDirection direction = TextDirection.ltr,
  Size size = const Size(375, 812),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: AppScope(
        state: state,
        child: Directionality(
          textDirection: direction,
          child: Scaffold(body: tab),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('history aggregation', () {
    test(
      'logCount, lastLoggedAt and lastServings from seeded day logs',
      () async {
        final state = await _freshState();

        await state.addEntry(
          DateTime(2026, 7, 18),
          'sample_snack_1',
          1,
          MealType.snack,
        );
        await state.addEntry(
          DateTime(2026, 7, 19),
          'sample_snack_1',
          2,
          MealType.breakfast,
        );
        // Same (most recent) day, a later entry — should win for
        // lastServings, per AppState.historyEntries' own documented rule.
        await state.addEntry(
          DateTime(2026, 7, 19),
          'sample_snack_1',
          3,
          MealType.breakfast,
        );
        await state.addEntry(
          DateTime(2026, 7, 18),
          'sample_snack_2',
          1,
          MealType.lunch,
        );

        final history = state.historyEntries;
        final snack1 = history.firstWhere((e) => e.food.id == 'sample_snack_1');
        expect(snack1.logCount, 3);
        expect(snack1.lastLoggedAt, DateTime(2026, 7, 19));
        expect(snack1.lastServings, 3);
        expect(snack1.mealTypes, {MealType.snack, MealType.breakfast});

        final snack2 = history.firstWhere((e) => e.food.id == 'sample_snack_2');
        expect(snack2.logCount, 1);
        expect(snack2.lastLoggedAt, DateTime(2026, 7, 18));
        expect(snack2.lastServings, 1);
      },
    );

    test('cache invalidates on add/remove/restore, not just add', () async {
      final state = await _freshState();
      expect(state.historyEntries, isEmpty);

      await state.addEntry(
        DateTime(2026, 7, 18),
        'sample_snack_1',
        1,
        MealType.snack,
      );
      expect(state.historyEntries, hasLength(1));

      final entry = state.entriesFor(DateTime(2026, 7, 18)).single;
      final removed = await state.removeEntry(DateTime(2026, 7, 18), entry.id);
      expect(state.historyEntries, isEmpty);

      await state.restoreEntry(
        DateTime(2026, 7, 18),
        removed!.entry,
        removed.index,
      );
      expect(state.historyEntries, hasLength(1));
    });
  });

  group('History tab sort options', () {
    Future<AppState> seedForSort() async {
      final state = await _freshState();
      // A: logged once, most recently.
      await state.addEntry(
        DateTime(2026, 7, 18),
        'sample_snack_1',
        1,
        MealType.lunch,
      );
      // B: logged three times, least recently (oldest "most recent" day).
      await state.addEntry(
        DateTime(2026, 7, 5),
        'sample_snack_2',
        1,
        MealType.lunch,
      );
      await state.addEntry(
        DateTime(2026, 7, 7),
        'sample_snack_2',
        1,
        MealType.lunch,
      );
      await state.addEntry(
        DateTime(2026, 7, 10),
        'sample_snack_2',
        1,
        MealType.lunch,
      );
      // C: logged twice, middle recency.
      await state.addEntry(
        DateTime(2026, 7, 12),
        'sample_snack_3',
        1,
        MealType.lunch,
      );
      await state.addEntry(
        DateTime(2026, 7, 14),
        'sample_snack_3',
        1,
        MealType.lunch,
      );
      return state;
    }

    double yOf(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    testWidgets('Most recent orders A, C, B', (tester) async {
      final state = await seedForSort();
      await _pumpTab(tester, state, const HistoryTab(meal: MealType.lunch));
      await state.setHistorySort(SortOption.mostRecent);
      await tester.pumpAndSettle();

      final a = yOf(tester, 'Sample Snack A');
      final c = yOf(tester, 'Sample Snack C');
      final b = yOf(tester, 'Sample Snack B');
      expect(a, lessThan(c));
      expect(c, lessThan(b));
    });

    testWidgets('Most frequent orders B, C, A', (tester) async {
      final state = await seedForSort();
      await _pumpTab(tester, state, const HistoryTab(meal: MealType.lunch));
      await state.setHistorySort(SortOption.mostFrequent);
      await tester.pumpAndSettle();

      final b = yOf(tester, 'Sample Snack B');
      final c = yOf(tester, 'Sample Snack C');
      final a = yOf(tester, 'Sample Snack A');
      expect(b, lessThan(c));
      expect(c, lessThan(a));
    });

    testWidgets('A to Z orders A, B, C', (tester) async {
      final state = await seedForSort();
      await _pumpTab(tester, state, const HistoryTab(meal: MealType.lunch));
      await state.setHistorySort(SortOption.aToZ);
      await tester.pumpAndSettle();

      final a = yOf(tester, 'Sample Snack A');
      final b = yOf(tester, 'Sample Snack B');
      final c = yOf(tester, 'Sample Snack C');
      expect(a, lessThan(b));
      expect(b, lessThan(c));
    });

    testWidgets('Z to A orders C, B, A', (tester) async {
      final state = await seedForSort();
      await _pumpTab(tester, state, const HistoryTab(meal: MealType.lunch));
      await state.setHistorySort(SortOption.zToA);
      await tester.pumpAndSettle();

      final c = yOf(tester, 'Sample Snack C');
      final b = yOf(tester, 'Sample Snack B');
      final a = yOf(tester, 'Sample Snack A');
      expect(c, lessThan(b));
      expect(b, lessThan(a));
    });
  });

  group('meal-type filtering', () {
    testWidgets('History tab: a food matches if EVER logged under that meal', (
      tester,
    ) async {
      final state = await _freshState();
      await state.addEntry(
        DateTime(2026, 7, 18),
        'sample_snack_1',
        1,
        MealType.breakfast,
      );
      await state.addEntry(
        DateTime(2026, 7, 18),
        'sample_snack_2',
        1,
        MealType.dinner,
      );

      await _pumpTab(tester, state, const HistoryTab(meal: MealType.lunch));
      await state.setHistoryFilter(MealType.breakfast);
      await tester.pumpAndSettle();

      expect(find.text('Sample Snack A'), findsOneWidget);
      expect(find.text('Sample Snack B'), findsNothing);
    });

    testWidgets('My Meals tab: matches mealType exactly; null only under All', (
      tester,
    ) async {
      final state = await _freshState();
      await state.addSavedMeal(
        SavedMeal(
          id: state.newSavedMealId(),
          name: 'Breakfast Combo',
          mealType: MealType.breakfast,
          items: const [SavedMealItem(foodId: 'sample_snack_1', servings: 1)],
          createdAt: state.now(),
        ),
      );
      await state.addSavedMeal(
        SavedMeal(
          id: state.newSavedMealId(),
          name: 'Untyped Combo',
          mealType: null,
          items: const [SavedMealItem(foodId: 'sample_snack_2', servings: 1)],
          createdAt: state.now(),
        ),
      );

      await _pumpTab(tester, state, const MyMealsTab(meal: MealType.lunch));
      await state.setMealsFilter(MealType.breakfast);
      await tester.pumpAndSettle();

      expect(find.text('Breakfast Combo'), findsOneWidget);
      expect(find.text('Untyped Combo'), findsNothing);

      await state.setMealsFilter(null);
      await tester.pumpAndSettle();
      expect(find.text('Breakfast Combo'), findsOneWidget);
      expect(find.text('Untyped Combo'), findsOneWidget);
    });
  });

  group('saved meal persistence', () {
    test(
      'create, save, reload, delete round trips through shared_preferences',
      () async {
        final state1 = await _freshState();
        final meal = SavedMeal(
          id: state1.newSavedMealId(),
          name: 'My Test Combo',
          mealType: MealType.breakfast,
          items: const [SavedMealItem(foodId: 'sample_snack_1', servings: 2)],
          createdAt: state1.now(),
        );
        expect(await state1.addSavedMeal(meal), isTrue);

        final state2 = AppState(clock: () => DateTime(2026, 7, 20, 9, 30));
        await state2.load();
        expect(state2.savedMeals, hasLength(1));
        final reloaded = state2.savedMeals.single;
        expect(reloaded.name, 'My Test Combo');
        expect(reloaded.mealType, MealType.breakfast);
        expect(reloaded.items.single.foodId, 'sample_snack_1');
        expect(reloaded.items.single.servings, 2);

        expect(await state2.deleteSavedMeal(meal.id), isTrue);

        final state3 = AppState(clock: () => DateTime(2026, 7, 20, 9, 30));
        await state3.load();
        expect(state3.savedMeals, isEmpty);
      },
    );
  });

  group('history quick add', () {
    testWidgets('writes a log entry with the last-used serving amount', (
      tester,
    ) async {
      final state = await _freshState();
      // Last-used serving is 2.5, logged on an earlier day than today.
      await state.addEntry(
        DateTime(2026, 7, 10),
        'sample_snack_1',
        2.5,
        MealType.breakfast,
      );

      await _pumpTab(tester, state, const HistoryTab(meal: MealType.lunch));
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final entries = state.entriesFor(
        state.selectedDate,
        meal: MealType.lunch,
      );
      expect(entries, hasLength(1));
      expect(entries.single.foodId, 'sample_snack_1');
      expect(entries.single.servings, 2.5);
    });
  });

  group('Western digits and overflow', () {
    testWidgets('Western digits render in Arabic locale on both tabs', (
      tester,
    ) async {
      final state = await _freshState(locale: 'ar');
      await state.addEntry(
        DateTime(2026, 7, 18),
        'sample_snack_1',
        2,
        MealType.breakfast,
      );
      await state.addSavedMeal(
        SavedMeal(
          id: state.newSavedMealId(),
          name: 'وجبة تجريبية',
          mealType: null,
          items: const [SavedMealItem(foodId: 'sample_snack_1', servings: 3)],
          createdAt: state.now(),
        ),
      );

      for (final tab in [
        const HistoryTab(meal: MealType.lunch),
        const MyMealsTab(meal: MealType.lunch),
      ]) {
        await _pumpTab(tester, state, tab, direction: TextDirection.rtl);
        for (final digit in const [
          '٠',
          '١',
          '٢',
          '٣',
          '٤',
          '٥',
          '٦',
          '٧',
          '٨',
          '٩',
        ]) {
          expect(find.textContaining(digit), findsNothing);
        }
      }
    });

    testWidgets(
      'no overflow at 375x812, both locales, both tabs, empty and populated',
      (tester) async {
        for (final locale in ['en', 'ar']) {
          final direction = locale == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr;

          // Empty state first (no logs, no saved meals).
          final empty = await _freshState(locale: locale);
          for (final tab in [
            const HistoryTab(meal: MealType.lunch),
            const MyMealsTab(meal: MealType.lunch),
          ]) {
            await _pumpTab(tester, empty, tab, direction: direction);
            expect(tester.takeException(), isNull);
          }

          // Populated state.
          final populated = await _freshState(locale: locale);
          await populated.addEntry(
            DateTime(2026, 7, 18),
            'sample_snack_1',
            2,
            MealType.breakfast,
          );
          await populated.addSavedMeal(
            SavedMeal(
              id: populated.newSavedMealId(),
              name: 'Test Combo',
              mealType: MealType.lunch,
              items: const [
                SavedMealItem(foodId: 'sample_snack_1', servings: 1),
              ],
              createdAt: populated.now(),
            ),
          );
          for (final tab in [
            const HistoryTab(meal: MealType.lunch),
            const MyMealsTab(meal: MealType.lunch),
          ]) {
            await _pumpTab(tester, populated, tab, direction: direction);
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  });
}
