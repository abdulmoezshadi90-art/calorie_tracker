import 'package:flutter/material.dart';

import 'theme.dart';

/// Shared friendly empty state: icon, short line, optional hint, and one
/// clear action. Used by search, history and meal detail (the home screen
/// uses an inline banner tuned to its layout).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.graphic,
    required this.line,
    this.hint,
    required this.actionLabel,
    required this.onAction,
  }) : assert(icon != null || graphic != null);

  final IconData? icon;
  /// Custom glyph (e.g. [MealIcon]) shown instead of [icon].
  final Widget? graphic;
  final String line;
  final String? hint;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.chipBg, shape: BoxShape.circle),
              child: graphic ?? Icon(icon, size: 30, color: c.accent),
            ),
            const SizedBox(height: 16),
            Text(
              line,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
