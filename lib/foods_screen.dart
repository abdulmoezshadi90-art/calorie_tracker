import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'food_detail_screen.dart';
import 'models.dart';
import 'round_icon_button.dart';
import 'theme.dart';

/// Read-only browser over every food (food_db.dart plus any custom foods
/// the user has added), grouped by category — custom foods land in their
/// own "My Foods" bucket (FoodCategory.custom). Tapping a food picks a
/// meal, then opens the food detail page — browsing turns into logging in
/// one tap. No new data model here; editing/deleting a custom food lives
/// on the All Foods tab (all_foods_tab.dart), where it was created.
class FoodsScreen extends StatelessWidget {
  const FoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;

    // Category headers/spacers are pre-built (cheap, ~9 of them); food rows
    // stay as data and are built lazily in itemBuilder via ListView.builder,
    // matching the pattern every other list screen in the app already uses.
    final rows = <Object>[
      for (final category in FoodCategory.values) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            l.category(category),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: c.inkStrong,
            ),
          ),
        ),
        for (final food in state.allFoods)
          if (food.category == category) food,
        const SizedBox(height: 8),
      ],
    ];

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Text(l.foods),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          return row is FoodItem ? _FoodRow(food: row) : row as Widget;
        },
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food});
  final FoodItem food;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
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
          subtitle: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              Text(
                l.servingLabel(food),
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
              // Approximate marker until values are verified (decision 8).
              // Tappable: the marker alone doesn't explain itself, so a tap
              // surfaces what "approx." actually means (see clarify pass).
              // Wrap (not Row) so the marker drops to its own line rather
              // than overflowing when the serving label is long on a
              // narrow screen — the subtitle slot has very little width
              // left once the trailing kcal/add controls claim theirs.
              if (!food.verified)
                Semantics(
                  button: true,
                  label: l.approxMarkerExplanation,
                  child: Material(
                    color: c.chipBg,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.approxMarkerExplanation)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Text(
                          l.approxMarker,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: c.chipText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _pickMealThenQuickAdd(context, state),
                  child: RoundIconButton(
                    bg: c.plusIdleBg,
                    icon: Icons.add,
                    iconColor: c.plusIdleIcon,
                  ),
                ),
              ),
            ],
          ),
          onTap: () => _pickMealThenOpenDetail(context),
        ),
      ),
    );
  }

  void _pickMealThenOpenDetail(BuildContext context) {
    _showMealChooser(
      context,
      onPicked: (meal) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FoodDetailScreen(food: food, meal: meal),
        ),
      ),
    );
  }

  void _pickMealThenQuickAdd(BuildContext context, AppState state) {
    _showMealChooser(
      context,
      onPicked: (meal) async {
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
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${l.added}: ${l.foodName(food)} · ${fmtInt(food.kcal)} ${l.kcal}',
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: l.undo,
              onPressed: () async {
                final match = state
                    .entriesFor(date, meal: meal)
                    .lastWhere((e) => e.foodId == food.id && e.quantity == 1.0);
                await state.removeEntry(date, match.id);
              },
            ),
          ),
        );
      },
    );
  }

  void _showMealChooser(
    BuildContext context, {
    required void Function(MealType meal) onPicked,
  }) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l.chooseMeal,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
              ),
            ),
            for (final meal in MealType.values)
              ListTile(
                leading: MealIcon(meal, size: 22, color: c.mealIconColor),
                title: Text(
                  l.mealName(meal),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onPicked(meal);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
