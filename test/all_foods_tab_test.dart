import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/all_foods_tab.dart';
import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/create_meal_screen.dart';
import 'package:calorie_tracker/food_db.dart';
import 'package:calorie_tracker/food_picker.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

Future<AppState> _freshState({String locale = 'en'}) async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState(clock: () => DateTime(2026, 7, 20, 9, 30));
  await state.load();
  state.localeCode = locale;
  return state;
}

Future<void> _pump(
  WidgetTester tester,
  AppState state,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: AppScope(
        state: state,
        child: Directionality(
          textDirection: direction,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AllFoodsTab _allFoodsTab({
  String query = '',
  void Function(FoodItem, double)? onFoodTap,
  void Function(FoodItem, double)? onQuickAdd,
  VoidCallback? onClearSearch,
}) => AllFoodsTab(
  query: query,
  onFoodTap: onFoodTap ?? (_, _) {},
  onQuickAdd: onQuickAdd ?? (_, _) {},
  onClearSearch: onClearSearch ?? () {},
);

void main() {
  group('All Foods tab — fresh install', () {
    testWidgets('renders every food with no Previously logged header', (
      tester,
    ) async {
      final state = await _freshState();
      await _pump(tester, state, _allFoodsTab());

      expect(find.text('Previously logged'), findsNothing);
      expect(find.text('All foods'), findsNothing); // no header when alone
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('food_picker.dart defaults to the All Foods tab', (
      tester,
    ) async {
      final state = await _freshState();
      await _pump(
        tester,
        state,
        FoodPicker(
          onFoodTap: (_, _) {},
          onFoodQuickAdd: (_, _) {},
          onMealTap: (_) {},
          onMealQuickAdd: (_) {},
        ),
      );

      // Food rows are visible immediately, with no query typed — only
      // possible if we opened on All Foods, since History/My Meals both
      // start empty for a first-time user.
      expect(find.byType(ListTile), findsWidgets);
      expect(find.text('Your logged foods will appear here'), findsNothing);
    });
  });

  group('All Foods tab — previously logged split', () {
    testWidgets('logged foods appear above the rest, each exactly once', (
      tester,
    ) async {
      final state = await _freshState();
      await state.addEntry(
        DateTime(2026, 7, 18),
        'sample_snack_1',
        1,
        MealType.snack,
      );

      await _pump(tester, state, _allFoodsTab());

      expect(find.text('Previously logged'), findsOneWidget);
      expect(find.text('All foods'), findsOneWidget);
      // The logged food shows once, under "Previously logged" — never
      // duplicated into the "All foods" section too.
      expect(find.text('Sample Snack A'), findsOneWidget);

      final headerY = tester.getTopLeft(find.text('Previously logged')).dy;
      final foodY = tester.getTopLeft(find.text('Sample Snack A')).dy;
      final allFoodsHeaderY = tester.getTopLeft(find.text('All foods')).dy;
      expect(headerY, lessThan(foodY));
      expect(foodY, lessThan(allFoodsHeaderY));
    });
  });

  group('All Foods tab — sort order', () {
    testWidgets('sorts A to Z by English name', (tester) async {
      final state = await _freshState();
      await _pump(tester, state, _allFoodsTab());

      final expected = [...foodDatabase]
        ..sort((a, b) => a.nameEn.compareTo(b.nameEn));
      final first = expected[0].nameEn;
      final second = expected[1].nameEn;

      final firstY = tester.getTopLeft(find.text(first)).dy;
      final secondY = tester.getTopLeft(find.text(second)).dy;
      expect(firstY, lessThan(secondY));
    });

    testWidgets('sorts A to Z by Arabic name in Arabic locale', (
      tester,
    ) async {
      final state = await _freshState(locale: 'ar');
      await _pump(tester, state, _allFoodsTab(), direction: TextDirection.rtl);

      final expected = [...foodDatabase]
        ..sort((a, b) => a.nameAr.compareTo(b.nameAr));
      final first = expected[0].nameAr;
      final second = expected[1].nameAr;

      final firstY = tester.getTopLeft(find.text(first)).dy;
      final secondY = tester.getTopLeft(find.text(second)).dy;
      expect(firstY, lessThan(secondY));
    });
  });

  group('search auto-switches to All Foods and filters live', () {
    testWidgets('typing from History switches tabs and filters', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'food_tab_index_v2': 1});
      final state = AppState(clock: () => DateTime(2026, 7, 20, 9, 30));
      await state.load();
      await state.addEntry(
        DateTime(2026, 7, 18),
        'sample_snack_1',
        1,
        MealType.snack,
      );

      await _pump(
        tester,
        state,
        FoodPicker(
          onFoodTap: (_, _) {},
          onFoodQuickAdd: (_, _) {},
          onMealTap: (_) {},
          onMealQuickAdd: (_) {},
        ),
      );
      // Confirms History is indeed the opening tab here (logs exist).
      expect(find.text('Recently logged'), findsOneWidget);

      // Query text deliberately differs from the expected row's full name
      // so find.text can't ambiguously match the TextField's own value too.
      await tester.enterText(find.byType(TextField), 'Snack B');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Recently logged'), findsNothing);
      expect(find.text('Sample Snack B'), findsOneWidget);
      expect(find.text('Sample Snack A'), findsNothing);
    });

    testWidgets('clearing the query keeps the current tab', (tester) async {
      SharedPreferences.setMockInitialValues({'food_tab_index_v2': 1});
      final state = AppState(clock: () => DateTime(2026, 7, 20, 9, 30));
      await state.load();
      await state.addEntry(
        DateTime(2026, 7, 18),
        'sample_snack_1',
        1,
        MealType.snack,
      );

      await _pump(
        tester,
        state,
        FoodPicker(
          onFoodTap: (_, _) {},
          onFoodQuickAdd: (_, _) {},
          onMealTap: (_) {},
          onMealQuickAdd: (_) {},
        ),
      );
      await tester.enterText(find.byType(TextField), 'zzzzznomatch');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Recently logged'), findsNothing); // now on All Foods

      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      // Stayed on All Foods (not jumped back to History) — its full
      // unfiltered list is showing again.
      expect(find.text('Recently logged'), findsNothing);
      expect(find.byType(ListTile), findsWidgets);
    });
  });

  group('cross-locale search matching', () {
    testWidgets('Arabic locale matches an English substring', (
      tester,
    ) async {
      final state = await _freshState(locale: 'ar');
      await _pump(
        tester,
        state,
        _allFoodsTab(query: 'Sample Snack A'),
        direction: TextDirection.rtl,
      );
      expect(find.text('وجبة خفيفة تجريبية أ'), findsOneWidget);
    });

    testWidgets('English locale matches an Arabic substring', (
      tester,
    ) async {
      final state = await _freshState();
      await _pump(tester, state, _allFoodsTab(query: 'تجريبية'));
      expect(find.text('Sample Snack A'), findsOneWidget);
    });
  });

  group('callback wiring at both call sites', () {
    testWidgets('log flow: tapping quick-add on an All Foods row logs it', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_done': true});
      final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
      await state.load();
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(CalorieApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('nav-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lunch').last);
      await tester.pumpAndSettle();

      // Narrow to a single match first — sample_snack_1 sorts well past
      // page one among 164 real foods, so it isn't built without this.
      await tester.enterText(find.byType(TextField), 'Sample Snack A');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('quick-add-sample_snack_1')),
      );
      await tester.pumpAndSettle();

      final entries = state.entriesFor(
        state.selectedDate,
        meal: MealType.lunch,
      );
      expect(entries, hasLength(1));
      expect(entries.single.foodId, 'sample_snack_1');
      expect(entries.single.servings, 1.0);
    });

    testWidgets('meal builder: picking a food from All Foods adds a row', (
      tester,
    ) async {
      final state = await _freshState();
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: AppScope(state: state, child: const CreateMealScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No foods added yet'), findsOneWidget);
      // Narrow to a single match first — sample_snack_1 sorts well past
      // page one among 164 real foods, so it isn't built without this.
      // The meal builder has two TextFields (name + the picker's search
      // bar); match the search bar by its hint text, not by type alone.
      final searchField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Search foods…',
      );
      await tester.enterText(searchField, 'Sample Snack A');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('quick-add-sample_snack_1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('No foods added yet'), findsNothing);
      // A running _MealItemRow was added — its remove (X) icon is unique
      // to that widget, unlike the food's name which also still shows in
      // the (still-filtered) picker list below and in the search field.
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('no overflow, all three tabs', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('at 375x812, locale=$locale', (tester) async {
        final direction = locale == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr;
        final state = await _freshState(locale: locale);
        await state.addEntry(
          DateTime(2026, 7, 18),
          'sample_snack_1',
          1,
          MealType.snack,
        );
        await state.addSavedMeal(
          SavedMeal(
            id: state.newSavedMealId(),
            name: 'Test Combo',
            mealType: null,
            items: const [SavedMealItem(foodId: 'sample_snack_1', servings: 1)],
            createdAt: state.now(),
          ),
        );

        await _pump(
          tester,
          state,
          FoodPicker(
            onFoodTap: (_, _) {},
            onFoodQuickAdd: (_, _) {},
            onMealTap: (_) {},
            onMealQuickAdd: (_) {},
          ),
          direction: direction,
        );
        expect(tester.takeException(), isNull);

        for (final tabIndex in [0, 1, 2]) {
          await state.setFoodTabIndex(tabIndex);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  });
}
