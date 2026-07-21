import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

Future<AppState> _pumpApp(WidgetTester tester, {String locale = 'en'}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
  await state.load();
  state.localeCode = locale;
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('bottom nav switches between Today, History and Settings', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text("Today's calories"), findsOneWidget);

    await tester.tap(find.byIcon(Icons.insights_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Last 7 days'), findsOneWidget); // chart always shown
    expect(find.text('No logged days yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Daily goals'), findsOneWidget);
    // Language toggle is the first settings card now.
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text("Today's calories"), findsOneWidget);
  });

  testWidgets('center Add opens the meal chooser then search', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('nav-add')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a meal'), findsOneWidget);

    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();
    expect(find.text('Search foods…'), findsOneWidget);
  });

  testWidgets('history empty-state back-to-today switches to the Today tab', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.insights_outlined));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Back to today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to today'));
    await tester.pumpAndSettle();
    expect(find.text("Today's calories"), findsOneWidget);
  });

  testWidgets('5-item nav order mirrors in RTL, Add stays centered', (
    tester,
  ) async {
    // LTR: Today · Progress · Add · Foods · Settings, left to right.
    await _pumpApp(tester);
    final width = tester.getSize(find.byType(MaterialApp)).width;
    double x(Finder f) => tester.getCenter(f).dx;
    final addX = x(find.byKey(const Key('nav-add')));
    expect(x(find.byIcon(Icons.home)), lessThan(x(find.byIcon(Icons.insights_outlined))));
    expect(x(find.byIcon(Icons.insights_outlined)), lessThan(addX));
    expect(addX, lessThan(x(find.byIcon(Icons.restaurant_menu_outlined))));
    expect(
      x(find.byIcon(Icons.restaurant_menu_outlined)),
      lessThan(x(find.byIcon(Icons.settings_outlined))),
    );
    // Add is horizontally centered.
    expect((addX - width / 2).abs(), lessThan(2));

    // RTL: whole order reverses; Add stays centered.
    await _pumpApp(tester, locale: 'ar');
    final addXRtl = x(find.byKey(const Key('nav-add')));
    expect(x(find.byIcon(Icons.home)), greaterThan(x(find.byIcon(Icons.insights_outlined))));
    expect(x(find.byIcon(Icons.insights_outlined)), greaterThan(addXRtl));
    expect(addXRtl, greaterThan(x(find.byIcon(Icons.restaurant_menu_outlined))));
    expect(
      x(find.byIcon(Icons.restaurant_menu_outlined)),
      greaterThan(x(find.byIcon(Icons.settings_outlined))),
    );
    expect((addXRtl - width / 2).abs(), lessThan(2));
    final context = tester.element(find.byKey(const Key('nav-add')));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('Foods tab lists categories; tapping a food logs via a meal', (
    tester,
  ) async {
    final state = await _pumpApp(tester);
    await tester.tap(find.byIcon(Icons.restaurant_menu_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Foods'), findsNWidgets(2)); // app bar + nav label
    expect(find.text('Snacks'), findsOneWidget); // a category header

    // Bazin is under Mains. Scroll to a food a few rows below it so Bazin
    // lands mid-viewport, clear of the bottom nav, then log it.
    await tester.scrollUntilVisible(
      find.text('Rishda'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Bazin with Sauce'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a meal'), findsOneWidget);
    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Add · 540'));
    await tester.pumpAndSettle();

    expect(state.entriesFor(state.selectedDate, meal: MealType.lunch).length, 1);
  });
}
