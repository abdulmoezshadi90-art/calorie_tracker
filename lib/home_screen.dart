import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'history_screen.dart';
import 'l10n.dart';
import 'meal_detail_screen.dart';
import 'models.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final date = state.selectedDate;
    final totals = state.totalsFor(date);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _Header(),
            // Pull the content up so the first card overlaps the header base.
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                child: Column(
                  children: [
                    _CalorieCard(totals: totals),
                    const SizedBox(height: 14),
                    _MacroCard(totals: totals),
                    const SizedBox(height: 24),
                    const _MealsHeader(),
                    const SizedBox(height: 4),
                    if (state.loggedMealCount(date) == 0)
                      const _EmptyTodayBanner(),
                    _MealsList(totals: totals),
                    const SizedBox(height: 14),
                    const _AddMealButton(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── Header ───────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.headerTop, c.headerBottom],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: _blob(190, c.headerBlob.withValues(alpha: 0.55)),
            ),
            Positioned(
              bottom: -70,
              left: -30,
              child: _blob(220, c.headerBlob.withValues(alpha: 0.35)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _TopRow(),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_DatePill(), _HistoryButton()],
                  ),
                  SizedBox(height: 18),
                  _WeekStrip(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _TopRow extends StatelessWidget {
  const _TopRow();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final greeting = l.greeting(state.now().hour);
    final hasName = state.userName.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasName) ...[
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        greeting,
                        style: TextStyle(
                          color: c.onHeader.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('🌿', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  state.userName,
                  style: TextStyle(
                    color: c.onHeader,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ] else
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        greeting.replaceAll(RegExp(r'[,،]\s*$'), ''),
                        style: TextStyle(
                          color: c.onHeader,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🌿', style: TextStyle(fontSize: 20)),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _SettingsButton(),
        const SizedBox(width: 8),
        const _LangToggle(),
        const SizedBox(width: 8),
        const _TodayPill(),
      ],
    );
  }
}

/// Circular header button: 44px touch target, ink ripple, tooltip
/// (ui-ux-pro-max polish pass — was a 40px GestureDetector with neither).
class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.dayIdleBg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            width: 44,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _HistoryButton extends StatelessWidget {
  const _HistoryButton();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    return _HeaderCircleButton(
      tooltip: state.l.history,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
      ),
      child: Icon(Icons.history, color: c.onHeader, size: 20),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    return _HeaderCircleButton(
      tooltip: state.l.settings,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      ),
      child: Icon(Icons.settings_outlined, color: c.onHeader, size: 20),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    return _HeaderCircleButton(
      tooltip: state.l.language,
      onTap: state.toggleLocale,
      child: Text(
        state.l.toggleLabel,
        style: TextStyle(
          color: c.onHeader,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  const _TodayPill();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    return Material(
      color: c.dayIdleBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => state.selectDate(state.now()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.l.today,
              style: TextStyle(
                color: c.onHeader,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: c.onHeader, size: 18),
          ],
          ),
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = state.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday-first week containing today (weekday: Mon=1 … Sun=7).
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: _DayChip(
              day: monday.add(Duration(days: i)),
              today: today,
              selected: state.selectedDate,
            ),
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.today,
    required this.selected,
  });
  final DateTime day;
  final DateTime today;
  final DateTime selected;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final isSelected = AppState.dateKey(day) == AppState.dateKey(selected);
    final isFuture = day.isAfter(today);

    return GestureDetector(
      onTap: () => state.selectDate(day),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: state.l.dateLine(day),
        child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 3,
          vertical: isSelected ? 0 : 6,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? c.daySelectedBg : c.dayIdleBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.daySelectedBg.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              state.l.dayShort(day),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? c.daySelectedText
                    : c.dayIdleText.withValues(alpha: isFuture ? 0.5 : 0.85),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? c.daySelectedText
                    : c.onHeader.withValues(alpha: isFuture ? 0.5 : 1),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: c.dayIdleBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        state.l.dateLine(state.selectedDate),
        style: TextStyle(color: c.onHeader, fontSize: 13.5),
      ),
    );
  }
}

// ─────────────────────────── Calorie card ───────────────────────────

class _CalorieCard extends StatelessWidget {
  const _CalorieCard({required this.totals});
  final DayTotals totals;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    final l = state.l;
    final consumed = totals.kcal.round();
    final goal = state.goals.kcal;
    final progress = (totals.kcal / goal).clamp(0.0, 1.0);
    final remaining = goal - consumed;

    return _Card(
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.caloriesToday,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 8),
          // One line: big number, goal, remaining-pill. Scaled as a unit so
          // long localized strings can never overflow the card.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    text: fmtInt(consumed),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: c.inkStrong,
                      height: 1,
                    ),
                    children: [
                      TextSpan(
                        text: '  ${l.ofGoalKcal(goal)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _LeftPill(remaining: remaining),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProgressBar(progress: progress),
        ],
      ),
    );
  }
}

class _LeftPill extends StatelessWidget {
  const _LeftPill({required this.remaining});
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppScope.of(context).l;
    final over = remaining < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.leftPillBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c.gold, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            over ? l.kcalOverToday(-remaining) : l.kcalLeftToday(remaining),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: over ? c.fat : c.leftPillText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Stack(
          children: [
            Container(color: c.progressTrack),
            FractionallySizedBox(
              widthFactor: progress == 0 ? 0.001 : progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [c.progressStart, c.progressEnd],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── Macro card ────────────────────────────

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.totals});
  final DayTotals totals;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    final l = state.l;
    final goals = state.goals;
    return _Card(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _macroCol(
              c,
              l,
              l.carb,
              totals.carbs,
              goals.carbs.toDouble(),
              c.carb,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _macroCol(c, l, l.fat, totals.fat, goals.fat.toDouble(), c.fat),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _macroCol(
              c,
              l,
              l.protein,
              totals.protein,
              goals.protein.toDouble(),
              c.protein,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroCol(
    AppColors c,
    L10n l,
    String label,
    double value,
    double goal,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.muted,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text.rich(
            TextSpan(
              text: fmtGrams(value),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.ink,
              ),
              children: [
                TextSpan(
                  text: ' / ${fmtGrams(goal)} ${l.grams}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _MiniBar(progress: (value / goal).clamp(0.0, 1.0), color: color),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Container(color: c.macroTrack),
            FractionallySizedBox(
              widthFactor: progress == 0 ? 0.001 : progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── Meals ──────────────────────────────

class _MealsHeader extends StatelessWidget {
  const _MealsHeader();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final done = state.loggedMealCount(state.selectedDate);

    return Row(
      children: [
        Text(
          l.meals,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: c.ink,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: c.chipBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            l.mealCountOf(done, MealType.values.length),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.chipText,
            ),
          ),
        ),
      ],
    );
  }
}

class _MealsList extends StatelessWidget {
  const _MealsList({required this.totals});
  final DayTotals totals;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final meals = MealType.values;
    return Column(
      children: [
        for (var i = 0; i < meals.length; i++) ...[
          _MealRow(meal: meals[i], totals: totals),
          if (i != meals.length - 1) _DashedDivider(color: c.divider),
        ],
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal, required this.totals});
  final MealType meal;
  final DayTotals totals;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final foods = state.foodsFor(state.selectedDate, meal);
    final logged = foods.isNotEmpty;
    final kc = totals.kcalPerMeal[meal.name] ?? 0;
    final subtitle = logged ? l.joinFoods(foods) : l.notLoggedYet;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.mealTint[meal],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: MealIcon(meal, color: c.mealIconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l.mealName(meal),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      if (logged) ...[
                        const SizedBox(width: 8),
                        Text(
                          l.kcalAmount(kc),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.protein,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (logged)
              _RoundBtn(bg: c.accent, icon: Icons.check, iconColor: c.onAccent)
            else
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SearchScreen(meal: meal)),
                ),
                child: _RoundBtn(
                  bg: c.plusIdleBg,
                  icon: Icons.add,
                  iconColor: c.plusIdleIcon,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.bg,
    required this.icon,
    required this.iconColor,
  });
  final Color bg;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}

/// Friendly banner when nothing is logged on the selected day; tapping it
/// opens the same meal chooser as the add button.
class _EmptyTodayBanner extends StatelessWidget {
  const _EmptyTodayBanner();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Material(
        color: c.chipBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _chooseMeal(context, state),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.restaurant_outlined, size: 20, color: c.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.emptyTodayLine,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        l.emptyTodayAction,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline, size: 20, color: c.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddMealButton extends StatelessWidget {
  const _AddMealButton();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;

    return GestureDetector(
      onTap: () => _chooseMeal(context, state),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: c.divider, radius: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: c.onAccent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                l.addMeal,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet asking which meal to add to; shared by the add-meal button
/// and the empty-today banner.
void _chooseMeal(BuildContext context, AppState state) {
    final c = AppColors.of(context);
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
            for (final m in MealType.values)
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.mealTint[m],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: MealIcon(m, color: c.mealIconColor, size: 20),
                  ),
                ),
                title: Text(
                  l.mealName(m),
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SearchScreen(meal: m)),
                  );
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
}

// ───────────────────────── Shared building blocks ─────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child, this.radius = 20, this.padding});
  final Widget child;
  final double radius;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: c.cardShadow,
      ),
      child: child,
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.4,
      width: double.infinity,
      child: CustomPaint(painter: _DashLinePainter(color)),
    );
  }
}

class _DashLinePainter extends CustomPainter {
  _DashLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    const dash = 5.0, gap = 5.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashLinePainter old) => old.color != color;
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 7.0, gap = 6.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final len = math.min(dash, metric.length - dist);
        canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
