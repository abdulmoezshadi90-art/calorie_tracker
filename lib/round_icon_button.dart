import 'package:flutter/material.dart';

/// Every circular icon affordance in the app ("add this", "this meal is
/// logged", quick-add rows across Foods/Search/History/Saved Meals) shares
/// this shape — a filled circle with a solid glyph — so the eye learns it
/// once. Size and color vary with emphasis (44dp muted-idle for repeated
/// per-row actions vs. 30dp accent for a single prominent CTA), the shape
/// never does. Purely visual: wrap in `InkWell`/`GestureDetector` for
/// tappable uses, matching every existing call site.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.bg,
    required this.icon,
    required this.iconColor,
    this.size = 44,
    this.iconSize = 22,
  });
  final Color bg;
  final IconData icon;
  final Color iconColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}
