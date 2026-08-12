import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/create_meal_screen.dart';
import 'package:calorie_tracker/models.dart';

Future<AppState> _pumpMealBuilder(
  WidgetTester tester, {
  Size size = const Size(375, 812),
  String locale = 'en',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final state = AppState(clock: () => DateTime(2026, 7, 20, 9, 30));
  await state.load();
  state.localeCode = locale;
  await tester.pumpWidget(
    MaterialApp(home: AppScope(state: state, child: const CreateMealScreen())),
  );
  await tester.pumpAndSettle();
  return state;
}

void main() {
  group('no overflow, all three tabs, with a running item', () {
    for (final size in [Size(320, 568), Size(375, 812)]) {
      for (final locale in ['en', 'ar']) {
        testWidgets('at ${size.width.toInt()}x${size.height.toInt()} $locale', (
          tester,
        ) async {
          final state = await _pumpMealBuilder(
            tester,
            size: size,
            locale: locale,
          );
          await state.addEntry(
            DateTime(2026, 7, 18),
            'sample_snack_1',
            1,
            MealType.snack,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'initial');

          // sample_snack_1 is now both previously-logged and pickable from
          // All Foods — narrow the query so its quick-add key is on page 1.
          await tester.enterText(find.byType(TextField).last, 'Sample Snack A');
          await tester.pump(const Duration(milliseconds: 200));
          await tester.pumpAndSettle();
          final quickAdd = find.byKey(
            const ValueKey('quick-add-sample_snack_1'),
          );
          await tester.tap(quickAdd.first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'after adding a row');

          for (final tabIndex in [1, 2, 0]) {
            await state.setFoodTabIndex(tabIndex);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'tab $tabIndex');
          }
        });
      }
    }
  });

  testWidgets('no overflow with several rows added at 320x568', (
    tester,
  ) async {
    await _pumpMealBuilder(tester, size: const Size(320, 568));
    const foods = {
      'sample_snack_1': 'Sample Snack A',
      'sample_snack_2': 'Sample Snack B',
      'sample_snack_3': 'Sample Snack C',
      'sample_main_1': 'Sample Main Dish A',
      'sample_main_2': 'Sample Main Dish B',
    };
    for (final entry in foods.entries) {
      await tester.enterText(find.byType(TextField).last, entry.value);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      final key = find.byKey(ValueKey('quick-add-${entry.key}'));
      expect(
        key,
        findsOneWidget,
        reason: 'row for ${entry.key} should be on page 1',
      );
      await tester.tap(key.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'after adding ${entry.key}');
    }
  });

  testWidgets('picking a food from All Foods adds a row without navigating', (
    tester,
  ) async {
    await _pumpMealBuilder(tester);
    expect(find.text('No foods added yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Sample Snack A');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-add-sample_snack_1')));
    await tester.pumpAndSettle();

    expect(find.text('No foods added yet'), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget); // the added row's remove
  });
}
