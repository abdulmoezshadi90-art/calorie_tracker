import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'copy_meal_sheet.dart';
import 'create_meal_screen.dart';
import 'empty_state.dart';
import 'filter_sort_sheet.dart';
import 'food_db.dart';
import 'models.dart';
import 'round_icon_button.dart';
import 'theme.dart';

double _totalKcal(SavedMeal meal) => meal.items.fold(
  0.0,
  (sum, item) => sum + (foodById[item.foodId]?.kcal ?? 0) * item.servings,
);

/// My Meals tab content (search_screen.dart's tab selector, tab 2):
/// user-saved food combos, logged again with one tap. Same
/// compute-outside-build, listener-driven recompute idiom as
/// food_history_tab.dart's HistoryTab.
class MyMealsTab extends StatefulWidget {
  const MyMealsTab({super.key, required this.meal});
  final MealType meal;

  @override
  State<MyMealsTab> createState() => _MyMealsTabState();
}

class _MyMealsTabState extends State<MyMealsTab> {
  List<SavedMeal> _visible = const [];
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
    final filter = state.mealsFilter;
    var meals = [
      for (final m in state.savedMeals)
        if (filter == null || m.mealType == filter) m,
    ];
    switch (state.mealsSort) {
      case SortOption.mostRecent:
        meals.sort(
          (a, b) => (b.lastUsedAt ?? b.createdAt).compareTo(
            a.lastUsedAt ?? a.createdAt,
          ),
        );
      case SortOption.mostFrequent:
        meals.sort((a, b) {
          final byCount = b.useCount.compareTo(a.useCount);
          return byCount != 0
              ? byCount
              : (b.lastUsedAt ?? b.createdAt).compareTo(
                  a.lastUsedAt ?? a.createdAt,
                );
        });
      case SortOption.aToZ:
        // A single user-typed name, no EN/AR pair (unlike FoodItem) — see
        // SavedMeal's own doc comment — so there is nothing locale-specific
        // to switch on here.
        meals.sort((a, b) => a.name.compareTo(b.name));
      case SortOption.zToA:
        meals.sort((a, b) => b.name.compareTo(a.name));
    }
    if (!mounted) {
      _visible = meals;
      return;
    }
    setState(() => _visible = meals);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final hasAnySaved = state.savedMeals.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_circle_outline,
                  label: l.createMealAction,
                  onTap: () async {
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => const CreateMealScreen(),
                      ),
                    );
                    if (saved == true) _recompute();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.content_copy_outlined,
                  label: l.copyPreviousMealAction,
                  onTap: () => showCopyMealSheet(
                    context: context,
                    targetMeal: widget.meal,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Text(
            l.myMeals,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
        ),
        if (!hasAnySaved)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              l.myMealsEmptyLine,
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
          )
        else ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilterSortRow(
              filter: state.mealsFilter,
              sort: state.mealsSort,
              onFilterChanged: (f) => state.setMealsFilter(f),
              onSortChanged: (s) => state.setMealsSort(s),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: !hasAnySaved
              ? const SizedBox.shrink()
              : _visible.isEmpty
              ? EmptyState(
                  icon: Icons.filter_list_off,
                  line: l.noFilterMatchLine,
                  actionLabel: l.clearFilterAction,
                  onAction: () => state.setMealsFilter(null),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _visible.length,
                  itemBuilder: (context, i) => RepaintBoundary(
                    child: _SavedMealRow(
                      meal: _visible[i],
                      targetMeal: widget.meal,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.chipBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: c.accent, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _SavedMealRow extends StatelessWidget {
  const _SavedMealRow({required this.meal, required this.targetMeal});
  final SavedMeal meal;
  final MealType targetMeal;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    final l = state.l;
    final kcal = _totalKcal(meal);

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
          onTap: () => showSavedMealDetailSheet(
            context: context,
            meal: meal,
            targetMeal: targetMeal,
          ),
          onLongPress: () =>
              showSavedMealOptionsSheet(context: context, meal: meal),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${l.foodsCount(meal.items.length)} · ${fmtInt(kcal)} ${l.kcal}',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => logSavedMealWithConfirmation(
                      context: context,
                      state: state,
                      meal: meal,
                      targetMeal: targetMeal,
                    ),
                    child: RoundIconButton(
                      bg: c.plusIdleBg,
                      icon: Icons.add,
                      iconColor: c.plusIdleIcon,
                    ),
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

/// Logs every food in [meal] into [state.selectedDate]/[targetMeal] at
/// once, then shows a confirmation with undo — same haptic + snackbar
/// pattern as every other add/delete in this app (local storage has no
/// backup for a mis-tap). Shared by the row's quick-add button and the
/// detail sheet's "Add all" button.
Future<void> logSavedMealWithConfirmation({
  required BuildContext context,
  required AppState state,
  required SavedMeal meal,
  required MealType targetMeal,
}) async {
  final l = state.l;
  HapticFeedback.lightImpact();
  final date = state.selectedDate;
  final addedIds = await state.logSavedMeal(date, targetMeal, meal);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  if (addedIds == null) {
    messenger.showSnackBar(SnackBar(content: Text(l.saveFailed)));
    return;
  }
  final kcal = _totalKcal(meal);
  messenger.showSnackBar(
    SnackBar(
      content: Text('${l.added}: ${meal.name} · ${fmtInt(kcal)} ${l.kcal}'),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: l.undo,
        onPressed: () => state.removeEntries(date, addedIds),
      ),
    ),
  );
}

/// Lists every food/serving in [meal] with an "Add all" button at the
/// bottom — tapping a saved meal row.
void showSavedMealDetailSheet({
  required BuildContext context,
  required SavedMeal meal,
  required MealType targetMeal,
}) {
  final c = AppColors.of(context);
  final state = AppScope.of(context);
  final l = state.l;
  showModalBottomSheet(
    context: context,
    backgroundColor: c.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              meal.name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: meal.items.length,
                itemBuilder: (context, i) {
                  final item = meal.items[i];
                  final food = foodById[item.foodId];
                  if (food == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.foodName(food),
                            style: TextStyle(fontSize: 14, color: c.ink),
                          ),
                        ),
                        Text(
                          '${fmtServings(item.servings)} × ${l.servingLabel(food)}',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  logSavedMealWithConfirmation(
                    context: context,
                    state: state,
                    meal: meal,
                    targetMeal: targetMeal,
                  );
                },
                child: Text(
                  l.addAllAction,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Long-press menu: edit (pushes CreateMealScreen in edit mode) or delete
/// (with the app's standard undo-snackbar pattern).
void showSavedMealOptionsSheet({
  required BuildContext context,
  required SavedMeal meal,
}) {
  final c = AppColors.of(context);
  final state = AppScope.of(context);
  final l = state.l;
  showModalBottomSheet(
    context: context,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit_outlined, color: c.ink),
            title: Text(
              l.editAction,
              style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateMealScreen(existing: meal),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: c.fieldError),
            title: Text(
              l.delete,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: c.fieldError,
              ),
            ),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              final ok = await state.deleteSavedMeal(meal.id);
              if (!context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              messenger.clearSnackBars();
              if (!ok) {
                messenger.showSnackBar(SnackBar(content: Text(l.saveFailed)));
                return;
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l.removed),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: l.undo,
                    onPressed: () => state.addSavedMeal(meal),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
