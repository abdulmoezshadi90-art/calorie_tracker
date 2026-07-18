import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

Future<AppState> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState();
  await state.load();
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  setUp(() {
    // iPhone-ish portrait viewport.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('home screen renders all sections without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Today'), findsOneWidget); // header date pill
    expect(find.text("Today's calories"), findsOneWidget);
    expect(find.textContaining('of 2,000 kcal'), findsOneWidget);
    expect(find.text('2,000 kcal left today'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('0 of 4'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Snack'), findsOneWidget);
    expect(find.text('Add meal'), findsOneWidget);
    expect(find.text('Not logged yet'), findsNWidgets(4));
  });

  testWidgets('logging food updates calories, macros, and meal row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final state = await _pumpApp(tester);

    // Log 2 servings of Kalee cheese chips (130 kcal each) to Snack.
    state.addEntry(state.selectedDate, 'kalee_cheese', 2, MealType.snack);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('260'), findsWidgets); // 2 × 130 kcal
    expect(find.text('1,740 kcal left today'), findsOneWidget);
    expect(find.text('260 kcal'), findsOneWidget); // snack row amount
    expect(find.text('1 of 4'), findsOneWidget);
    expect(find.text('Not logged yet'), findsNWidgets(3));
    // Macros: 2 × (15 carb, 7 fat, 2 protein). Values live in a Text.rich.
    expect(find.textContaining('30 / 220 g'), findsOneWidget);
    expect(find.textContaining('14 / 65 g'), findsOneWidget);
    expect(find.textContaining('4 / 110 g'), findsOneWidget);
  });

  testWidgets('arabic locale renders RTL with Western digits', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final state = await _pumpApp(tester);
    state.toggleLocale();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('اليوم'), findsOneWidget); // date pill
    expect(find.text('سعرات اليوم'), findsOneWidget);
    expect(find.text('تبقّى 2,000 سعرة اليوم'), findsOneWidget);
    expect(find.text('الوجبات'), findsOneWidget);

    // Layout must be RTL.
    final context = tester.element(find.text('اليوم'));
    expect(Directionality.of(context), TextDirection.rtl);

    // Digits stay Western: no Eastern Arabic numerals anywhere.
    expect(find.textContaining('٢'), findsNothing);
  });
}
