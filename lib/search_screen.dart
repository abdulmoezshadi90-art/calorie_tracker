import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'empty_state.dart';
import 'food_db.dart';
import 'food_detail_screen.dart';
import 'food_history_tab.dart';
import 'models.dart';
import 'saved_meals_tab.dart';
import 'theme.dart';

/// One food's search text, folded to lowercase (EN only — Arabic has no
/// letter case) exactly once at startup. Filtering a keystroke then never
/// re-lowercases the whole database inside build(); it was the measured
/// cause of per-keystroke jank once the database grew past a couple dozen
/// items (see the profiling notes on the perf-fix commit).
class _SearchEntry {
  const _SearchEntry(this.food, this.enLower);
  final FoodItem food;
  final String enLower;
}

final List<_SearchEntry> _searchIndex = [
  for (final f in foodDatabase) _SearchEntry(f, f.nameEn.toLowerCase()),
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.meal});
  final MealType meal;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _pageSize = 20;
  static const _debounceDelay = Duration(milliseconds: 200);
  static const _loadMoreAt = 0.8; // fraction of scroll extent

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  // The full filtered set for the last APPLIED query, recomputed only when
  // that query actually changes — never on every keystroke or unrelated
  // rebuild (diagnosis #2/#3). _visible windows it down to _visibleCount
  // rows; more of the already-filtered list appends silently near the
  // bottom of the scroll (no spinner: this is local data, there is nothing
  // to wait for).
  List<FoodItem> _filtered = foodDatabase;
  int _visibleCount = _pageSize;

  // True once the field holds non-empty trimmed text — gates the tab
  // selector/content vs. the search results list (point 4 of the tab
  // selector spec: search text hides the tabs entirely, clearing restores
  // whichever tab was selected before).
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => _applyQuery(value));
  }

  void _applyQuery(String value) {
    final q = value.trim().toLowerCase();
    final filtered = q.isEmpty
        ? foodDatabase
        : [
            for (final entry in _searchIndex)
              if (entry.enLower.contains(q) || entry.food.nameAr.contains(q))
                entry.food,
          ];
    setState(() {
      _filtered = filtered;
      _visibleCount = _pageSize;
      _isSearching = q.isNotEmpty;
    });
    // A changed query always starts the list from the top — the old
    // scroll offset has no meaning against a different result set. This
    // never fires for reasons OTHER than the query changing, so scroll
    // position stays put across unrelated rebuilds.
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients || _visibleCount >= _filtered.length) {
      return;
    }
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent * _loadMoreAt) {
      setState(() {
        _visibleCount = (_visibleCount + _pageSize).clamp(0, _filtered.length);
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    _applyQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final visible = _filtered.take(_visibleCount).toList();

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Text('${l.add} · ${l.mealName(widget.meal)}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onQueryChanged,
              style: TextStyle(color: c.ink),
              decoration: InputDecoration(
                hintText: l.searchHint,
                hintStyle: TextStyle(color: c.muted),
                prefixIcon: Icon(Icons.search, color: c.muted),
                filled: true,
                fillColor: c.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!_isSearching) _FoodTabSelector(),
          Expanded(
            child: !_isSearching
                ? (state.foodTabIndex == 0
                      ? HistoryTab(meal: widget.meal)
                      : MyMealsTab(meal: widget.meal))
                : _filtered.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_outlined,
                    line: l.noResults,
                    hint: l.searchEmptyHint,
                    actionLabel: l.clearSearch,
                    onAction: _clearSearch,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: visible.length,
                    itemBuilder: (context, i) => RepaintBoundary(
                      child: _FoodTile(food: visible[i], meal: widget.meal),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.meal});
  final FoodItem food;
  final MealType meal;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    final l = state.l;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            l.foodName(food),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
          subtitle: Text(
            '${l.servingLabel(food)} · ${l.category(food.category)}',
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
          // Row order only — never flipped by hand, so RTL mirrors it.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${fmtInt(food.kcal)} ${l.kcal}',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.kcalAccent,
                    ),
                  ),
                ),
              ),
              _QuickAddButton(food: food, meal: meal),
            ],
          ),
          // Search is itself a pushed route; when the detail page reports a
          // successful log (pop(true)), also close search so the user lands
          // back on Home, matching the old sheet-on-search behavior.
          onTap: () async {
            final logged = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => FoodDetailScreen(food: food, meal: meal),
              ),
            );
            if (logged == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}

/// Logs one base serving straight into [meal] without leaving the list:
/// haptic, then an undo snackbar (mirrors the delete-undo pattern) since
/// local-only storage has no backup for a mis-tap. Min 44×44 tap target.
class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.food, required this.meal});
  final FoodItem food;
  final MealType meal;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    // Exact 44×44 footprint: IconButton's own min-tap-target padding would
    // overflow a SizedBox wrapper, so build the circle directly.
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _quickAdd(context, state),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.add_circle_outline, color: c.accent),
        ),
      ),
    );
  }

  Future<void> _quickAdd(BuildContext context, AppState state) async {
    final l = state.l;
    HapticFeedback.lightImpact();
    final date = state.selectedDate;
    final ok = await state.addEntry(date, food.id, 1.0, meal);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l.saveFailed)));
      return;
    }
    final kcal = food.kcal;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${l.added}: ${l.foodName(food)} · ${fmtInt(kcal)} ${l.kcal}',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () async {
            // Quick add always logs exactly one fresh entry; find and
            // remove it by matching food+meal+quantity on today's list —
            // safe because it was just added and ids are unique per tap.
            final match = state
                .entriesFor(date, meal: meal)
                .lastWhere((e) => e.foodId == food.id && e.quantity == 1.0);
            await state.removeEntry(date, match.id);
          },
        ),
      ),
    );
  }
}

/// Two equal-width segments below the search bar — History / My Meals.
/// Selected segment fills with the accent color; unselected stays flat on
/// the surrounding chip background, matching the rounded/soft-shadow card
/// language used throughout home_screen.dart. Selection persists via
/// AppState.foodTabIndex.
class _FoodTabSelector extends StatelessWidget {
  const _FoodTabSelector();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    final l = state.l;
    final selected = state.foodTabIndex;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.chipBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: c.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _FoodTabSegment(
              label: l.logHistoryTab,
              selected: selected == 0,
              onTap: () => state.setFoodTabIndex(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _FoodTabSegment(
              label: l.myMeals,
              selected: selected == 1,
              onTap: () => state.setFoodTabIndex(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodTabSegment extends StatelessWidget {
  const _FoodTabSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: selected ? c.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? c.onAccent : c.muted,
            ),
          ),
        ),
      ),
    );
  }
}
