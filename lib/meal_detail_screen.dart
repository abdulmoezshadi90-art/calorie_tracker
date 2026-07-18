import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'empty_state.dart';
import 'food_db.dart';
import 'models.dart';
import 'search_screen.dart';
import 'theme.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key, required this.meal});
  final MealType meal;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final entries = state.entriesFor(state.selectedDate, meal: meal);
    final totalKcal = entries.fold<double>(
      0,
      (sum, e) => sum + (foodById[e.foodId]?.kcal ?? 0) * e.servings,
    );

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Row(
          children: [
            MealIcon(meal, size: 22),
            const SizedBox(width: 10),
            Text(l.mealName(meal)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => SearchScreen(meal: meal))),
        child: const Icon(Icons.add),
      ),
      body: entries.isEmpty
          ? EmptyState(
              graphic: MealIcon(meal, size: 30, color: c.accent),
              line: l.notLoggedYet,
              actionLabel: l.addFood,
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SearchScreen(meal: meal)),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      final food = foodById[entry.foodId];
                      if (food == null) return const SizedBox.shrink();
                      final kcal = (food.kcal * entry.servings).round();
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
                              '${fmtServings(entry.servings)} × ${l.servingLabel(food)}',
                              style: TextStyle(fontSize: 12, color: c.muted),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${fmtInt(kcal)} ${l.kcal}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: c.protein,
                                  ),
                                ),
                                IconButton(
                                  tooltip: l.delete,
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: c.muted,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    state.removeEntry(
                                      state.selectedDate,
                                      entry.id,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.total,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          '${fmtInt(totalKcal)} ${l.kcal}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: c.protein,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
