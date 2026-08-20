import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';

// Fixed clock: Tuesday 2026-07-21, so the "today" cell and month header
// are deterministic across runs.
DateTime _now() => DateTime(2026, 7, 21, 9, 30);

Future<AppState> _pumpApp(WidgetTester tester, {String locale = 'en'}) async {
  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState(clock: _now);
  await state.load();
  state.localeCode = locale;
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('tapping the Today pill opens the calendar instead of '
      'jumping straight to today', (tester) async {
    final state = await _pumpApp(tester);
    state.selectDate(DateTime(2026, 7, 10)); // not today
    await tester.pumpAndSettle();

    await tester.tap(find.text('Today').first);
    await tester.pumpAndSettle();

    expect(find.text('July 2026'), findsOneWidget);
    // Still on the day we picked before opening it — opening the sheet is
    // not itself a jump to today anymore.
    expect(state.selectedDate, DateTime(2026, 7, 10));
  });

  testWidgets('tapping a day in the calendar selects it and closes the '
      'sheet', (tester) async {
    final state = await _pumpApp(tester);
    await tester.tap(find.text('Today').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();

    expect(state.selectedDate, DateTime(2026, 7, 15));
    expect(find.text('July 2026'), findsNothing); // sheet closed
  });

  testWidgets('month navigation moves the header forward and back', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Today').first);
    await tester.pumpAndSettle();

    expect(find.text('July 2026'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('August 2026'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('June 2026'), findsOneWidget);
  });

  testWidgets('renders without error in Arabic, with a Western-digit year', (
    tester,
  ) async {
    await _pumpApp(tester, locale: 'ar');
    await tester.tap(find.text('اليوم').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('2026'), findsWidgets);
    // No Eastern Arabic numerals anywhere in the sheet (hard requirement 1).
    for (final glyph in '٠١٢٣٤٥٦٧٨٩'.split('')) {
      expect(find.textContaining(glyph), findsNothing);
    }
  });
}
