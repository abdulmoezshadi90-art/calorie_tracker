// One-off generator for app icon + splash artwork (issue #9).
// Run: C:\dev\flutter\bin\flutter.bat test tool\generate_app_icon.dart
// Then: flutter_launcher_icons + flutter_native_splash (see pubspec).
//
// Mark: a plate ring with a gold progress arc and a small leaf — the
// calorie bar + Libyan-life motifs in the app palette.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _green = Color(0xFF35533B);
const _greenDeep = Color(0xFF243D2A);
const _cream = Color(0xFFF1EEE0);
const _gold = Color(0xFFEFC65B);

/// Draws the mark centered in a [size] box. [ink] is the ring/leaf color.
void _mark(Canvas c, double size, Color ink) {
  final center = Offset(size / 2, size / 2 + size * 0.02);
  final r = size * 0.30;
  final stroke = size * 0.075;

  // Plate ring.
  c.drawCircle(
    center,
    r,
    Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke,
  );
  // Gold progress arc on the rim (~65%, from the top).
  c.drawArc(
    Rect.fromCircle(center: center, radius: r),
    -1.5708,
    4.1,
    false,
    Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round,
  );
  // Inner plate dot.
  c.drawCircle(center, r * 0.32, Paint()..color = ink);
  // Leaf: short stem off the ring's top-right with two splayed petals.
  final leafBase = center + Offset(r * 0.82, -r * 0.95);
  final leaf = Paint()..color = ink;
  c.save();
  c.translate(leafBase.dx, leafBase.dy);
  c.rotate(0.45); // stem leans away from the ring
  c.drawLine(
    Offset.zero,
    Offset(0, -size * 0.07),
    Paint()
      ..color = ink
      ..strokeWidth = size * 0.018
      ..strokeCap = StrokeCap.round,
  );
  for (final side in [-1, 1]) {
    c.save();
    c.translate(0, -size * 0.06);
    c.rotate(side * 0.85);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, -size * 0.05),
        width: size * 0.045,
        height: size * 0.105,
      ),
      leaf,
    );
    c.restore();
  }
  c.restore();
}

Future<void> _save(
  void Function(Canvas) draw,
  String path,
  int px,
) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('generate app icon + splash artwork into assets/branding', () async {
    const s = 1024.0;

    // Full-bleed launcher icon: green gradient + cream mark.
    await _save((c) {
      c.drawRect(
        const Rect.fromLTWH(0, 0, s, s),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_green, _greenDeep],
          ).createShader(const Rect.fromLTWH(0, 0, s, s)),
      );
      _mark(c, s, _cream);
    }, 'assets/branding/app_icon.png', 1024);

    // Adaptive foreground: transparent, mark shrunk into the safe zone.
    await _save((c) {
      c.save();
      c.translate(s * 0.22, s * 0.22);
      c.scale(0.56);
      _mark(c, s, _cream);
      c.restore();
    }, 'assets/branding/app_icon_foreground.png', 1024);

    // Splash marks: green-on-transparent (light bg) and cream (dark bg).
    await _save(
      (c) => _mark(c, 640, _green),
      'assets/branding/splash_mark.png',
      640,
    );
    await _save(
      (c) => _mark(c, 640, _cream),
      'assets/branding/splash_mark_dark.png',
      640,
    );
  });
}
