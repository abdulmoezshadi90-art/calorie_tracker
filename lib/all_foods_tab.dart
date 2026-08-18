import 'package:flutter/material.dart';

import 'app_state.dart';
import 'custom_food_screen.dart';
import 'empty_state.dart';
import 'models.dart';
import 'round_icon_button.dart';
import 'theme.dart';

/// One row in the flattened list: either a section header or a food. A
/// single ListView.builder walks this list (hard rule: no nested
/// scrollables, no two separate ListViews for the two sections).
sealed class _Row {
  const _Row();
}

class _HeaderRow extends _Row {
  const _HeaderRow(this.label);
  final String label;
}

class _FoodRow extends _Row {
  const _FoodRow(this.food);
  final FoodItem food;
}

/// All Foods tab content (food_picker.dart's third tab): every food in
/// food_db, A-to-Z by the current locale's display name, split into
/// "Previously logged" (foods the user has logged at least once) and
/// "All foods" (everything else) — the split fixes the first-time-user
/// dead end, since History and My Meals both start empty. Same
/// compute-outside-build, listener-driven recompute idiom as
/// food_history_tab.dart's HistoryTab and saved_meals_tab.dart's
/// MyMealsTab.
class AllFoodsTab extends StatefulWidget {
  const AllFoodsTab({
    super.key,
    required this.query,
    required this.onFoodTap,
    required this.onQuickAdd,
    required this.onClearSearch,
    required this.onAddCustomFood,
  });

  /// Trimmed or raw search text from food_picker.dart — empty means show
  /// everything. Matches against both the English and Arabic name of every
  /// food regardless of the current locale.
  final String query;

  /// Row tap — pushes the food detail screen (log flow logs to today, the
  /// meal builder uses its draft-mode to add a row instead). Second
  /// argument is the serving count to start from (always 1 here — a food
  /// with no logging history has no "last used" amount to prefill).
  final void Function(FoodItem food, double servings) onFoodTap;

  /// Plus button — adds one serving directly (log flow logs it to today
  /// with undo; the meal builder appends a row), matching how the History
  /// tab's plus button already behaves.
  final void Function(FoodItem food, double servings) onQuickAdd;

  /// Clears the shared picker's search field — the "no matches" empty
  /// state's action. food_db always has entries, so this is never reached
  /// with an empty query (see the debug assertion in build()).
  final VoidCallback onClearSearch;

  /// The persistent "Add a food" row's tap target — always visible, never
  /// hidden, unlike the log-flow-only action cards on the My Meals tab
  /// (creating a custom food isn't tied to "today" or a specific meal).
  final VoidCallback onAddCustomFood;

  @override
  State<AllFoodsTab> createState() => _AllFoodsTabState();
}

class _AllFoodsTabState extends State<AllFoodsTab> {
  static const _pageSize = 20;
  static const _loadMoreAt = 0.8;

  final _scrollController = ScrollController();
  int _visibleCount = _pageSize;
  List<FoodItem> _logged = const [];
  List<FoodItem> _rest = const [];
  AppState? _state;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    if (!identical(state, _state)) {
      _state?.removeListener(_recompute);
      _state = state;
      state.addListener(_recompute);
      _recompute();
    }
  }

  @override
  void didUpdateWidget(covariant AllFoodsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _visibleCount = _pageSize;
      // Deferred: didUpdateWidget runs mid-build (this widget's parent is
      // rebuilding), and jumpTo's scroll notification would otherwise
      // reach ancestors (e.g. an AppBar reacting to scroll) that try to
      // setState while the tree is still building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      });
      _recompute();
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_recompute);
    _scrollController.dispose();
    super.dispose();
  }

  void _recompute() {
    final state = _state;
    if (state == null) return;
    final l = state.l;
    final q = widget.query.trim().toLowerCase();

    bool matches(FoodItem f) {
      if (q.isEmpty) return true;
      return f.nameEn.toLowerCase().contains(q) || f.nameAr.contains(q);
    }

    final loggedIds = {for (final e in state.historyEntries) e.food.id};
    final logged = <FoodItem>[];
    final rest = <FoodItem>[];
    for (final f in state.allFoods) {
      if (!matches(f)) continue;
      (loggedIds.contains(f.id) ? logged : rest).add(f);
    }
    int byName(FoodItem a, FoodItem b) =>
        l.foodName(a).compareTo(l.foodName(b));
    logged.sort(byName);
    rest.sort(byName);

    if (!mounted) {
      _logged = logged;
      _rest = rest;
      return;
    }
    setState(() {
      _logged = logged;
      _rest = rest;
    });
  }

  void _maybeLoadMore() {
    final total = _rowCount;
    if (!_scrollController.hasClients || _visibleCount >= total) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent * _loadMoreAt) {
      setState(() {
        _visibleCount = (_visibleCount + _pageSize).clamp(0, total);
      });
    }
  }

  int get _rowCount {
    final showHeaders = _logged.isNotEmpty;
    return (showHeaders ? 2 : 0) + _logged.length + _rest.length;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final showHeaders = _logged.isNotEmpty;

    final rows = <_Row>[
      if (showHeaders) _HeaderRow(l.previouslyLoggedHeader),
      for (final f in _logged) _FoodRow(f),
      if (showHeaders) _HeaderRow(l.allFoodsSectionHeader),
      for (final f in _rest) _FoodRow(f),
    ];

    // food_db always has entries — an empty unfiltered list is a real bug,
    // not a state to design a screen for (hard rule 5).
    assert(
      rows.isNotEmpty || widget.query.trim().isNotEmpty,
      'AllFoodsTab rendered empty with no active query — food_db is empty?',
    );

    final Widget body;
    if (rows.isEmpty) {
      // Only reachable with an active query — never say "the food list is
      // empty" here, because it is not; only this search came up empty.
      body = EmptyState(
        icon: Icons.search_off_outlined,
        line: l.noResults,
        hint: l.searchEmptyHint,
        actionLabel: l.clearSearch,
        onAction: widget.onClearSearch,
      );
    } else {
      final visible = rows.take(_visibleCount).toList();
      body = ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: visible.length,
        itemBuilder: (context, i) => switch (visible[i]) {
          _HeaderRow(:final label) => _SectionHeader(label: label),
          _FoodRow(:final food) => RepaintBoundary(
            child: _AllFoodsRow(
              food: food,
              onTap: widget.onFoodTap,
              onQuickAdd: widget.onQuickAdd,
            ),
          ),
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _AddFoodRow(onTap: widget.onAddCustomFood),
        ),
        Expanded(child: body),
      ],
    );
  }
}

/// Persistent header above the list — always visible regardless of search
/// or empty state, matching how the My Meals tab's action cards stay put
/// (saved_meals_tab.dart), just styled as a single full-width row instead
/// of a card since there's only one action here, not two side by side.
class _AddFoodRow extends StatelessWidget {
  const _AddFoodRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppScope.of(context).l;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: c.accent, size: 22),
                const SizedBox(width: 12),
                Text(
                  l.addFoodAction,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.muted,
        ),
      ),
    );
  }
}

class _AllFoodsRow extends StatelessWidget {
  const _AllFoodsRow({
    required this.food,
    required this.onTap,
    required this.onQuickAdd,
  });
  final FoodItem food;
  final void Function(FoodItem, double) onTap;
  final void Function(FoodItem, double) onQuickAdd;

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
            l.servingLabel(food),
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
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
              Material(
                key: ValueKey('quick-add-${food.id}'),
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onQuickAdd(food, 1.0),
                  child: RoundIconButton(
                    bg: c.plusIdleBg,
                    icon: Icons.add,
                    iconColor: c.plusIdleIcon,
                  ),
                ),
              ),
            ],
          ),
          onTap: () => onTap(food, 1.0),
          // Edit/delete only make sense for a food the user created —
          // food_db.dart entries are the curated, verified database and
          // stay read-only.
          onLongPress: food.category == FoodCategory.custom
              ? () => showCustomFoodOptionsSheet(context: context, food: food)
              : null,
        ),
      ),
    );
  }
}
