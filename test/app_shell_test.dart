import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';

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

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    expect(find.text('Last 7 days'), findsNothing); // no logs → empty state
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

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to today'));
    await tester.pumpAndSettle();
    expect(find.text("Today's calories"), findsOneWidget);
  });

  testWidgets('nav item order mirrors in RTL', (tester) async {
    await _pumpApp(tester, locale: 'ar');

    // Today tab is selected at rest, so its icon is the filled variant.
    final todayX = tester.getCenter(find.byIcon(Icons.home)).dx;
    final settingsX =
        tester.getCenter(find.byIcon(Icons.settings_outlined)).dx;
    // RTL: first item (Today) sits on the right of the last (Settings).
    expect(todayX, greaterThan(settingsX));

    final context = tester.element(find.byKey(const Key('nav-add')));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
