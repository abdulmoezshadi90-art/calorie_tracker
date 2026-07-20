import 'package:flutter/material.dart';

/// Progress bar with striped overflow: within goal it is a plain rounded
/// fill; past the goal it fills solid to the goal marker and continues
/// with a diagonal hatch in the same color family — informative, never
/// alarming (design decision 2).
///
/// The full track width represents max(value, goal), so the goal sits at
/// `goal / value` when over. Mirrors in RTL.
class StripedBar extends StatelessWidget {
  const StripedBar({
    super.key,
    required this.value,
    required this.goal,
    required this.height,
    required this.track,
    this.color,
    this.gradient,
  }) : assert(color != null || gradient != null);

  final double value;
  final double goal;
  final double height;
  final Color track;

  /// Solid fill color (macro mini bars).
  final Color? color;

  /// Solid fill gradient (calorie bar). Overrides [color] when set.
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _StripedBarPainter(
          value: value,
          goal: goal,
          track: track,
          color: color,
          gradient: gradient,
          isRtl: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    );
  }
}

class _StripedBarPainter extends CustomPainter {
  _StripedBarPainter({
    required this.value,
    required this.goal,
    required this.track,
    required this.color,
    required this.gradient,
    required this.isRtl,
  });

  final double value;
  final double goal;
  final Color track;
  final Color? color;
  final List<Color>? gradient;
  final bool isRtl;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final full = Offset.zero & size;
    canvas.clipRRect(RRect.fromRectAndRadius(full, radius));

    canvas.drawRect(full, Paint()..color = track);
    if (value <= 0 || goal <= 0) return;

    // Fractions of the track: solid ends at the goal marker when over.
    final over = value > goal;
    final solidFrac = over ? goal / value : (value / goal).clamp(0.0, 1.0);

    Rect fromFrac(double start, double end) {
      final w = size.width;
      return isRtl
          ? Rect.fromLTRB(w - end * w, 0, w - start * w, size.height)
          : Rect.fromLTRB(start * w, 0, end * w, size.height);
    }

    final fillColor = color ?? gradient![0];
    final solidPaint = Paint();
    if (gradient != null) {
      solidPaint.shader = LinearGradient(
        colors: isRtl ? gradient!.reversed.toList() : gradient!,
      ).createShader(full);
    } else {
      solidPaint.color = fillColor;
    }
    canvas.drawRect(fromFrac(0, solidFrac), solidPaint);

    if (!over) return;

    // Overflow segment: faint wash of the same color, hatched with
    // diagonal stripes in the fill color. Same family, no alarm red.
    final overRect = fromFrac(solidFrac, 1);
    canvas.drawRect(
      overRect,
      Paint()..color = fillColor.withValues(alpha: 0.22),
    );
    final stripe = Paint()
      ..color = fillColor.withValues(alpha: 0.75)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;
    canvas.save();
    canvas.clipRect(overRect);
    const gap = 7.0;
    // 45° stripes; mirrored slope in RTL so the hatch reads directional.
    final slope = isRtl ? -size.height : size.height;
    for (
      var x = overRect.left - size.height;
      x < overRect.right + size.height;
      x += gap
    ) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + slope, 0),
        stripe,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripedBarPainter old) =>
      old.value != value ||
      old.goal != goal ||
      old.track != track ||
      old.color != color ||
      old.gradient != gradient ||
      old.isRtl != isRtl;
}
