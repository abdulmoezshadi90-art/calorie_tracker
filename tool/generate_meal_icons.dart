// One-off generator for the bundled meal icon PNGs (issue #8).
// Run: C:\dev\flutter\bin\flutter.bat test tool\generate_meal_icons.dart
//
// Draws the four meal glyphs in solid black on transparency; the app tints
// them at runtime via Image(color:), so one set serves light and dark.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Paint _stroke(double w) => Paint()
  ..color = Colors.black
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// All glyphs are drawn on a 48x48 grid.
void _breakfast(Canvas c) {
  // Coffee cup with saucer and steam.
  final p = _stroke(3);
  c.drawPath(
    Path()
      ..moveTo(12, 20)
      ..lineTo(14, 36)
      ..quadraticBezierTo(15, 40, 19, 40)
      ..lineTo(29, 40)
      ..quadraticBezierTo(33, 40, 34, 36)
      ..lineTo(36, 20)
      ..close(),
    p,
  );
  // Handle.
  c.drawPath(
    Path()
      ..moveTo(36, 24)
      ..quadraticBezierTo(43, 24, 42, 30)
      ..quadraticBezierTo(41, 35, 35, 34),
    p,
  );
  // Steam.
  final s = _stroke(2.4);
  c.drawPath(Path()..moveTo(19, 8)..quadraticBezierTo(17, 12, 19, 15), s);
  c.drawPath(Path()..moveTo(26, 6)..quadraticBezierTo(24, 11, 26, 15), s);
}

void _lunch(Canvas c) {
  // Plate (two rings) with fork beside it.
  final p = _stroke(3);
  c.drawCircle(const Offset(28, 26), 14, p);
  c.drawCircle(const Offset(28, 26), 7, _stroke(2.4));
  // Fork.
  final f = _stroke(2.4);
  c.drawLine(const Offset(8, 10), const Offset(8, 42), f);
  c.drawPath(
    Path()
      ..moveTo(4, 10)
      ..lineTo(4, 18)
      ..quadraticBezierTo(4, 22, 8, 22)
      ..quadraticBezierTo(12, 22, 12, 18)
      ..lineTo(12, 10),
    f,
  );
}

void _dinner(Canvas c) {
  // Bowl with lid knob and steam.
  final p = _stroke(3);
  c.drawPath(
    Path()
      ..moveTo(8, 26)
      ..lineTo(40, 26)
      ..quadraticBezierTo(40, 40, 28, 41)
      ..lineTo(20, 41)
      ..quadraticBezierTo(8, 40, 8, 26)
      ..close(),
    p,
  );
  // Foot.
  c.drawLine(const Offset(19, 41), const Offset(17, 45), _stroke(2.4));
  c.drawLine(const Offset(29, 41), const Offset(31, 45), _stroke(2.4));
  // Steam.
  final s = _stroke(2.4);
  c.drawPath(Path()..moveTo(18, 10)..quadraticBezierTo(16, 15, 18, 20), s);
  c.drawPath(Path()..moveTo(25, 7)..quadraticBezierTo(23, 13, 25, 20), s);
  c.drawPath(Path()..moveTo(32, 10)..quadraticBezierTo(30, 15, 32, 20), s);
}

void _snack(Canvas c) {
  // Cookie: circle with a bite and chips.
  final p = _stroke(3);
  c.drawPath(
    Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(24, 26), radius: 15),
        -0.4,
        5.2,
      ),
    p,
  );
  // Bite arcs.
  c.drawPath(
    Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(38, 14), radius: 6),
        1.6,
        2.6,
      ),
    _stroke(2.6),
  );
  // Chips.
  final dot = Paint()..color = Colors.black;
  c.drawCircle(const Offset(19, 22), 2.2, dot);
  c.drawCircle(const Offset(28, 30), 2.2, dot);
  c.drawCircle(const Offset(18, 32), 1.8, dot);
  c.drawCircle(const Offset(27, 20), 1.6, dot);
}

Future<void> _savePng(
  void Function(Canvas) draw,
  String path,
  double scale,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);
  draw(canvas);
  final image = await recorder
      .endRecording()
      .toImage((48 * scale).round(), (48 * scale).round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('generate meal icon PNGs into assets/icons', () async {
    const glyphs = {
      'meal_breakfast': _breakfast,
      'meal_lunch': _lunch,
      'meal_dinner': _dinner,
      'meal_snack': _snack,
    };
    for (final e in glyphs.entries) {
      await _savePng(e.value, 'assets/icons/${e.key}.png', 1);
      await _savePng(e.value, 'assets/icons/2.0x/${e.key}.png', 2);
      await _savePng(e.value, 'assets/icons/3.0x/${e.key}.png', 3);
    }
  });
}
