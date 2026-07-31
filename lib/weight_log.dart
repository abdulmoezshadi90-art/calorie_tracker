import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'profile.dart';
import 'settings_screen.dart' show WesternDigitsFormatter;
import 'theme.dart';

/// Bottom sheet to log today's weight (kg, one decimal allowed). One entry
/// per day; logging again the same day asks to replace. Neutral by design
/// — no red/alarm styling on any weight value (design decision 2).
void showLogWeightSheet(BuildContext context, AppState state) {
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
      child: _LogWeightSheet(state: state),
    ),
  );
}

class _LogWeightSheet extends StatefulWidget {
  const _LogWeightSheet({required this.state});
  final AppState state;

  @override
  State<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<_LogWeightSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Prefill with the most recent weight, if any, as a sensible start.
    final entries = widget.state.weightEntries();
    if (entries.isNotEmpty) {
      _controller.text = _fmt(entries.last.kg);
    }
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = widget.state.l;
    final kg = double.tryParse(_controller.text) ?? 0;
    if (kg < profileRanges.weight.min || kg > profileRanges.weight.max) {
      setState(() => _error = l.invalidNumber);
      return;
    }
    final today = widget.state.now();
    if (widget.state.hasWeightOn(today)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(l.weightOverwrite),
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
      if (replace != true || !mounted) return;
    }
    final ok = await widget.state.logWeight(today, kg);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = l.saveFailed);
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.weightSaved)));
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
            l.logWeight,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              const WesternDigitsFormatter(allowDecimal: true),
              LengthLimitingTextInputFormatter(5),
            ],
            style: TextStyle(color: c.ink, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: '${l.weightTrend} (${l.kg})',
              helperText: l.rangeHint(
                profileRanges.weight.min,
                profileRanges.weight.max,
              ),
              labelStyle: TextStyle(fontSize: 13, color: c.muted),
              helperStyle: TextStyle(fontSize: 10, color: c.muted),
              filled: true,
              fillColor: c.macroTrack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(fontSize: 13, color: c.fieldError)),
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
}
