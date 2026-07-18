import 'package:flutter/material.dart';

import 'app_state.dart';
import 'food_db.dart';
import 'models.dart';
import 'theme.dart';

/// Scrollable list of past logged days. Tapping a day opens a read-only
/// view of what was logged. Goal wording stays neutral by design.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final dates = state.loggedDates();

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Text(l.history),
      ),
      body: dates.isEmpty
          ? Center(
              child: Text(l.historyEmpty, style: TextStyle(color: c.muted)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dates.length,
              itemBuilder: (context, i) => _DayTile(date: dates[i]),
            ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final kcal = state.totalsFor(date).kcal.round();
    final over = kcal > state.goals.kcal;

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            '${l.dateLine(date)} · ${date.year}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
          subtitle: Text(
            '${fmtInt(kcal)} / ${fmtInt(state.goals.kcal)} ${l.kcal}',
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              // Gold for over, green-tint for within: informative, never
              // alarming (anti-ED design decision).
              color: over ? c.gold.withValues(alpha: 0.25) : c.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              over ? l.overGoal : l.withinGoal,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.chipText,
              ),
            ),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => DayViewScreen(date: date)),
          ),
        ),
      ),
    );
  }
}

/// Read-only view of one past day: per-meal foods and the day total.
class DayViewScreen extends StatelessWidget {
  const DayViewScreen({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final totals = state.totalsFor(date);

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Text('${l.dateLine(date)} · ${date.year}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final meal in MealType.values)
            if (state.entriesFor(date, meal: meal).isNotEmpty)
              _MealSection(date: date, meal: meal),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  '${fmtInt(totals.kcal)} ${l.kcal}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.protein,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({required this.date, required this.meal});
  final DateTime date;
  final MealType meal;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final entries = state.entriesFor(date, meal: meal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: [
              Icon(meal.icon, size: 18, color: c.mealIconColor),
              const SizedBox(width: 8),
              Text(
                l.mealName(meal),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: c.cardShadow,
          ),
          child: Material(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                for (final entry in entries)
                  if (foodById[entry.foodId] != null)
                    ListTile(
                      dense: true,
                      title: Text(
                        l.foodName(foodById[entry.foodId]!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      subtitle: Text(
                        '${fmtServings(entry.servings)} × ${l.servingLabel(foodById[entry.foodId]!)}',
                        style: TextStyle(fontSize: 11, color: c.muted),
                      ),
                      trailing: Text(
                        '${fmtInt((foodById[entry.foodId]!.kcal * entry.servings).round())} ${l.kcal}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.protein,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
