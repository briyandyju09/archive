import 'package:flutter/material.dart';

import '../models/camera_customization.dart';
import '../theme/app_skin_extension.dart';

/// A small stylized digicam silhouette, drawn in code so the collection
/// doesn't depend on sourced photography/icon assets. Body color reflects
/// the owned camera's customization. Carries a thin "engraved metal" edge
/// stroke and tighter corner rounding to match FIELD UNIT 04's 2-8px shape
/// language.
class CameraIcon extends StatelessWidget {
  final BodyColor? bodyColor;
  final bool locked;
  final double size;

  const CameraIcon({super.key, this.bodyColor, this.locked = false, this.size = 64});

  Color _bodyPaint(BuildContext context) {
    if (locked) return context.skin.graphite;
    return switch (bodyColor) {
      BodyColor.black => const Color(0xFF2B2B2E),
      BodyColor.pink => const Color(0xFFE49AAE),
      BodyColor.blue => const Color(0xFF5C82C4),
      BodyColor.white => const Color(0xFFF2EFE9),
      BodyColor.silver || null => const Color(0xFFB7BCC2),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CameraPainter(
          bodyColor: _bodyPaint(context),
          locked: locked,
          isDark: (bodyColor == BodyColor.black),
        ),
      ),
    );
  }
}

class _CameraPainter extends CustomPainter {
  final Color bodyColor;
  final bool locked;
  final bool isDark;

  _CameraPainter({required this.bodyColor, required this.locked, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bodyRect = Rect.fromLTWH(w * 0.06, h * 0.28, w * 0.88, h * 0.56);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.06));

    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawRRect(bodyRRect, bodyPaint);
    // Thin engraved-metal edge stroke, matching the panel/bezel border
    // treatment used everywhere else in this identity.
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );

    // top viewfinder bump
    final bumpRect = Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.3, h * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bumpRect, Radius.circular(w * 0.02)),
      bodyPaint,
    );

    // lens
    final lensCenter = Offset(w * 0.5, h * 0.56);
    final lensOuter = Paint()..color = (isDark ? Colors.black54 : const Color(0xFF3A3A3D));
    canvas.drawCircle(lensCenter, w * 0.2, lensOuter);
    canvas.drawCircle(lensCenter, w * 0.13, Paint()..color = const Color(0xFF16171A));
    canvas.drawCircle(
      lensCenter.translate(-w * 0.04, -h * 0.04),
      w * 0.035,
      Paint()..color = Colors.white.withValues(alpha: locked ? 0.15 : 0.55),
    );

    // flash square
    final flashRect = Rect.fromLTWH(w * 0.68, h * 0.36, w * 0.14, h * 0.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(flashRect, Radius.circular(w * 0.02)),
      Paint()..color = locked ? Colors.black26 : const Color(0xFFEFE6D0),
    );

    if (locked) {
      // subtle padlock hint
      final lockPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.85), width: w * 0.22, height: w * 0.22),
        3.4,
        2.7,
        false,
        lockPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.5, h * 0.92), width: w * 0.28, height: w * 0.16),
          Radius.circular(w * 0.03),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CameraPainter oldDelegate) =>
      oldDelegate.bodyColor != bodyColor || oldDelegate.locked != locked;
}
