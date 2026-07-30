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
      // Small delta + generous maxScrolls: the milk batch made Drinks long
      // enough that the sliver list's extent estimate keeps growing as
      // more children get measured, and a coarse step can drift right past
      // a header before the check between drags ever sees it.
      for (final category in FoodCategory.values) {
        await tester.scrollUntilVisible(
          find.text(l.category(category)),
          50,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 300,
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
    // Placeholder sample_* foods are still unverified → marker present.
    expect(find.text('approx.'), findsWidgets);
    // Sanity: the placeholder foods are indeed unverified (verified data,
    // e.g. the milk batch, is expected alongside them from Phase 2 on).
    expect(
      foodDatabase.where((f) => f.id.startsWith('sample_')).every(
        (f) => !f.verified,
      ),
      isTrue,
    );
  });
}
