import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/food_db.dart';
import 'package:calorie_tracker/l10n.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

Future<void> _openFoods(WidgetTester tester, {String locale = 'en'}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState();
  await state.load();
  state.localeCode = locale;
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.restaurant_menu_outlined));
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in ['en', 'ar']) {
    testWidgets('Foods renders every category at 375x812 ($locale)', (
      tester,
    ) async {
      await _openFoods(tester, locale: locale);
      final l = L10n(locale);

      expect(tester.takeException(), isNull);
      // Every category header is present (scroll through the whole list).
      for (final category in FoodCategory.values) {
        await tester.scrollUntilVisible(
          find.text(l.category(category)),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(l.category(category)), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      if (locale == 'ar') {
        final context = tester.element(find.byType(Scrollable).first);
        expect(Directionality.of(context), TextDirection.rtl);
      }
    });
  }

  testWidgets('approximate marker shows on unverified foods', (tester) async {
    await _openFoods(tester);
    // All current foods are unverified placeholders → marker present.
    expect(find.text('approx.'), findsWidgets);
    // Sanity: the database is indeed all-unverified for now.
    expect(foodDatabase.every((f) => !f.verified), isTrue);
  });
}
