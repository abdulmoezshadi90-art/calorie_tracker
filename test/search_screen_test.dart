import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/food_db.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';
import 'package:calorie_tracker/search_screen.dart';

Future<AppState> _openSearch(
  WidgetTester tester, {
  String locale = 'en',
  double width = 375,
  double height = 812,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
  await state.load();
  state.localeCode = locale;
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('nav-add')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(locale == 'ar' ? 'الغداء' : 'Lunch').last);
  await tester.pumpAndSettle();
  return state;
}

/// The persistent tabs (Home/Progress/Foods/Settings) are all kept alive by
/// AppShell's IndexedStack, and every one of them has its own Scrollable —
/// so once the search screen is pushed on top, `find.byType(Scrollable)`
/// matches multiple candidates and `.first` picks an arbitrary, usually
/// wrong, one. The search screen's own subtree isn't unambiguous either:
/// the TextField's EditableText contributes its own (horizontal) Scrollable
/// for the text cursor, alongside the actual (vertical) results list — so
/// match on axis direction too.
Finder _searchScrollable() => find.descendant(
  of: find.byType(SearchScreen),
  matching: find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  ),
);

/// Small steps + a generous scroll budget: a coarse step can drift past a
/// target on a long, incrementally-measured sliver list (see the Foods-tab
/// scroll fix in foods_screen_test.dart for the same underlying reason).
/// maxScrolls is sized with headroom above the current foodDatabase length,
/// not just enough for today's count — the data pipeline (CLAUDE.md) keeps
/// adding categories, so a tight budget here breaks again with every batch.
Future<void> _scrollDownUntil(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    50,
    scrollable: _searchScrollable(),
    maxScrolls: 1200,
  );
}

Future<void> _dragDown(WidgetTester tester, {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await tester.drag(_searchScrollable(), const Offset(0, -300));
    await tester.pump();
  }
}

/// Types into the search field and deterministically waits out its 200ms
/// debounce. `pumpAndSettle()` alone is not reliable here: it only keeps
/// pumping while a frame is already scheduled, and a bare `Timer` (as
/// opposed to an animation) doesn't itself count — in practice it was
/// riding on the text cursor's own blink timer coincidentally scheduling a
/// frame, which raced against a prior scroll's settling and occasionally
/// lost, so the debounced query silently never applied.
Future<void> _enterQuery(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pumpAndSettle();
}

void main() {
  group('incremental window', () {
    testWidgets(
      'the first food beyond the initial page is absent until scrolled to',
      (tester) async {
        await _openSearch(tester);

        // 21st food in database order — the first one outside a 20-item
        // window — must not exist yet (it isn't even in itemCount, let
        // alone built), then must appear once scrolled to.
        final beyondFirstPage = foodDatabase[20].nameEn;
        expect(find.text(beyondFirstPage), findsNothing);

        await _scrollDownUntil(tester, find.text(beyondFirstPage));
        expect(find.text(beyondFirstPage), findsOneWidget);
      },
    );

    testWidgets('scrolling to the bottom reaches the last food', (
      tester,
    ) async {
      await _openSearch(tester);

      final lastFood = foodDatabase.last.nameEn;
      await _scrollDownUntil(tester, find.text(lastFood));
      expect(find.text(lastFood), findsOneWidget);
    });

    testWidgets(
      'changing the query resets the window and shows matches from the top',
      (tester) async {
        await _openSearch(tester);

        // "milk" matches more than one page.
        final milkFoods = foodDatabase
            .where((f) => f.nameEn.toLowerCase().contains('milk'))
            .toList();
        expect(milkFoods.length, greaterThan(20));
        final beyondFirstMilkPage = milkFoods[20].nameEn;

        await _enterQuery(tester, 'milk');
        expect(find.text(beyondFirstMilkPage), findsNothing);

        // Load a second page.
        await _scrollDownUntil(tester, find.text(beyondFirstMilkPage));
        expect(find.text(beyondFirstMilkPage), findsOneWidget);

        // Now change the query entirely — window resets to page one, and
        // the new match is visible without any further scrolling.
        await _enterQuery(tester, 'juhayna');
        expect(find.text('Juhayna Full Cream Milk'), findsOneWidget);
        // The old second-page item is gone — this is a different result
        // set now, not just a scroll-position artifact.
        expect(find.text(beyondFirstMilkPage), findsNothing);
      },
    );
  });

  group('search correctness with the precomputed index', () {
    testWidgets('EN query matches by English name', (tester) async {
      await _openSearch(tester);
      await _enterQuery(tester, 'sample snack');
      expect(find.textContaining('Sample Snack'), findsNWidgets(4));
    });

    testWidgets('AR query matches by Arabic name', (tester) async {
      await _openSearch(tester, locale: 'ar');
      await _enterQuery(tester, 'الريحان');
      expect(find.text('الريحان - حليب كامل الدسم'), findsOneWidget);
    });
  });

  testWidgets('quick add works on a row from the second page', (tester) async {
    final state = await _openSearch(tester);
    await _enterQuery(tester, 'milk');

    // The last MILK result, not foodDatabase.last — later categories appended
    // after the dairy batch (e.g. meat) would otherwise end the database on
    // an item this 'milk' query never matches.
    final lastFood = foodDatabase
        .where((f) => f.nameEn.toLowerCase().contains('milk'))
        .last;
    await _scrollDownUntil(tester, find.text(lastFood.nameEn));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text(lastFood.nameEn),
          matching: find.byType(ListTile),
        ),
        matching: find.byIcon(Icons.add_circle_outline),
      ),
    );
    await tester.pumpAndSettle();

    final entries = state.entriesFor(state.selectedDate, meal: MealType.lunch);
    expect(entries.length, 1);
    expect(entries.single.foodId, lastFood.id);
  });

  group('no overflow', () {
    for (final size in [(375.0, 812.0), (320.0, 640.0)]) {
      testWidgets('at ${size.$1.toInt()}x${size.$2.toInt()}', (tester) async {
        await _openSearch(tester, width: size.$1, height: size.$2);
        expect(tester.takeException(), isNull);
        await _dragDown(tester, times: 4);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('kcal figures on the list stay Western-digit in Arabic', (
    tester,
  ) async {
    await _openSearch(tester, locale: 'ar');
    expect(find.textContaining('٠'), findsNothing);
    expect(find.textContaining('١'), findsNothing);
    expect(find.textContaining('٥'), findsNothing);
  });
}
