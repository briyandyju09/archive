import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_skin_extension.dart';

/// Drawn glyph set for FIELD UNIT 04, extending the app's existing
/// "no sourced icon packs — draw everything in code" principle (already
/// established by CameraIcon) across every device-chrome context. All
/// glyphs are monochrome, stroke-based (1.5–2px), with the same 2–4px
/// corner language as the rest of the shape system — never a Material
/// [Icons.*] glyph and never an emoji standing in for one.
enum DeviceGlyph {
  flashAuto,
  flashOn,
  flashOff,
  filmRoll,
  rec,
  chevronLeft,
  chevronRight,
  chevronBack,
  info,
  delete,
  warning,
  aperture,
  cameraBody,
  unknownUnit,
  shutterRelease,
  zoomOut,
  zoomIn,
  skinSwap,
}

class DeviceIcon extends StatelessWidget {
  final DeviceGlyph glyph;
  final double size;
  final Color? color;
  final double strokeWidth;

  const DeviceIcon(this.glyph, {super.key, this.size = 20, this.color, this.strokeWidth = 1.6});

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? context.skin.lcdWhite;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GlyphPainter(glyph, resolved, strokeWidth)),
    );
  }
}

/// A 4-bar battery indicator, fill proportional to [percent] (0..100).
class BatteryGlyph extends StatelessWidget {
  final double percent;
  final double size;
  final Color? color;

  const BatteryGlyph({super.key, required this.percent, this.size = 18, this.color});

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? context.skin.lcdWhite;
    return SizedBox(
      width: size * 1.3,
      height: size,
      child: CustomPaint(painter: _BatteryPainter(percent: percent, color: resolved)),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final double percent;
  final Color color;

  _BatteryPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final bodyRect = Rect.fromLTWH(0, h * 0.1, w * 0.85, h * 0.8);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(1.5)), stroke);
    final capRect = Rect.fromLTWH(w * 0.87, h * 0.32, w * 0.1, h * 0.36);
    canvas.drawRRect(RRect.fromRectAndRadius(capRect, const Radius.circular(1)), Paint()..color = color);

    final bars = (percent / 25).ceil().clamp(0, 4);
    final fill = Paint()..color = color;
    const gap = 1.5;
    final barW = (bodyRect.width - gap * 5) / 4;
    for (var i = 0; i < bars; i++) {
      final left = bodyRect.left + gap + i * (barW + gap);
      final barRect = Rect.fromLTWH(left, bodyRect.top + gap, barW, bodyRect.height - gap * 2);
      canvas.drawRect(barRect, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}

class _GlyphPainter extends CustomPainter {
  final DeviceGlyph glyph;
  final Color color;
  final double strokeWidth;

  _GlyphPainter(this.glyph, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    switch (glyph) {
      case DeviceGlyph.flashAuto:
      case DeviceGlyph.flashOn:
      case DeviceGlyph.flashOff:
        _drawFlash(canvas, w, h, stroke, fill);
        break;
      case DeviceGlyph.filmRoll:
        _drawFilmRoll(canvas, w, h, stroke);
        break;
      case DeviceGlyph.rec:
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.4, fill);
        break;
      case DeviceGlyph.chevronLeft:
        _drawChevron(canvas, w, h, stroke, pointLeft: true);
        break;
      case DeviceGlyph.chevronRight:
        _drawChevron(canvas, w, h, stroke, pointLeft: false);
        break;
      case DeviceGlyph.chevronBack:
        _drawBack(canvas, w, h, stroke);
        break;
      case DeviceGlyph.info:
        _drawInfo(canvas, w, h, stroke, fill);
        break;
      case DeviceGlyph.delete:
        _drawDelete(canvas, w, h, stroke);
        break;
      case DeviceGlyph.warning:
        _drawWarning(canvas, w, h, stroke, fill);
        break;
      case DeviceGlyph.aperture:
        _drawAperture(canvas, w, h, stroke);
        break;
      case DeviceGlyph.cameraBody:
        _drawCameraBody(canvas, w, h, stroke);
        break;
      case DeviceGlyph.unknownUnit:
        _drawUnknownUnit(canvas, w, h, stroke);
        break;
      case DeviceGlyph.shutterRelease:
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.38, stroke);
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.16, fill);
        break;
      case DeviceGlyph.zoomOut:
        canvas.drawLine(Offset(w * 0.2, h / 2), Offset(w * 0.8, h / 2), stroke);
        break;
      case DeviceGlyph.zoomIn:
        canvas.drawLine(Offset(w * 0.2, h / 2), Offset(w * 0.8, h / 2), stroke);
        canvas.drawLine(Offset(w / 2, h * 0.2), Offset(w / 2, h * 0.8), stroke);
        break;
      case DeviceGlyph.skinSwap:
        _drawSkinSwap(canvas, w, h, stroke);
        break;
    }
  }

  void _drawFlash(Canvas canvas, double w, double h, Paint stroke, Paint fill) {
    final path = Path()
      ..moveTo(w * 0.55, h * 0.12)
      ..lineTo(w * 0.28, h * 0.58)
      ..lineTo(w * 0.46, h * 0.58)
      ..lineTo(w * 0.40, h * 0.88)
      ..lineTo(w * 0.72, h * 0.40)
      ..lineTo(w * 0.52, h * 0.40)
      ..close();
    canvas.drawPath(path, glyph == DeviceGlyph.flashOn ? fill : stroke);
    if (glyph == DeviceGlyph.flashOff) {
      canvas.drawLine(Offset(w * 0.15, h * 0.15), Offset(w * 0.85, h * 0.85), stroke);
    }
    if (glyph == DeviceGlyph.flashAuto) {
      final dot = Paint()..color = stroke.color;
      canvas.drawCircle(Offset(w * 0.82, h * 0.2), w * 0.06, dot);
    }
  }

  void _drawFilmRoll(Canvas canvas, double w, double h, Paint stroke) {
    final rect = Rect.fromLTWH(w * 0.14, h * 0.22, w * 0.72, h * 0.56);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.05)), stroke);
    for (final fx in [0.32, 0.5, 0.68]) {
      canvas.drawLine(Offset(w * fx, h * 0.22), Offset(w * fx, h * 0.78), stroke);
    }
  }

  void _drawChevron(Canvas canvas, double w, double h, Paint stroke, {required bool pointLeft}) {
    final tipX = pointLeft ? w * 0.36 : w * 0.64;
    final baseX = pointLeft ? w * 0.64 : w * 0.36;
    final path = Path()
      ..moveTo(baseX, h * 0.25)
      ..lineTo(tipX, h * 0.5)
      ..lineTo(baseX, h * 0.75);
    canvas.drawPath(path, stroke);
  }

  void _drawBack(Canvas canvas, double w, double h, Paint stroke) {
    final path = Path()
      ..moveTo(w * 0.62, h * 0.22)
      ..lineTo(w * 0.32, h * 0.5)
      ..lineTo(w * 0.62, h * 0.78);
    canvas.drawPath(path, stroke);
    canvas.drawLine(Offset(w * 0.34, h * 0.5), Offset(w * 0.8, h * 0.5), stroke);
  }

  void _drawInfo(Canvas canvas, double w, double h, Paint stroke, Paint fill) {
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.38, stroke);
    canvas.drawCircle(Offset(w / 2, h * 0.32), w * 0.045, fill);
    canvas.drawLine(Offset(w / 2, h * 0.46), Offset(w / 2, h * 0.7), stroke);
  }

  void _drawDelete(Canvas canvas, double w, double h, Paint stroke) {
    final rect = Rect.fromLTWH(w * 0.28, h * 0.32, w * 0.44, h * 0.48);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.03)), stroke);
    canvas.drawLine(Offset(w * 0.22, h * 0.28), Offset(w * 0.78, h * 0.28), stroke);
    canvas.drawLine(Offset(w * 0.4, h * 0.2), Offset(w * 0.6, h * 0.2), stroke);
  }

  void _drawWarning(Canvas canvas, double w, double h, Paint stroke, Paint fill) {
    final path = Path()
      ..moveTo(w * 0.5, h * 0.14)
      ..lineTo(w * 0.88, h * 0.82)
      ..lineTo(w * 0.12, h * 0.82)
      ..close();
    canvas.drawPath(path, stroke);
    canvas.drawLine(Offset(w * 0.5, h * 0.4), Offset(w * 0.5, h * 0.62), stroke);
    canvas.drawCircle(Offset(w * 0.5, h * 0.72), w * 0.03, fill);
  }

  void _drawAperture(Canvas canvas, double w, double h, Paint stroke) {
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.38, stroke);
    const blades = 6;
    for (var i = 0; i < blades; i++) {
      final angle = (i / blades) * math.pi * 2;
      final cx = w / 2 + w * 0.16 * math.cos(angle);
      final cy = h / 2 + h * 0.16 * math.sin(angle);
      canvas.drawLine(Offset(w / 2, h / 2), Offset(cx, cy), stroke);
    }
  }

  void _drawCameraBody(Canvas canvas, double w, double h, Paint stroke) {
    final body = Rect.fromLTWH(w * 0.12, h * 0.32, w * 0.76, h * 0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(w * 0.06)), stroke);
    canvas.drawCircle(Offset(w / 2, h * 0.57), w * 0.16, stroke);
    final bump = Rect.fromLTWH(w * 0.3, h * 0.2, w * 0.24, h * 0.14);
    canvas.drawRRect(RRect.fromRectAndRadius(bump, Radius.circular(w * 0.02)), stroke);
  }

  void _drawSkinSwap(Canvas canvas, double w, double h, Paint stroke) {
    // A small camera-body silhouette (reusing _drawCameraBody's own
    // proportions, scaled down) with two short curved "cycle" arrows
    // circling it — the swap-the-body cue, distinct from the plain
    // cameraBody glyph.
    canvas.save();
    canvas.translate(w * 0.22, h * 0.22);
    canvas.scale(0.56);
    _drawCameraBody(canvas, w, h, stroke);
    canvas.restore();

    final arcRect = Rect.fromCircle(center: Offset(w / 2, h / 2), radius: w * 0.46);
    canvas.drawArc(arcRect, -0.5, 1.9, false, stroke);
    canvas.drawArc(arcRect, math.pi - 0.5, 1.9, false, stroke);
    // Arrowhead ticks at each arc's leading end.
    final tip1 = Offset(w / 2 + w * 0.46 * math.cos(1.4), h / 2 + w * 0.46 * math.sin(1.4));
    canvas.drawLine(tip1, tip1.translate(-w * 0.07, -w * 0.02), stroke);
    canvas.drawLine(tip1, tip1.translate(-w * 0.02, w * 0.07), stroke);
    final tip2 = Offset(w / 2 + w * 0.46 * math.cos(math.pi + 1.4), h / 2 + w * 0.46 * math.sin(math.pi + 1.4));
    canvas.drawLine(tip2, tip2.translate(w * 0.07, w * 0.02), stroke);
    canvas.drawLine(tip2, tip2.translate(w * 0.02, -w * 0.07), stroke);
  }

  void _drawUnknownUnit(Canvas canvas, double w, double h, Paint stroke) {
    // A dashed/segmented outline suggesting an unidentified device.
    final rect = Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.6, h * 0.6);
    const dash = 6.0, gap = 5.0;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.04));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), stroke);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
