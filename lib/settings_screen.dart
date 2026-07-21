import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'models.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import 'theme.dart';
import 'weight_log.dart';

/// Shown in the about card. Keep in sync with pubspec.yaml `version:`.
const appVersion = '0.5.0';

const feedbackEmail = 'abdulmoezshadi.90@gmail.com';

/// Native mail intent (Android); no url_launcher — tiny dependency
/// footprint is deliberate. Returns false where unhandled (web, tests).
const _mailChannel = MethodChannel('ly.app.calorie_tracker/mail');

Future<void> openFeedbackEmail(BuildContext context, AppState state) async {
  final l = state.l;
  final subject = 'Calorie Tracker feedback';
  final body = 'App version: $appVersion\nLanguage: ${state.localeCode}\n\n';
  var opened = false;
  try {
    opened = await _mailChannel.invokeMethod<bool>('openMail', {
          'to': feedbackEmail,
          'subject': subject,
          'body': body,
        }) ??
        false;
  } catch (_) {
    opened = false;
  }
  if (opened || !context.mounted) return;
  // Fallback (web/desktop or no mail app): copy the address instead.
  await Clipboard.setData(const ClipboardData(text: feedbackEmail));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${l.feedbackCopied}: $feedbackEmail')),
  );
}

/// Normalizes Eastern Arabic numerals to Western on entry and strips
/// everything that is not 0-9 (hard requirement 1). With [allowDecimal]
/// a single '.' is permitted too (Arabic decimal separator '٫' and ','
/// normalize to '.') — used by weight/height, never by integer fields.
class WesternDigitsFormatter extends TextInputFormatter {
  const WesternDigitsFormatter({this.allowDecimal = false});
  final bool allowDecimal;

  static const _eastern = '٠١٢٣٤٥٦٧٨٩';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buf = StringBuffer();
    var hasPoint = false;
    for (final rune in newValue.text.runes) {
      final ch = String.fromCharCode(rune);
      final eastern = _eastern.indexOf(ch);
      if (eastern >= 0) {
        buf.write(eastern);
      } else if (ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0) {
        buf.write(ch);
      } else if (allowDecimal &&
          !hasPoint &&
          (ch == '.' || ch == '٫' || ch == ',')) {
        buf.write('.');
        hasPoint = true;
      }
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final goals = state.goals;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Text(l.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language first for quick access — the toggle moved here from
          // the home top bar in the bottom-nav restructure.
          _SettingsCard(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: Icon(Icons.language_outlined, color: c.accent),
              title: Text(
                l.language,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
              ),
              subtitle: Text(
                l.languageName,
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
              trailing: Container(
                height: 36,
                width: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.chipBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  l.toggleLabel,
                  style: TextStyle(
                    color: c.chipText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              onTap: state.toggleLocale,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: Icon(Icons.flag_outlined, color: c.accent),
              title: Text(
                l.dailyGoals,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
              ),
              subtitle: Text(
                '${fmtInt(goals.kcal)} ${l.kcal} · '
                '${l.carb} ${fmtInt(goals.carbs)}${l.grams} · '
                '${l.fat} ${fmtInt(goals.fat)}${l.grams} · '
                '${l.protein} ${fmtInt(goals.protein)}${l.grams}',
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
              trailing: Icon(Icons.edit_outlined, size: 20, color: c.muted),
              onTap: () => showGoalsEditor(context, state),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              // Unset profile (skipped wizard): invite setup rather than
              // showing a bare "recalculate" with nothing behind it.
              leading: Icon(
                state.profile == null
                    ? Icons.person_add_alt_1_outlined
                    : Icons.calculate_outlined,
                color: c.accent,
              ),
              title: Text(
                state.profile == null ? l.setUpProfile : l.recalculateGoal,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
              ),
              subtitle: Text(
                state.profile == null ? l.setUpProfileHint : l.profileTitle,
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: Icon(Icons.monitor_weight_outlined, color: c.accent),
              title: Text(
                l.logWeight,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
              ),
              onTap: () => showLogWeightSheet(context, state),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: Icon(Icons.replay_outlined, color: c.accent),
              title: Text(
                l.replayOnboarding,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OnboardingScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: Icon(Icons.mail_outline, color: c.accent),
              title: Text(
                l.sendFeedback,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
              ),
              subtitle: Text(
                feedbackEmail,
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
              onTap: () => openFeedbackEmail(context, state),
            ),
          ),
          const SizedBox(height: 12),
          // Room grows here later: export.
          _SettingsCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: c.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.about,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l.version} $appVersion',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.disclaimerTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.disclaimerBody,
                    style: TextStyle(fontSize: 12, height: 1.5, color: c.muted),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }
}

// ─────────────────────────── Goals editor ───────────────────────────

/// [initial] prefill (defaults to current goals) lets the profile summary
/// open the editor on the calculated values — every save still runs the
/// same validation, floors, and gentle warnings.
void showGoalsEditor(BuildContext context, AppState state, {Goals? initial}) {
  final c = AppColors.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _GoalsEditor(state: state, initial: initial ?? state.goals),
    ),
  );
}

class _GoalsEditor extends StatefulWidget {
  const _GoalsEditor({required this.state, required this.initial});
  final AppState state;
  final Goals initial;

  @override
  State<_GoalsEditor> createState() => _GoalsEditorState();
}

class _GoalsEditorState extends State<_GoalsEditor> {
  late final TextEditingController _kcal;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late final TextEditingController _protein;
  String? _error;

  @override
  void initState() {
    super.initState();
    final g = widget.initial;
    _kcal = TextEditingController(text: '${g.kcal}');
    _carbs = TextEditingController(text: '${g.carbs}');
    _fat = TextEditingController(text: '${g.fat}');
    _protein = TextEditingController(text: '${g.protein}');
  }

  @override
  void dispose() {
    _kcal.dispose();
    _carbs.dispose();
    _fat.dispose();
    _protein.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = widget.state.l;
    final kcal = int.tryParse(_kcal.text) ?? 0;
    final carbs = int.tryParse(_carbs.text) ?? 0;
    final fat = int.tryParse(_fat.text) ?? 0;
    final protein = int.tryParse(_protein.text) ?? 0;
    if (kcal <= 0 || carbs <= 0 || fat <= 0 || protein <= 0) {
      setState(() => _error = l.invalidNumber);
      return;
    }
    final belowFloor =
        kcal < goalFloors.kcal ||
        carbs < goalFloors.carbs ||
        fat < goalFloors.fat ||
        protein < goalFloors.protein;
    if (belowFloor) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(l.valueTooLow),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l.save),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    final ok = await widget.state.setGoals(
      Goals(kcal: kcal, carbs: carbs, fat: fat, protein: protein),
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = l.saveFailed);
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.goalsSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = widget.state.l;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.dailyGoals,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _field(c, l.calories, _kcal)),
              const SizedBox(width: 12),
              Expanded(child: _field(c, '${l.carb} (${l.grams})', _carbs)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(c, '${l.fat} (${l.grams})', _fat)),
              const SizedBox(width: 12),
              Expanded(child: _field(c, '${l.protein} (${l.grams})', _protein)),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(fontSize: 13, color: c.fat),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: c.muted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _save,
                  child: Text(
                    l.save,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(AppColors c, String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        WesternDigitsFormatter(),
        LengthLimitingTextInputFormatter(5),
      ],
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
