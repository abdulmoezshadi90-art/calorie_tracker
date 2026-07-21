import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/progress_screen.dart';
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

Future<void> _openProgress(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.insights_outlined));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('history shows empty message with no logged days', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openProgress(tester);

    expect(tester.takeException(), isNull);
    // App bar title + bottom-nav tab label both say History.
    expect(find.text('Progress'), findsNWidgets(2));
    expect(find.text('No logged days yet'), findsOneWidget);
    // The 7-day calorie chart is always present; the weight card shows
    // its own empty state when no weight is logged.
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('No weight logged yet'), findsOneWidget);
  });

  testWidgets('7-day chart renders with data, over-goal and RTL variants', (
    tester,
  ) async {
    final state = await _pumpApp(tester);
    state.addEntry(DateTime(2026, 7, 13), 'kalee_cheese', 1, MealType.snack);
    for (var i = 0; i < 5; i++) {
      state.addEntry(DateTime(2026, 7, 14), 'bazin', 1, MealType.lunch);
    }
    await tester.pumpAndSettle();

    await _openProgress(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Last 7 days'), findsOneWidget);

    final painter =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is WeekBarChartPainter,
                  ),
                )
                .painter
            as WeekBarChartPainter;
    // 7 slots ending today (15th); the 13th and 14th carry the data.
    expect(painter.kcals.length, 7);
    expect(painter.labels, ['9', '10', '11', '12', '13', '14', '15']);
    expect(painter.kcals[4], 130);
    expect(painter.kcals[5], 2700); // over goal → gold bar
    expect(painter.kcals[6], 0);
    expect(painter.isRtl, isFalse);

    // Same chart in Arabic flags RTL so bars mirror.
    state.toggleLocale();
    await tester.pumpAndSettle();
    final rtlPainter =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is WeekBarChartPainter,
                  ),
                )
                .painter
            as WeekBarChartPainter;
    expect(rtlPainter.isRtl, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history lists one day and opens its read-only view', (
    tester,
  ) async {
    final state = await _pumpApp(tester);
    final day = DateTime(2026, 7, 10);
    state.addEntry(day, 'bazin', 1, MealType.lunch); // 540 kcal
    state.addEntry(day, 'kalee_cheese', 2, MealType.snack); // 260 kcal
    await tester.pumpAndSettle();

    await _openProgress(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Friday, July 10 · 2026'), findsOneWidget);
    expect(find.text('800 / 2,000 kcal'), findsOneWidget);
    expect(find.text('Within goal'), findsOneWidget);

    // Read-only day view: meals, foods, total — and no delete buttons.
    await tester.tap(find.text('Friday, July 10 · 2026'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Snack'), findsOneWidget);
    expect(find.text('Bazin with Sauce'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('800 kcal'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('over-goal day gets the neutral over chip', (tester) async {
    final state = await _pumpApp(tester);
    final day = DateTime(2026, 7, 9);
    for (var i = 0; i < 5; i++) {
      state.addEntry(day, 'bazin', 1, MealType.lunch); // 5 × 540 = 2,700
    }
    await tester.pumpAndSettle();

    await _openProgress(tester);
    expect(find.text('Over goal'), findsOneWidget);
    expect(find.text('2,700 / 2,000 kcal'), findsOneWidget);
  });

  testWidgets('30 logged days render newest-first without overflow', (
    tester,
  ) async {
    final state = await _pumpApp(tester);
    for (var i = 1; i <= 30; i++) {
      state.addEntry(
        DateTime(2026, 7, 15).subtract(Duration(days: i)),
        'kalee_cheese',
        1,
        MealType.snack,
      );
    }
    await tester.pumpAndSettle();

    await _openProgress(tester);
    expect(tester.takeException(), isNull);
    // Newest logged day is first in the list order (state guarantees it);
    // its tile is inflated near the top under the two chart cards.
    expect(state.loggedDates().first, DateTime(2026, 7, 14));
    expect(find.text('Tuesday, July 14 · 2026'), findsOneWidget);
    // Scroll to the bottom; list must survive the full range.
    await tester.fling(find.byType(ListView), const Offset(0, -4000), 3000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Monday, June 15 · 2026'), findsOneWidget);
  });

  testWidgets('history renders RTL with Western digits', (tester) async {
    final state = await _pumpApp(tester, locale: 'ar');
    state.addEntry(DateTime(2026, 7, 10), 'bazin', 1, MealType.lunch);
    await tester.pumpAndSettle();

    await _openProgress(tester);
    expect(tester.takeException(), isNull);
    // App bar title + bottom-nav tab label both say التقدّم.
    expect(find.text('التقدّم'), findsNWidgets(2));
    expect(find.text('الجمعة، 10 يوليو · 2026'), findsOneWidget);
    final context = tester.element(find.text('التقدّم').first);
    expect(Directionality.of(context), TextDirection.rtl);
    expect(find.textContaining('٢'), findsNothing);
  });

  testWidgets('weight chart renders with 0, 1, 2, and 30 points', (
    tester,
  ) async {
    for (final n in [0, 1, 2, 30]) {
      SharedPreferences.setMockInitialValues({'onboarding_done': true});
      final state = AppState(clock: () => DateTime(2026, 7, 15));
      await state.load();
      for (var i = 0; i < n; i++) {
        await state.logWeight(
          DateTime(2026, 6, 16).add(Duration(days: i)),
          80 + (i % 5) * 0.5,
        );
      }
      // Fresh key each iteration so the shell's tab state doesn't carry
      // over (element reuse would keep Progress selected otherwise).
      await tester.pumpWidget(CalorieApp(key: UniqueKey(), state: state));
      await tester.pumpAndSettle();
      await _openProgress(tester);

      expect(tester.takeException(), isNull, reason: 'n=$n threw');
      if (n == 0) {
        expect(find.text('No weight logged yet'), findsOneWidget);
      } else {
        final painter =
            tester
                    .widget<CustomPaint>(
                      find.byWidgetPredicate(
                        (w) =>
                            w is CustomPaint &&
                            w.painter is WeightLineChartPainter,
                      ),
                    )
                    .painter
                as WeightLineChartPainter;
        expect(painter.kgs.length, n);
        // A single point shows the trend hint, not a fake line.
        expect(
          find.text('Log weight regularly to see your trend'),
          n == 1 ? findsOneWidget : findsNothing,
        );
      }
    }
  });
}
