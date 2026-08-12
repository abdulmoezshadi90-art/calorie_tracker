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
    this.actionLabel,
    this.onAction,
  }) : assert(icon != null || graphic != null),
       assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be supplied together, or not at all',
       );

  final IconData? icon;

  /// Custom glyph (e.g. [MealIcon]) shown instead of [icon].
  final Widget? graphic;
  final String line;
  final String? hint;

  /// Both null hides the action button entirely — a state with nothing
  /// useful to do about it (e.g. no history logged anywhere yet).
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Scrollable, not just Center: callers place this inside an Expanded
    // whose available height they don't fully control (e.g. a picker tab
    // squeezed by sibling content on a short screen). A few pixels of
    // scroll beats a hard RenderFlex overflow when this content's natural
    // size (icon + line + optional hint/button) doesn't quite fit.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.chipBg,
                shape: BoxShape.circle,
              ),
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
            if (actionLabel != null && onAction != null) ...[
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
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
