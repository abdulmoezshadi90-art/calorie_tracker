import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'app_state.dart';
import 'empty_state.dart';
import 'food_db.dart';
import 'models.dart';
import 'theme.dart';
import 'weight_log.dart';

/// Progress: weight trend on top, the 7-day calorie bar chart in the
/// middle, and the day-history list below. Merges what was the History
/// tab. Neutral presentation throughout (no alarm styling by design).
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final dates = state.loggedDates();
    final weights = state.weightEntries();

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Text(l.progress),
        actions: [
          IconButton(
            tooltip: l.logWeight,
            icon: const Icon(Icons.add),
            onPressed: () => showLogWeightSheet(context, state),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WeightChartCard(weights: weights),
          const _WeekChartCard(),
          if (dates.isEmpty)
            // No history yet: illustration + text (state-handling pass).
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: EmptyState(
                icon: Icons.calendar_month_outlined,
                line: l.historyEmpty,
                hint: l.historyEmptyHint,
                actionLabel: l.backToToday,
                onAction: () {
                  final tabs = AppTabs.maybeOf(context);
                  if (tabs != null) {
                    tabs.select(0);
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            )
          else
            for (final date in dates) _DayTile(date: date),
        ],
      ),
    );
  }
}

// ─────────────────────────── Weight trend ───────────────────────────

class _WeightChartCard extends StatelessWidget {
  const _WeightChartCard({required this.weights});
  final List<({DateTime date, double kg})> weights;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.weightTrend} (${l.kg})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (weights.isEmpty)
            // No weight yet: illustration + text, with a log action.
            EmptyState(
              icon: Icons.monitor_weight_outlined,
              line: l.weightEmptyLine,
              hint: l.weightEmptyHint,
              actionLabel: l.logWeight,
              onAction: () => showLogWeightSheet(context, state),
            )
          else ...[
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Semantics(
                label:
                    '${l.weightTrend}: '
                    '${[for (final w in weights) '${w.date.day}: ${_fmt(w.kg)}'].join(', ')}',
                child: CustomPaint(
                  painter: WeightLineChartPainter(
                    kgs: [for (final w in weights) w.kg],
                    isRtl: l.isAr,
                    lineColor: c.accent,
                    dotColor: c.accent,
                    trackColor: c.macroTrack,
                    labelColor: c.muted,
                  ),
                ),
              ),
            ),
            // A single point can't show a trend — say so, don't fake a line.
            if (weights.length == 1) ...[
              const SizedBox(height: 8),
              Text(
                l.weightTrendHint,
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// Line chart of weight over time. One point → a centered dot; two+ →
/// a connected line with dots. Y auto-scales to the data with padding.
/// Mirrors in RTL (oldest on the right, like the calorie bars).
class WeightLineChartPainter extends CustomPainter {
  WeightLineChartPainter({
    required this.kgs,
    required this.isRtl,
    required this.lineColor,
    required this.dotColor,
    required this.trackColor,
    required this.labelColor,
  });

  final List<double> kgs;
  final bool isRtl;
  final Color lineColor;
  final Color dotColor;
  final Color trackColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final n = kgs.length;
    if (n == 0) return;

    final minKg = kgs.reduce((a, b) => a < b ? a : b);
    final maxKg = kgs.reduce((a, b) => a > b ? a : b);
    // Pad the range so flat/near-flat data isn't a line on the edge.
    final span = (maxKg - minKg).abs();
    final pad = span < 1 ? 2.0 : span * 0.25;
    final lo = minKg - pad;
    final hi = maxKg + pad;

    double yFor(double kg) =>
        size.height - ((kg - lo) / (hi - lo)) * size.height;
    double xFor(int i) {
      if (n == 1) return size.width / 2;
      final t = i / (n - 1);
      return isRtl ? size.width * (1 - t) : size.width * t;
    }

    // Baseline track.
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      Paint()
        ..color = trackColor
        ..strokeWidth = 1,
    );

    if (n >= 2) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = Offset(xFor(i), yFor(kgs[i]));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final dot = Paint()..color = dotColor;
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(Offset(xFor(i), yFor(kgs[i])), n == 1 ? 5 : 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(WeightLineChartPainter old) =>
      old.kgs.toString() != kgs.toString() || old.isRtl != isRtl;
}

// ──────────────────── 7-day calorie bar chart ────────────────────

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
            child: Semantics(
              label:
                  '${l.last7Days}: '
                  '${[for (final d in days) '${d.day}: ${fmtInt(state.totalsFor(d).kcal.round())} ${l.kcal}'].join(', ')}',
              child: CustomPaint(
                painter: WeekBarChartPainter(
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
    final rawMax = [
      goal * 1.2,
      ...kcals.map((k) => k.toDouble()),
    ].reduce((a, b) => a > b ? a : b);
    // A non-positive goal with nothing logged has no meaningful scale to
    // draw against (rawMax collapses to exactly 0) — floor it so bars and
    // the goal line still render instead of dividing by zero into NaN.
    final maxValue = rawMax > 0 ? rawMax : 1.0;

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
          style: TextStyle(
            fontSize: 11,
            color: labelColor,
            fontFamily: 'Roboto',
            fontFamilyFallback: const ['SegoeUI'],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + (barWidth - tp.width) / 2, chartHeight + 4));
    }

    // A non-positive goal isn't a real target — nothing meaningful to mark.
    if (goal <= 0) return;
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

// ─────────────────────────── Day history ───────────────────────────

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
                    color: c.kcalAccent,
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
              MealIcon(meal, size: 18, color: c.mealIconColor),
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
                          color: c.kcalAccent,
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
