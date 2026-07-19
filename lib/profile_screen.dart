import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'models.dart';
import 'profile.dart';
import 'settings_screen.dart';
import 'theme.dart';

/// Profile step with maintenance calculation (design decision 8).
///
/// A local profile, never an account: no login, no sign up, answers stay in
/// shared_preferences. Reached from onboarding (skippable) and from the
/// settings "recalculate" entry. The result saves through the existing
/// Goals object so all floors and gentle warnings keep applying.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  Sex? _sex;
  ActivityLevel _activity = ActivityLevel.moderate;
  WeightGoal _goal = WeightGoal.maintain;
  String? _error;
  MaintenanceResult? _result;

  @override
  void initState() {
    super.initState();
    // Recalculate flow: start from the saved profile.
    final p = AppScope.read(context).profile;
    if (p != null) {
      _name.text = p.name;
      _age.text = '${p.age}';
      _weight.text = '${p.weightKg}';
      _height.text = '${p.heightCm}';
      _sex = p.sex;
      _activity = p.activity;
      _goal = p.goal;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Profile? _buildProfile(AppState state) {
    final age = int.tryParse(_age.text) ?? 0;
    final weight = int.tryParse(_weight.text) ?? 0;
    final height = int.tryParse(_height.text) ?? 0;
    final sex = _sex;
    final valid =
        sex != null &&
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
      activity: _activity,
      goal: _goal,
    );
  }

  void _calculate(AppState state) {
    final profile = _buildProfile(state);
    if (profile == null) {
      setState(() {
        _error = state.l.completeFields;
        _result = null;
      });
      return;
    }
    setState(() {
      _error = null;
      _result = calculateMaintenance(profile);
    });
  }

  void _useGoal(AppState state) {
    final profile = _buildProfile(state);
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
        title: Text(l.profileTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l.profileIntro,
            style: TextStyle(fontSize: 13, height: 1.5, color: c.muted),
          ),
          const SizedBox(height: 16),
          _textField(c, l.nameOptional, _name, numeric: false),
          const SizedBox(height: 16),
          _sectionLabel(c, l.sexLabel),
          _chipWrap<Sex>(
            c,
            Sex.values,
            _sex,
            l.sexName,
            (v) => setState(() => _sex = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _textField(
                  c,
                  l.ageLabel,
                  _age,
                  hint: l.rangeHint(profileRanges.age.min, profileRanges.age.max),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _textField(
                  c,
                  l.weightLabel,
                  _weight,
                  hint: l.rangeHint(
                    profileRanges.weight.min,
                    profileRanges.weight.max,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _textField(
                  c,
                  l.heightLabel,
                  _height,
                  hint: l.rangeHint(
                    profileRanges.height.min,
                    profileRanges.height.max,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel(c, l.activityLabel),
          _chipWrap<ActivityLevel>(
            c,
            ActivityLevel.values,
            _activity,
            l.activityName,
            (v) => setState(() => _activity = v),
          ),
          const SizedBox(height: 16),
          _sectionLabel(c, l.goalLabel),
          _chipWrap<WeightGoal>(
            c,
            WeightGoal.values,
            _goal,
            l.weightGoalName,
            (v) => setState(() => _goal = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(fontSize: 13, color: c.fat)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _calculate(state),
            child: Text(
              l.calculateGoal,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(
              result: _result!,
              onUse: () => _useGoal(state),
              onAdjust: () {
                // Save the profile, then hand the calculated numbers to the
                // standard goals editor: floors and warnings apply there.
                final profile = _buildProfile(state);
                if (profile != null) state.setProfile(profile);
                showGoalsEditor(context, state, initial: _result!.goals);
              },
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(AppColors c, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: c.ink,
      ),
    ),
  );

  Widget _chipWrap<T>(
    AppColors c,
    List<T> values,
    T? selected,
    String Function(T) label,
    ValueChanged<T> onSelect,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(label(v)),
            selected: v == selected,
            onSelected: (_) => onSelect(v),
            selectedColor: c.chipBg,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: v == selected ? c.chipText : c.ink,
            ),
            side: BorderSide(color: v == selected ? c.accent : c.divider),
            backgroundColor: c.card,
          ),
      ],
    );
  }

  Widget _textField(
    AppColors c,
    String label,
    TextEditingController controller, {
    bool numeric = true,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.name,
      inputFormatters: numeric
          ? [WesternDigitsFormatter(), LengthLimitingTextInputFormatter(3)]
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.onUse,
    required this.onAdjust,
  });
  final MaintenanceResult result;
  final VoidCallback onUse;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final g = result.goals;

    return Container(
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
                  onPressed: onAdjust,
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
                  onPressed: onUse,
                  child: Text(l.useThisGoal),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
