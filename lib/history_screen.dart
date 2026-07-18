import 'package:flutter/material.dart';

import 'app_state.dart';
import 'empty_state.dart';
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
          ? EmptyState(
              icon: Icons.calendar_month_outlined,
              line: l.historyEmpty,
              hint: l.historyEmptyHint,
              actionLabel: l.backToToday,
              onAction: () => Navigator.of(context).pop(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dates.length + 1,
              itemBuilder: (context, i) => i == 0
                  ? const _WeekChartCard()
                  : _DayTile(date: dates[i - 1]),
            ),
    );
  }
}

/// Calorie bar chart of the last 7 days (ending today), drawn by hand —
/// no charting package by design.
class _WeekChartCard extends StatelessWidget {
  const _WeekChartCard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final now = state.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.last7Days,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: WeekBarChartPainter(
                // Painter draws start-to-end; pass days in reading order so
                // RTL shows the oldest day on the right.
                kcals: [
                  for (final d in days) state.totalsFor(d).kcal.round(),
                ],
                labels: [for (final d in days) '${d.day}'],
                goal: state.goals.kcal,
                isRtl: l.isAr,
                barColor: c.accent,
                overColor: c.gold,
                trackColor: c.macroTrack,
                goalLineColor: c.muted,
                labelColor: c.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints up to [kcals.length] rounded bars with day-of-month labels and a
/// dashed goal line. Over-goal bars use [overColor] (gold, never alarm red).
class WeekBarChartPainter extends CustomPainter {
  WeekBarChartPainter({
    required this.kcals,
    required this.labels,
    required this.goal,
    required this.isRtl,
    required this.barColor,
    required this.overColor,
    required this.trackColor,
    required this.goalLineColor,
    required this.labelColor,
  });

  final List<int> kcals;
  final List<String> labels;
  final int goal;
  final bool isRtl;
  final Color barColor;
  final Color overColor;
  final Color trackColor;
  final Color goalLineColor;
  final Color labelColor;

  static const _labelHeight = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final n = kcals.length;
    if (n == 0) return;
    final chartHeight = size.height - _labelHeight;
    final slot = size.width / n;
    final barWidth = slot * 0.5;
    // Headroom above the goal line so typical days don't hit the ceiling.
    final maxValue = [
      goal * 1.2,
      ...kcals.map((k) => k.toDouble()),
    ].reduce((a, b) => a > b ? a : b);

    double xFor(int i) {
      final slotIndex = isRtl ? n - 1 - i : i;
      return slotIndex * slot + (slot - barWidth) / 2;
    }

    final track = Paint()..color = trackColor;
    for (var i = 0; i < n; i++) {
      final x = xFor(i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barWidth, chartHeight),
          const Radius.circular(6),
        ),
        track,
      );
      if (kcals[i] > 0) {
        final h = (kcals[i] / maxValue) * chartHeight;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, chartHeight - h, barWidth, h),
            const Radius.circular(6),
          ),
          Paint()..color = kcals[i] > goal ? overColor : barColor,
        );
      }
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          // Raw TextPainter skips the theme; name the family so golden
          // tests resolve the loaded Roboto instead of the box font.
          style: TextStyle(
            fontSize: 11,
            color: labelColor,
            fontFamily: 'Roboto',
            fontFamilyFallback: const ['SegoeUI'],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x + (barWidth - tp.width) / 2, chartHeight + 4),
      );
    }

    // Dashed goal line.
    final goalY = chartHeight - (goal / maxValue) * chartHeight;
    final dash = Paint()
      ..color = goalLineColor
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, goalY), Offset(x + 4, goalY), dash);
    }
  }

  @override
  bool shouldRepaint(WeekBarChartPainter old) =>
      old.kcals.toString() != kcals.toString() ||
      old.goal != goal ||
      old.isRtl != isRtl;
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
