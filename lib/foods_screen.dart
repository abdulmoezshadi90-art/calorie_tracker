import 'package:flutter/material.dart';

import 'app_state.dart';
import 'food_db.dart';
import 'models.dart';
import 'search_screen.dart' show showAddFoodSheet;
import 'theme.dart';

/// Read-only browser over the food database, grouped by category. Tapping
/// a food picks a meal, then opens the shared add sheet — browsing turns
/// into logging in one tap. No new data model; a pure view over food_db.
class FoodsScreen extends StatelessWidget {
  const FoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Text(l.foods),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            for (final food in foodDatabase)
              if (food.category == category) _FoodRow(food: food),
            const SizedBox(height: 8),
          ],
        ],
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
          subtitle: Row(
            children: [
              Flexible(
                child: Text(
                  l.servingLabel(food),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ),
              // Approximate marker until values are verified (decision 8).
              if (!food.verified) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.chipBg,
                    borderRadius: BorderRadius.circular(6),
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
              ],
            ],
          ),
          trailing: Text(
            '${fmtInt(food.kcal)} ${l.kcal}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.protein,
            ),
          ),
          onTap: () => _pickMealThenAdd(context, state),
        ),
      ),
    );
  }

  void _pickMealThenAdd(BuildContext context, AppState state) {
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
                  showAddFoodSheet(context, food, meal);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
