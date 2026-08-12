import 'package:flutter/material.dart';

import 'app_state.dart';
import 'empty_state.dart';
import 'filter_sort_sheet.dart';
import 'models.dart';
import 'round_icon_button.dart';
import 'theme.dart';

/// History tab content (food_picker.dart's tab selector, tab 1): every
/// food ever logged, aggregated across all days, filterable by meal type,
/// sortable, and matched against the shared picker's search query. The
/// list itself is computed by [_recompute] — never inside build() — and
/// only redone when AppState actually notifies (a log mutation or a
/// filter/sort change) or the query changes, same idiom as
/// _MyMealsTabState's own _recompute.
class HistoryTab extends StatefulWidget {
  const HistoryTab({
    super.key,
    required this.query,
    required this.onFoodTap,
    required this.onQuickAdd,
    required this.onBrowseAllFoods,
    required this.onClearFilters,
  });

  /// Trimmed or raw search text from food_picker.dart — empty means
  /// unfiltered by search (the existing meal-type filter still applies).
  final String query;

  /// Row tap — log flow pushes the food detail screen, the meal builder
  /// adds a row to the draft meal. Second argument is the food's last-used
  /// serving amount, so the log flow can prefill it.
  final void Function(FoodItem food, double servings) onFoodTap;

  /// Plus button — adds the food's last-used serving amount directly.
  final void Function(FoodItem food, double servings) onQuickAdd;

  /// "Browse all foods" action on the no-logs-at-all empty state — switches
  /// the shared picker to the All Foods tab.
  final VoidCallback onBrowseAllFoods;

  /// "Clear filter" action when logs exist but the meal-type filter and/or
  /// search query leave nothing to show — resets both.
  final VoidCallback onClearFilters;

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<HistoryEntry> _visible = const [];
  AppState? _state;

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
  void didUpdateWidget(covariant HistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _recompute();
  }

  @override
  void dispose() {
    _state?.removeListener(_recompute);
    super.dispose();
  }

  void _recompute() {
    final state = _state;
    if (state == null) return;
    final filter = state.historyFilter;
    final q = widget.query.trim().toLowerCase();
    bool matchesQuery(FoodItem f) =>
        q.isEmpty || f.nameEn.toLowerCase().contains(q) || f.nameAr.contains(q);
    var entries = [
      for (final e in state.historyEntries)
        if ((filter == null || e.mealTypes.contains(filter)) &&
            matchesQuery(e.food))
          e,
    ];
    final isAr = state.localeCode == 'ar';
    switch (state.historySort) {
      case SortOption.mostRecent:
        entries.sort((a, b) => b.lastLoggedAt.compareTo(a.lastLoggedAt));
      case SortOption.mostFrequent:
        entries.sort((a, b) {
          final byCount = b.logCount.compareTo(a.logCount);
          return byCount != 0
              ? byCount
              : b.lastLoggedAt.compareTo(a.lastLoggedAt);
        });
      case SortOption.aToZ:
        entries.sort((a, b) => _name(a, isAr).compareTo(_name(b, isAr)));
      case SortOption.zToA:
        entries.sort((a, b) => _name(b, isAr).compareTo(_name(a, isAr)));
    }
    if (!mounted) {
      _visible = entries;
      return;
    }
    setState(() => _visible = entries);
  }

  static String _name(HistoryEntry e, bool isAr) =>
      isAr ? e.food.nameAr : e.food.nameEn;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final hasAnyHistory = state.historyEntries.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            l.recentlyLogged,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).ink,
            ),
          ),
        ),
        if (hasAnyHistory) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilterSortRow(
              filter: state.historyFilter,
              sort: state.historySort,
              onFilterChanged: (f) => state.setHistoryFilter(f),
              onSortChanged: (s) => state.setHistorySort(s),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: !hasAnyHistory
              ? EmptyState(
                  icon: Icons.history,
                  line: l.historyTabEmptyLine,
                  actionLabel: l.browseAllFoods,
                  onAction: widget.onBrowseAllFoods,
                )
              : _visible.isEmpty
              ? EmptyState(
                  icon: Icons.filter_list_off,
                  line: l.noFilterMatchLine,
                  actionLabel: l.clearFilterAction,
                  onAction: widget.onClearFilters,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _visible.length,
                  itemBuilder: (context, i) => RepaintBoundary(
                    child: _HistoryRow(
                      entry: _visible[i],
                      onTap: widget.onFoodTap,
                      onQuickAdd: widget.onQuickAdd,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.onTap,
    required this.onQuickAdd,
  });
  final HistoryEntry entry;
  final void Function(FoodItem, double) onTap;
  final void Function(FoodItem, double) onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    final l = state.l;
    final food = entry.food;
    final kcal = food.kcal * entry.lastServings;

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
            '${fmtServings(entry.lastServings)} × ${l.servingLabel(food)}',
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${fmtInt(kcal)} ${l.kcal}',
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
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onQuickAdd(food, entry.lastServings),
                  child: RoundIconButton(
                    bg: c.plusIdleBg,
                    icon: Icons.add,
                    iconColor: c.plusIdleIcon,
                  ),
                ),
              ),
            ],
          ),
          onTap: () => onTap(food, entry.lastServings),
        ),
      ),
    );
  }
}
