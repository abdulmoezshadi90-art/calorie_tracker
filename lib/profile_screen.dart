import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
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
  static const _questionCount = 7; // steps before the result summary

  final _controller = PageController();
  int _step = 0;

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  Sex? _sex;
  ActivityLevel? _activity;
  WeightGoal? _goal;
  String? _error;
  MaintenanceResult? _result;

  /// Brief pause before revealing the result: the math is instant, the
  /// moment deserves weight. The ONLY loading state besides cold launch.
  bool _calculating = false;

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
      _goal = p.goal;
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

  Profile? _buildProfile() {
    final age = int.tryParse(_age.text) ?? 0;
    final weight = double.tryParse(_weight.text) ?? 0;
    final height = double.tryParse(_height.text) ?? 0;
    final sex = _sex;
    final activity = _activity;
    final goal = _goal;
    final valid =
        sex != null &&
        activity != null &&
        goal != null &&
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
      goal: goal,
    );
  }

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

  void _useGoal(AppState state) {
    final profile = _buildProfile();
    final result = _result;
    if (profile == null || result == null) return;
    state.setProfile(profile);
    // Result is already clamped at the floors, so this save needs no
    // warning; manual edits go through the goals editor as usual.
    state.setGoals(result.goals);
    if (!mounted) return;
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
            child: _textField(
              c,
              l.ageLabel,
              _age,
              hint: l.rangeHint(profileRanges.age.min, profileRanges.age.max),
            ),
            onContinue: () => _continueNumeric(state, _age, profileRanges.age),
          ),
          _numericOrTextStep(
            state,
            c,
            question: l.weightQuestion,
            child: _textField(
              c,
              l.weightLabel,
              _weight,
              decimal: true,
              hint: l.rangeHint(
                profileRanges.weight.min,
                profileRanges.weight.max,
              ),
            ),
            onContinue: () =>
                _continueNumeric(state, _weight, profileRanges.weight),
          ),
          _numericOrTextStep(
            state,
            c,
            question: l.heightQuestion,
            child: _textField(
              c,
              l.heightLabel,
              _height,
              decimal: true,
              hint: l.rangeHint(
                profileRanges.height.min,
                profileRanges.height.max,
              ),
            ),
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
          _choiceStep<WeightGoal>(
            c,
            question: l.goalQuestion,
            // Reference-calculator order: maintain, mild loss, loss, gain.
            values: const [
              WeightGoal.maintain,
              WeightGoal.loseGently,
              WeightGoal.lose,
              WeightGoal.gain,
            ],
            selected: _goal,
            label: l.weightGoalName,
            description: l.goalDesc,
            onSelect: (v) {
              setState(() => _goal = v);
              _next();
            },
          ),
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
          Text(_error!, style: TextStyle(fontSize: 13, color: c.fat)),
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
            style: TextStyle(fontSize: 11, height: 1.4, color: c.muted),
          ),
        ],
      ],
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
    String? hint,
  }) {
    return TextField(
      controller: controller,
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
        helperText: hint,
        helperStyle: TextStyle(fontSize: 10, color: c.muted),
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

/// One selectable option: label, optional one-line description, tap to
/// choose (the wizard auto-advances).
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    this.description,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String? description;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
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
                  style: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
