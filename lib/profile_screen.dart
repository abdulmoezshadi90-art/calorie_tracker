import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'l10n.dart';
import 'models.dart';
import 'profile.dart';
import 'settings_screen.dart';
import 'theme.dart';

/// Profile wizard with maintenance calculation (design decision 8).
///
/// One question per screen: name → sex → age → weight → height → activity
/// → weight goal → result summary. Choice steps auto-advance; numeric
/// steps use a continue button. A local profile, never an account: no
/// login, no sign up, answers stay in shared_preferences. Skippable at
/// any point (skip = defaults). The result saves through the existing
/// Goals object so all floors and gentle warnings keep applying.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _controller = PageController();
  int _step = 0;

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  Sex? _sex;
  ActivityLevel? _activity;
  GoalDirection? _goalDirection;
  GoalRate? _goalRate;
  String? _error;
  MaintenanceResult? _result;

  /// Brief pause before revealing the result: the math is instant, the
  /// moment deserves weight. The ONLY loading state besides cold launch.
  bool _calculating = false;

  /// Lose/gain need a rate step; maintain skips straight to the result, so
  /// the step count (and the progress indicator) is never fixed.
  bool get _hasRateStep =>
      _goalDirection == GoalDirection.lose ||
      _goalDirection == GoalDirection.gain;
  int get _questionCount => _hasRateStep ? 8 : 7;

  @override
  void initState() {
    super.initState();
    // Recalculate flow: start from the saved profile.
    final p = AppScope.read(context).profile;
    if (p != null) {
      _name.text = p.name;
      _age.text = '${p.age}';
      _weight.text = fmtServings(p.weightKg); // "81.5", "80" (no ".0")
      _height.text = fmtServings(p.heightCm);
      _sex = p.sex;
      _activity = p.activity;
      _goalDirection = p.goalDirection;
      _goalRate = p.goalRate;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  /// Shared by the real submission ([_buildProfile]) and the rate step's
  /// live per-card preview, which plugs in a candidate rate before the
  /// user has actually chosen one.
  Profile? _profileFor(GoalDirection? direction, GoalRate? rate) {
    final age = int.tryParse(_age.text) ?? 0;
    final weight = double.tryParse(_weight.text) ?? 0;
    final height = double.tryParse(_height.text) ?? 0;
    final sex = _sex;
    final activity = _activity;
    final valid =
        sex != null &&
        activity != null &&
        direction != null &&
        (direction == GoalDirection.maintain || rate != null) &&
        age >= profileRanges.age.min &&
        age <= profileRanges.age.max &&
        weight >= profileRanges.weight.min &&
        weight <= profileRanges.weight.max &&
        height >= profileRanges.height.min &&
        height <= profileRanges.height.max;
    if (!valid) return null;
    return Profile(
      name: _name.text.trim(),
      sex: sex,
      age: age,
      weightKg: weight,
      heightCm: height,
      activity: activity,
      goalDirection: direction,
      goalRate: direction == GoalDirection.maintain ? null : rate,
    );
  }

  Profile? _buildProfile() => _profileFor(_goalDirection, _goalRate);

  void _goTo(int step) {
    setState(() {
      _step = step;
      _error = null;
      if (step == _questionCount) {
        final profile = _buildProfile();
        _result = profile == null ? null : calculateMaintenance(profile);
        _calculating = true;
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _calculating = false);
        });
      }
    });
    _controller.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _next() => _goTo(_step + 1);

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      _goTo(_step - 1);
    }
  }

  /// Validates the numeric field for the current step, then advances.
  /// Parses as double so decimal weight/height ("81.5") validate too;
  /// the age field's formatter never lets a '.' through.
  void _continueNumeric(
    AppState state,
    TextEditingController controller,
    ({int min, int max}) range,
  ) {
    final value = double.tryParse(controller.text) ?? 0;
    if (value < range.min || value > range.max) {
      setState(() => _error = state.l.invalidNumber);
      return;
    }
    _next();
  }

  Future<void> _useGoal(AppState state) async {
    final profile = _buildProfile();
    final result = _result;
    if (profile == null || result == null) return;
    final okProfile = await state.setProfile(profile);
    // Result is already clamped at the floors, so this save needs no
    // warning; manual edits go through the goals editor as usual.
    final okGoals = await state.setGoals(result.goals);
    if (!mounted) return;
    if (!okProfile || !okGoals) {
      setState(() => _error = state.l.saveFailed);
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.l.goalsSaved)));
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
        // Directional icon mirrors in RTL automatically.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: Text(l.profileTitle),
        actions: [
          // Skippable at any point: skip = defaults, nothing saved.
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l.skip,
              style: TextStyle(color: c.onHeader.withValues(alpha: 0.85)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _step < _questionCount
                  ? '${fmtInt(_step + 1)}/${fmtInt(_questionCount)}'
                  : l.suggestedGoal,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.onHeader.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _controller,
        // Steps validate on advance; free swiping would bypass that.
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _numericOrTextStep(
            state,
            c,
            question: l.nameQuestion,
            child: _textField(c, l.nameOptional, _name, numeric: false),
            onContinue: _next,
          ),
          _choiceStep<Sex>(
            c,
            question: l.sexQuestion,
            values: Sex.values,
            selected: _sex,
            label: l.sexName,
            onSelect: (v) {
              setState(() => _sex = v);
              _next();
            },
          ),
          _numericOrTextStep(
            state,
            c,
            question: l.ageQuestion,
            child: _textField(c, l.ageLabel, _age),
            onContinue: () => _continueNumeric(state, _age, profileRanges.age),
          ),
          _numericOrTextStep(
            state,
            c,
            question: l.weightQuestion,
            child: _textField(c, l.weightLabel, _weight, decimal: true),
            onContinue: () =>
                _continueNumeric(state, _weight, profileRanges.weight),
          ),
          _numericOrTextStep(
            state,
            c,
            question: l.heightQuestion,
            child: _textField(c, l.heightLabel, _height, decimal: true),
            onContinue: () =>
                _continueNumeric(state, _height, profileRanges.height),
          ),
          _choiceStep<ActivityLevel>(
            c,
            question: l.activityQuestion,
            values: ActivityLevel.values,
            selected: _activity,
            label: l.activityName,
            description: l.activityDesc,
            helper: l.exerciseHelper,
            onSelect: (v) {
              setState(() => _activity = v);
              _next();
            },
          ),
          _choiceStep<GoalDirection>(
            c,
            question: l.goalQuestion,
            values: const [
              GoalDirection.lose,
              GoalDirection.maintain,
              GoalDirection.gain,
            ],
            selected: _goalDirection,
            label: l.goalDirectionName,
            onSelect: (v) {
              // A new direction invalidates any previously chosen rate
              // (also covers backing up from the rate step and switching).
              setState(() {
                _goalDirection = v;
                _goalRate = null;
              });
              _next();
            },
          ),
          if (_hasRateStep) _rateStep(state, c),
          _resultStep(state, c),
        ],
      ),
    );
  }

  /// Shared step layout: the question, input and button group vertically
  /// centered in the available space (calm guided flow, not a form).
  /// Falls back to scrolling when content is taller than the viewport
  /// (activity step at large font sizes).
  Widget _stepShell(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _question(AppColors c, String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: c.inkStrong,
    ),
  );

  /// Name and the three numeric steps: question, one field, continue.
  Widget _numericOrTextStep(
    AppState state,
    AppColors c, {
    required String question,
    required Widget child,
    required VoidCallback onContinue,
  }) {
    return _stepShell([
        _question(c, question),
        const SizedBox(height: 24),
        child,
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.fat),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: c.accent,
            foregroundColor: c.onAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: onContinue,
          child: Text(
            state.l.continueLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Choice steps: question + one card per option, tap auto-advances.
  /// [description] adds the one-line explanation (activity, goal);
  /// [helper] adds the small definition line under the cards.
  Widget _choiceStep<T>(
    AppColors c, {
    required String question,
    required List<T> values,
    required T? selected,
    required String Function(T) label,
    String Function(T)? description,
    String? helper,
    required ValueChanged<T> onSelect,
  }) {
    return _stepShell([
        _question(c, question),
        const SizedBox(height: 20),
        for (final v in values) ...[
          _OptionCard(
            label: label(v),
            description: description?.call(v),
            selected: v == selected,
            onTap: () => onSelect(v),
          ),
          const SizedBox(height: 10),
        ],
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.4, color: c.muted),
          ),
        ],
      ],
    );
  }

  /// Rate step (lose/gain only — maintain skips it). Each card previews the
  /// resulting daily target live from the answers already given, using a
  /// candidate profile for that specific rate.
  Widget _rateStep(AppState state, AppColors c) {
    final l = state.l;
    final direction = _goalDirection;
    if (direction == null || direction == GoalDirection.maintain) {
      return const SizedBox.shrink(); // unreachable — guarded by _hasRateStep
    }
    return _stepShell([
        _question(c, l.goalRateQuestion(direction)),
        const SizedBox(height: 20),
        for (final rate in GoalRate.values) ...[
          _rateOptionCard(l, direction, rate),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _rateOptionCard(L10n l, GoalDirection direction, GoalRate rate) {
    final preview = _profileFor(direction, rate);
    final result = preview == null ? null : calculateMaintenance(preview);
    return _OptionCard(
      label: l.goalRateName(direction, rate),
      description: l.goalRateKgLine(rate),
      detail: result == null ? null : '${fmtInt(result.goals.kcal)} ${l.kcal}',
      note: result != null && result.clamped ? l.goalFloorNote : null,
      selected: rate == _goalRate,
      onTap: () {
        setState(() => _goalRate = rate);
        _next();
      },
    );
  }

  Widget _resultStep(AppState state, AppColors c) {
    final l = state.l;
    final result = _result;
    // Only reachable with valid answers; guard for safety.
    if (result == null) return const SizedBox.shrink();
    if (_calculating) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3, color: c.accent),
        ),
      );
    }
    final g = result.goals;

    return _stepShell([
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: c.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.suggestedGoal,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${fmtInt(g.kcal)} ${l.kcal}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: c.inkStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.maintenanceLine(result.maintenanceKcal),
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
              if (result.clamped) ...[
                const SizedBox(height: 4),
                // Neutral wording by design: a note, never a block or alarm.
                Text(
                  l.goalFloorNote,
                  style: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${l.protein} ${fmtInt(g.protein)}${l.grams} · '
                '${l.fat} ${fmtInt(g.fat)}${l.grams} · '
                '${l.carb} ${fmtInt(g.carbs)}${l.grams}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
              if (result.maintenanceOnly) ...[
                const SizedBox(height: 8),
                // Neutral wording by design: a note, never a block or alarm.
                Text(
                  l.under18Note,
                  style: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                l.estimateNote,
                style: TextStyle(fontSize: 11, height: 1.4, color: c.muted),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(fontSize: 13, color: c.fat)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        // Save the profile, then hand the calculated numbers
                        // to the standard goals editor: floors and warnings
                        // apply there.
                        final profile = _buildProfile();
                        if (profile != null) state.setProfile(profile);
                        showGoalsEditor(context, state, initial: g);
                      },
                      style: TextButton.styleFrom(foregroundColor: c.muted),
                      child: Text(l.adjust),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: c.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _useGoal(state),
                      child: Text(l.useThisGoal),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textField(
    AppColors c,
    String label,
    TextEditingController controller, {
    bool numeric = true,
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: numeric
          ? TextInputType.numberWithOptions(decimal: decimal)
          : TextInputType.name,
      inputFormatters: numeric
          ? [
              WesternDigitsFormatter(allowDecimal: decimal),
              // "250" or "120.5" fit in 5; age stays a 3-digit field.
              LengthLimitingTextInputFormatter(decimal ? 5 : 3),
            ]
          : null,
      style: TextStyle(color: c.ink, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: c.muted),
        filled: true,
        fillColor: c.macroTrack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// One selectable option: label, optional description line(s), tap to
/// choose (the wizard auto-advances). [detail] is the live-computed daily
/// target (rate step); [note] is the floor-guard note when it clamped.
/// Content is centered, not left-aligned, even though the card itself
/// stays full width (Change 1 — layout-driven, no RTL-specific code).
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    this.description,
    this.detail,
    this.note,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String? description;
  final String? detail;
  final String? note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: selected ? c.chipBg : c.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? c.accent : c.divider,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? c.chipText : c.ink,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
                ),
              ],
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected ? c.chipText : c.accent,
                  ),
                ),
              ],
              if (note != null) ...[
                const SizedBox(height: 4),
                Text(
                  note!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, height: 1.4, color: c.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
