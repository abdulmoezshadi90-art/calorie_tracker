import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'theme.dart';

/// Bottom sheet listing the last 14 days that have at least one logged
/// entry, newest first, each with one row per meal that has entries.
/// Tapping a meal row copies every entry from it into today's
/// [targetMeal], preserving serving amounts, then closes the sheet — the
/// source day is never mutated.
void showCopyMealSheet({
  required BuildContext context,
  required MealType targetMeal,
}) {
  final c = AppColors.of(context);
  final state = AppScope.of(context);
  final l = state.l;
  final days = state.loggedDates().take(14).toList();

  showModalBottomSheet(
    context: context,
    backgroundColor: c.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l.copyMealSheetTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
              ),
            ),
            if (days.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(
                  l.noPreviousMeals,
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    for (final day in days)
                      _DaySection(day: day, targetMeal: targetMeal),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.targetMeal});
  final DateTime day;
  final MealType targetMeal;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    final l = state.l;
    final mealsWithEntries = [
      for (final m in MealType.values)
        if (state.entriesFor(day, meal: m).isNotEmpty) m,
    ];
    if (mealsWithEntries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.dateLine(day),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 6),
          for (final m in mealsWithEntries)
            _CopyMealRow(day: day, sourceMeal: m, targetMeal: targetMeal),
        ],
      ),
    );
  }
}

class _CopyMealRow extends StatelessWidget {
  const _CopyMealRow({
    required this.day,
    required this.sourceMeal,
    required this.targetMeal,
  });
  final DateTime day;
  final MealType sourceMeal;
  final MealType targetMeal;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    final l = state.l;
    final entries = state.entriesFor(day, meal: sourceMeal);
    final kcal = entries.fold<double>(
      0,
      (sum, e) => sum + (state.resolveFood(e.foodId)?.kcal ?? 0) * e.servings,
    );

    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _copy(context, state),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.mealTint[sourceMeal],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: MealIcon(sourceMeal, color: c.mealIconColor, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.mealName(sourceMeal),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      '${l.foodsCount(entries.length)} · ${fmtInt(kcal)} ${l.kcal}',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, AppState state) async {
    final l = state.l;
    final today = state.selectedDate;
    final addedIds = await state.copyMealEntries(
      day,
      sourceMeal,
      today,
      targetMeal,
    );
    if (!context.mounted) return;
    Navigator.of(context).pop();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    if (addedIds == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.saveFailed)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.mealCopied),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () => state.removeEntries(today, addedIds),
        ),
      ),
    );
  }
}
