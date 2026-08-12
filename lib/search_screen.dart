import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'copy_meal_sheet.dart';
import 'create_meal_screen.dart';
import 'food_detail_screen.dart';
import 'food_picker.dart';
import 'models.dart';
import 'saved_meals_tab.dart';
import 'theme.dart';

/// Log-flow food selection screen: search bar + All Foods/History/My Meals
/// tabs (food_picker.dart), pushed from a meal row or the add FAB. Picking a
/// food pushes the food detail screen so the user can confirm quantity;
/// picking a saved meal opens its "add all" detail sheet. Quick-add (the
/// plus button) skips that step and logs directly with an undo snackbar —
/// local-only storage has no server backup for a mis-tap.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, required this.meal});
  final MealType meal;

  Future<void> _openDetail(
    BuildContext context,
    FoodItem food,
    double servings,
  ) async {
    final logged = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            FoodDetailScreen(food: food, meal: meal, initialServings: servings),
      ),
    );
    // Search is itself a pushed route; when the detail page reports a
    // successful log, also close search so the user lands back on Home.
    if (logged == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _quickAdd(
    BuildContext context,
    AppState state,
    FoodItem food,
    double servings,
  ) async {
    final l = state.l;
    HapticFeedback.lightImpact();
    final date = state.selectedDate;
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
                  (e) => e.foodId == food.id && e.quantity == servings,
                );
            await state.removeEntry(date, match.id);
          },
        ),
      ),
    );
  }

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
        title: Text('${l.add} · ${l.mealName(meal)}'),
      ),
      body: FoodPicker(
        onFoodTap: (food, servings) => _openDetail(context, food, servings),
        onFoodQuickAdd: (food, servings) =>
            _quickAdd(context, state, food, servings),
        onMealTap: (saved) => showSavedMealDetailSheet(
          context: context,
          meal: saved,
          targetMeal: meal,
        ),
        onMealQuickAdd: (saved) => logSavedMealWithConfirmation(
          context: context,
          state: state,
          meal: saved,
          targetMeal: meal,
        ),
        onCreateMeal: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CreateMealScreen())),
        onCopyPreviousMeal: () =>
            showCopyMealSheet(context: context, targetMeal: meal),
      ),
    );
  }
}
