import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'empty_state.dart';
import 'filter_sort_sheet.dart';
import 'food_detail_screen.dart';
import 'models.dart';
import 'round_icon_button.dart';
import 'theme.dart';

/// History tab content (search_screen.dart's tab selector, tab 1): every
/// food ever logged, aggregated across all days, filterable by meal type
/// and sortable. The list itself is computed by [_recompute] — never
/// inside build() — and only redone when AppState actually notifies
/// (a log mutation or a filter/sort change), same idiom as
/// _SearchScreenState's own _filtered field.
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key, required this.meal});
  final MealType meal;

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
  void dispose() {
    _state?.removeListener(_recompute);
    super.dispose();
  }

  void _recompute() {
    final state = _state;
    if (state == null) return;
    final filter = state.historyFilter;
    var entries = [
      for (final e in state.historyEntries)
        if (filter == null || e.mealTypes.contains(filter)) e,
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
              ? EmptyState(icon: Icons.history, line: l.historyTabEmptyLine)
              : _visible.isEmpty
              ? EmptyState(
                  icon: Icons.filter_list_off,
                  line: l.noFilterMatchLine,
                  actionLabel: l.clearFilterAction,
                  onAction: () => state.setHistoryFilter(null),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _visible.length,
                  itemBuilder: (context, i) => RepaintBoundary(
                    child: _HistoryRow(entry: _visible[i], meal: widget.meal),
                  ),
                ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.meal});
  final HistoryEntry entry;
  final MealType meal;

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
              _HistoryQuickAddButton(entry: entry, meal: meal),
            ],
          ),
          onTap: () async {
            final logged = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => FoodDetailScreen(
                  food: food,
                  meal: meal,
                  initialServings: entry.lastServings,
                ),
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

/// Logs [entry]'s last-used serving amount straight into [meal], mirroring
/// search_screen.dart's own _QuickAddButton (same haptic + undo-snackbar
/// pattern), just against a remembered serving instead of a flat 1.0.
class _HistoryQuickAddButton extends StatelessWidget {
  const _HistoryQuickAddButton({required this.entry, required this.meal});
  final HistoryEntry entry;
  final MealType meal;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _quickAdd(context, state),
        child: RoundIconButton(
          bg: c.plusIdleBg,
          icon: Icons.add,
          iconColor: c.plusIdleIcon,
        ),
      ),
    );
  }

  Future<void> _quickAdd(BuildContext context, AppState state) async {
    final l = state.l;
    HapticFeedback.lightImpact();
    final date = state.selectedDate;
    final food = entry.food;
    final servings = entry.lastServings;
    final ok = await state.addEntry(date, food.id, servings, meal);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l.saveFailed)));
      return;
    }
    final kcal = food.kcal * servings;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${l.added}: ${l.foodName(food)} · ${fmtInt(kcal)} ${l.kcal}',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () async {
            final match = state
                .entriesFor(date, meal: meal)
                .lastWhere(
                  (e) => e.foodId == food.id && e.servings == servings,
                );
            await state.removeEntry(date, match.id);
          },
        ),
      ),
    );
  }
}
