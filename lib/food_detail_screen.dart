import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'l10n.dart';
import 'models.dart';
import 'settings_screen.dart' show WesternDigitsFormatter;
import 'theme.dart';

/// Full detail page for one food: unit + quantity picker, live macro
/// breakdown and donut chart, then log. Replaces the old add-to-meal
/// bottom sheet as the primary way to log from a food row. Constructor
/// carries no search-specific state so it can be opened from anywhere
/// (search results today; meal detail later).
///
/// Two confirm modes, exactly one applies:
/// - [meal] set, [onConfirm] null: logs to today via `AppState.addEntry`
///   (the normal log flow).
/// - [onConfirm] set: hands back the resulting base-serving multiplier
///   instead of logging anywhere, so a caller can use this same
///   unit/quantity/macros picker for a non-logging context (the meal
///   builder's draft rows, which have no date or meal-type per item).
///   The time-of-day row makes no sense without a log entry, so it's
///   hidden in this mode.
class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({
    super.key,
    required this.food,
    this.meal,
    this.initialServings,
    this.onConfirm,
  }) : assert(
         (meal == null) != (onConfirm == null),
         'Pass exactly one of meal (log to today) or onConfirm (custom save).',
       );
  final FoodItem food;
  final MealType? meal;

  /// Prefills the quantity input with this many base servings (History tab
  /// row tap, "prefilled with the serving amount last used for that food").
  /// Null keeps the normal default of 1. Always against the food's own
  /// base serving unit — [_unit] still defaults to servingUnits.first, and
  /// that unit's multiplier is 1:1 with the base serving, so this value
  /// maps straight onto [_quantity] with no conversion needed.
  final double? initialServings;

  /// See the class doc's "two confirm modes". Return true on success,
  /// mirroring `AppState.addEntry`'s bool result.
  final Future<bool> Function(double multiplier)? onConfirm;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  late ServingUnit _unit;
  late String _mode; // 'fraction' | 'decimal'
  int _whole = 1;
  int _fractionPreset = 0; // 0 = none, else index into fraction glyph table
  final _decimalController = TextEditingController(text: '1');
  String? _error;
  var _justSaved = false;
  late TimeOfDay _time;

  static const _fractionValues = {1: 0.25, 2: 1 / 3, 3: 0.5, 4: 2 / 3, 5: 0.75};

  bool get _isDraftMode => widget.onConfirm != null;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    _unit = widget.food.servingUnits.first;
    _time = TimeOfDay.fromDateTime(state.now());
    _mode = state.quantityMode == 'fraction' ? 'fraction' : 'decimal';
    final initial = widget.initialServings;
    if (initial != null && initial > 0) {
      if (_mode == 'decimal') {
        _decimalController.text = fmtServings(initial);
      } else {
        _whole = initial.floor().clamp(0, 98);
        _fractionPreset = _nearestFractionPreset(initial - _whole);
      }
    }
  }

  @override
  void dispose() {
    _decimalController.dispose();
    super.dispose();
  }

  double get _quantity {
    if (_mode == 'decimal') {
      final v = double.tryParse(_decimalController.text);
      return v ?? 0;
    }
    return _whole + (_fractionValues[_fractionPreset] ?? 0);
  }

  bool get _quantityValid => _quantity >= 0.1 && _quantity <= 99;

  double get _multiplier =>
      widget.food.multiplierFor(_unit, _quantityValid ? _quantity : 0);

  /// Carries the current quantity across a mode switch instead of resetting
  /// it — 0.5 becomes ½, and a value with no clean fraction snaps silently
  /// to the nearest chip combination (design: say nothing, just move it).
  void _switchMode(String mode, AppState state) {
    final current = _quantity; // reads via the OLD _mode, before it flips.
    setState(() {
      if (mode == 'decimal') {
        _decimalController.text = fmtServings((current * 10).round() / 10);
      } else {
        _whole = current.floor().clamp(0, 98);
        _fractionPreset = _nearestFractionPreset(current - _whole);
      }
      _mode = mode;
    });
    state.setQuantityMode(mode);
  }

  /// Nearest fraction chip (0 = none) to [frac], by absolute distance —
  /// the silent snap the task calls for when a decimal has no exact match.
  int _nearestFractionPreset(double frac) {
    var bestKey = 0;
    var bestDiff = frac.abs();
    for (final entry in _fractionValues.entries) {
      final diff = (entry.value - frac).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestKey = entry.key;
      }
    }
    return bestKey;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final food = widget.food;
    final kcal = food.kcal * _multiplier;
    final carbs = food.carbs * _multiplier;
    final fat = food.fat * _multiplier;
    final protein = food.protein * _multiplier;
    final pct = kcalPercents(carbsG: carbs, fatG: fat, proteinG: protein);

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        // Row-based, not manually mirrored — order flips for free in RTL.
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(l.foodName(food), overflow: TextOverflow.ellipsis),
            ),
            if (food.verified) ...[
              const SizedBox(width: 8),
              _VerifiedBadge(color: c.accent, onColor: c.onAccent),
            ],
          ],
        ),
      ),
      // SingleChildScrollView, not ListView: a Sliver-backed ListView only
      // mounts elements within its built extent, which can hide widgets
      // (like the error text) that appear after a scroll-position change —
      // this screen's content is short enough that eager building is fine.
      //
      // LayoutBuilder + a min-height ConstrainedBox: centers content in the
      // available viewport when it's shorter than the screen (small foods
      // with few macros) so it reads as composed rather than top-anchored
      // over empty space; content taller than the viewport (long names,
      // larger system font sizes, an error line) still scrolls normally.
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ServingRow(
                  caption: l.unit,
                  label: l.unitLabel(_unit),
                  onTap: () => _showUnitPicker(context),
                ),
                if (!_isDraftMode) ...[
                  const SizedBox(height: 20),
                  _ServingRow(
                    caption: l.time,
                    label: fmtTime(_time.hour, _time.minute),
                    onTap: () => _pickTime(context),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _sectionLabel(c, l.quantity)),
                    _ModeToggle(
                      mode: _mode,
                      fractionLabel: l.fractionMode,
                      decimalLabel: l.decimalMode,
                      onChanged: (mode) => _switchMode(mode, state),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_mode == 'fraction')
                  _FractionPicker(
                    whole: _whole,
                    fractionPreset: _fractionPreset,
                    wholeLabel: l.whole,
                    onWholeChanged: (w) => setState(() => _whole = w),
                    onFractionChanged: (f) =>
                        setState(() => _fractionPreset = f),
                  )
                else
                  _DecimalPicker(
                    controller: _decimalController,
                    onChanged: () {
                      setState(() {});
                    },
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 13, color: c.fieldError),
                  ),
                ],
                const SizedBox(height: 20),
                _MacroChipsRow(
                  carbs: carbs,
                  fat: fat,
                  protein: protein,
                  pct: pct,
                  zeroCal: kcal <= 0,
                ),
                const SizedBox(height: 20),
                _DonutCard(kcal: kcal, pct: pct),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: c.card, boxShadow: c.cardShadow),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SizedBox(
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
                onPressed: _justSaved ? () {} : () => _confirm(state, kcal),
                child: _justSaved
                    ? Icon(Icons.check, size: 22, color: c.onAccent)
                    : Text(
                        '${l.add} · ${fmtInt(kcal)} ${l.kcal}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(AppState state, double kcal) async {
    final l = state.l;
    if (!_quantityValid) {
      setState(() => _error = l.invalidQuantity);
      return;
    }
    HapticFeedback.lightImpact();
    final onConfirm = widget.onConfirm;
    final bool ok;
    if (onConfirm != null) {
      ok = await onConfirm(_multiplier);
    } else {
      final date = state.selectedDate;
      ok = await state.addEntry(
        date,
        widget.food.id,
        _multiplier,
        widget.meal!,
        unitId: _unit.id,
        quantity: _quantity,
        loggedAt: DateTime(
          date.year,
          date.month,
          date.day,
          _time.hour,
          _time.minute,
        ),
      );
    }
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = l.saveFailed);
      return;
    }
    setState(() => _justSaved = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    // Pop with a result so a caller that pushed an intermediate route (the
    // search screen) can close that too and land back on Home, matching
    // the old sheet-on-search behavior. Callers that don't care (Foods
    // tab, a persistent tab underneath) simply ignore the result.
    Navigator.of(context).pop(true);
    // The draft-meal path shows the new row in the running list right
    // behind this screen — that's feedback enough, and there's no "today"
    // for the message to reference.
    if (onConfirm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l.added}: ${l.foodName(widget.food)} · ${fmtInt(kcal)} ${l.kcal}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Widget _sectionLabel(AppColors c, String text) => Text(
    text,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink),
  );

  /// Bottom sheet listing this food's own named servings first, then the
  /// generic weight/volume units (only when the food has a servingGrams
  /// anchor to convert them through — see [FoodItem.genericUnits]).
  void _showUnitPicker(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    final l = state.l;
    final food = widget.food;
    final generic = food.genericUnits;

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
                  l.chooseUnit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _unitSection(
                      c,
                      l,
                      l.namedServingsSection,
                      food.servingUnits,
                      sheetContext,
                    ),
                    if (generic.isNotEmpty)
                      _unitSection(
                        c,
                        l,
                        food.isLiquid
                            ? l.volumeUnitsSection
                            : l.weightUnitsSection,
                        generic,
                        sheetContext,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _unitSection(
    AppColors c,
    L10n l,
    String label,
    List<ServingUnit> units,
    BuildContext sheetContext,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.muted,
            ),
          ),
        ),
        for (final u in units)
          ListTile(
            title: Text(
              l.unitLabel(u),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
            trailing: u.id == _unit.id
                ? Icon(Icons.check, color: c.accent)
                : null,
            onTap: () {
              Navigator.of(sheetContext).pop();
              setState(() => _unit = u);
            },
          ),
      ],
    );
  }
}

/// Serving row: shows the selected unit and opens the picker sheet on tap.
class _ServingRow extends StatelessWidget {
  const _ServingRow({
    required this.caption,
    required this.label,
    required this.onTap,
  });
  final String caption;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caption,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small filled checkmark next to the food name — shown only for foods the
/// owner has verified against a real product label (never for the
/// placeholder/unverified majority of food_db.dart). Tapping explains what
/// the mark means instead of leaving it as an unexplained decoration,
/// mirroring the tappable "approx." marker on the Foods list.
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.color, required this.onColor});
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final l = AppScope.of(context).l;
    return Semantics(
      button: true,
      label: l.verifiedBadgeExplanation,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.verifiedBadgeExplanation))),
          child: SizedBox(
            width: 20,
            height: 20,
            child: Icon(Icons.check, size: 14, color: onColor),
          ),
        ),
      ),
    );
  }
}

class _MacroChipsRow extends StatelessWidget {
  const _MacroChipsRow({
    required this.carbs,
    required this.fat,
    required this.protein,
    required this.pct,
    required this.zeroCal,
  });
  final double carbs;
  final double fat;
  final double protein;
  final ({int carb, int fat, int protein}) pct;
  final bool zeroCal;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    return Row(
      children: [
        Expanded(
          child: _MacroChip(
            label: l.carb,
            grams: carbs,
            percent: pct.carb,
            color: c.carb,
            zeroCal: zeroCal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroChip(
            label: l.fat,
            grams: fat,
            percent: pct.fat,
            color: c.fat,
            zeroCal: zeroCal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroChip(
            label: l.protein,
            grams: protein,
            percent: pct.protein,
            color: c.protein,
            zeroCal: zeroCal,
          ),
        ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.grams,
    required this.percent,
    required this.color,
    required this.zeroCal,
  });
  final String label;
  final double grams;
  final int percent;
  final Color color;
  final bool zeroCal;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              '${fmtGrams(grams)}${l.grams}',
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            // A zero-calorie food can't have a calorie SHARE — showing 0%
            // for all three would misleadingly imply an even split.
            zeroCal ? '–' : fmtPercent(percent),
            style: TextStyle(fontSize: 11, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  const _DonutCard({required this.kcal, required this.pct});
  final double kcal;
  final ({int carb, int fat, int protein}) pct;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: c.cardShadow,
      ),
      child: Center(
        // ExcludeSemantics: the label below already restates the center
        // kcal text, so a screen reader gets one clean announcement
        // instead of the number twice.
        child: Semantics(
          label:
              '${fmtInt(kcal)} ${l.kcal} — '
              '${l.carb} ${fmtPercent(pct.carb)}, '
              '${l.fat} ${fmtPercent(pct.fat)}, '
              '${l.protein} ${fmtPercent(pct.protein)}',
          child: ExcludeSemantics(
            child: SizedBox(
              width: 160,
              height: 160,
              child: _AnimatedDonut(
                pct: pct,
                colors: (c.carb, c.fat, c.protein),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        child: Text(
                          fmtInt(kcal),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: c.inkStrong,
                          ),
                        ),
                      ),
                      Text(
                        l.kcal,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animates the three arcs to their new percentages (300ms, easeOut) any
/// time [pct] changes — quantity/unit edits update live, not instantly.
class _AnimatedDonut extends ImplicitlyAnimatedWidget {
  const _AnimatedDonut({
    required this.pct,
    required this.colors,
    required this.child,
  }) : super(
         duration: const Duration(milliseconds: 300),
         curve: Curves.easeOut,
       );

  final ({int carb, int fat, int protein}) pct;
  final (Color, Color, Color) colors;
  final Widget child;

  @override
  ImplicitlyAnimatedWidgetState<_AnimatedDonut> createState() =>
      _AnimatedDonutState();
}

class _AnimatedDonutState
    extends ImplicitlyAnimatedWidgetState<_AnimatedDonut> {
  Tween<double>? _carb, _fat, _protein;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _carb =
        visitor(
              _carb,
              widget.pct.carb.toDouble(),
              (v) => Tween<double>(begin: v as double),
            )
            as Tween<double>;
    _fat =
        visitor(
              _fat,
              widget.pct.fat.toDouble(),
              (v) => Tween<double>(begin: v as double),
            )
            as Tween<double>;
    _protein =
        visitor(
              _protein,
              widget.pct.protein.toDouble(),
              (v) => Tween<double>(begin: v as double),
            )
            as Tween<double>;
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder is required, not decorative: nothing else here
    // listens to `animation`, so without it build() only evaluates the
    // tweens once per external rebuild and then sits frozen at that single
    // frame instead of gliding — same root cause as AnimatedStripedBar.
    return AnimatedBuilder(
      animation: animation,
      child: widget.child,
      builder: (context, child) => CustomPaint(
        painter: DonutChartPainter(
          carbPct: _carb!.evaluate(animation),
          fatPct: _fat!.evaluate(animation),
          proteinPct: _protein!.evaluate(animation),
          carbColor: widget.colors.$1,
          fatColor: widget.colors.$2,
          proteinColor: widget.colors.$3,
          trackColor: const Color(0x00000000),
        ),
        child: child,
      ),
    );
  }
}

/// Three-arc donut, hand-painted (no charting package): carb, fat, protein
/// in that reading order, sized by calorie-share percentage. Soft round
/// stroke caps matching the app's other hand-painted charts.
class DonutChartPainter extends CustomPainter {
  DonutChartPainter({
    required this.carbPct,
    required this.fatPct,
    required this.proteinPct,
    required this.carbColor,
    required this.fatColor,
    required this.proteinColor,
    required this.trackColor,
  });

  final double carbPct;
  final double fatPct;
  final double proteinPct;
  final Color carbColor;
  final Color fatColor;
  final Color proteinColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.14;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawArc(rect, 0, 6.2832, false, base);

    var start = -1.5708; // start at 12 o'clock
    for (final MapEntry(key: pct, value: color) in {
      carbPct: carbColor,
      fatPct: fatColor,
      proteinPct: proteinColor,
    }.entries) {
      if (pct <= 0) continue;
      final sweep = pct / 100 * 6.2832;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter old) =>
      old.carbPct != carbPct ||
      old.fatPct != fatPct ||
      old.proteinPct != proteinPct;
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.fractionLabel,
    required this.decimalLabel,
    required this.onChanged,
  });
  final String mode;
  final String fractionLabel;
  final String decimalLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget seg(String value, String label) {
      final selected = mode == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c.chipBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? c.chipText : c.muted,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.macroTrack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('fraction', fractionLabel),
          seg('decimal', decimalLabel),
        ],
      ),
    );
  }
}

class _FractionPicker extends StatelessWidget {
  const _FractionPicker({
    required this.whole,
    required this.fractionPreset,
    required this.wholeLabel,
    required this.onWholeChanged,
    required this.onFractionChanged,
  });
  final int whole;
  final int fractionPreset;
  final String wholeLabel;
  final ValueChanged<int> onWholeChanged;
  final ValueChanged<int> onFractionChanged;

  static const _labels = {1: '¼', 2: '⅓', 3: '½', 4: '⅔', 5: '¾'};

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(wholeLabel, style: TextStyle(fontSize: 13, color: c.muted)),
            const Spacer(),
            IconButton(
              onPressed: whole > 0 ? () => onWholeChanged(whole - 1) : null,
              icon: const Icon(Icons.remove, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: c.macroTrack,
                foregroundColor: c.ink,
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                fmtInt(whole),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
            ),
            IconButton(
              onPressed: whole < 98 ? () => onWholeChanged(whole + 1) : null,
              icon: const Icon(Icons.add, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: c.macroTrack,
                foregroundColor: c.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in _labels.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: fractionPreset == entry.key,
                onSelected: (_) => onFractionChanged(
                  fractionPreset == entry.key ? 0 : entry.key,
                ),
                selectedColor: c.chipBg,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: fractionPreset == entry.key ? c.chipText : c.ink,
                ),
                side: BorderSide(
                  color: fractionPreset == entry.key ? c.accent : c.divider,
                ),
                backgroundColor: c.card,
              ),
          ],
        ),
      ],
    );
  }
}

class _DecimalPicker extends StatelessWidget {
  const _DecimalPicker({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    void step(double delta) {
      final v = double.tryParse(controller.text) ?? 1.0;
      final next = (v + delta).clamp(0.1, 99.0);
      controller.text = fmtServings((next * 10).round() / 10);
      onChanged();
    }

    return Row(
      children: [
        IconButton(
          onPressed: () => step(-0.5),
          icon: const Icon(Icons.remove, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: c.macroTrack,
            foregroundColor: c.ink,
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              const WesternDigitsFormatter(allowDecimal: true),
              LengthLimitingTextInputFormatter(5),
            ],
            onChanged: (_) => onChanged(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: c.macroTrack,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () => step(0.5),
          icon: const Icon(Icons.add, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: c.macroTrack,
            foregroundColor: c.ink,
          ),
        ),
      ],
    );
  }
}
