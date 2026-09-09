import 'package:flutter/material.dart';

import '../models/camera_customization.dart';
import '../models/camera_silhouette.dart';
import '../theme/app_skin_extension.dart';

/// A small stylized digicam silhouette, drawn in code so the collection
/// doesn't depend on sourced photography/icon assets. Body color reflects
/// the owned camera's customization; [silhouette] picks which archetype
/// shape is drawn — every camera model in the catalog gets a distinct body
/// instead of one shape reused everywhere. Carries a thin "engraved metal"
/// edge stroke and tighter corner rounding to match FIELD UNIT 04's 2-8px
/// shape language.
class CameraIcon extends StatelessWidget {
  final BodyColor? bodyColor;
  final bool locked;
  final double size;
  final CameraSilhouette silhouette;

  const CameraIcon({
    super.key,
    this.bodyColor,
    this.locked = false,
    this.size = 64,
    this.silhouette = CameraSilhouette.classicCompact,
  });

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
          silhouette: silhouette,
        ),
      ),
    );
  }
}

class _CameraPainter extends CustomPainter {
  final Color bodyColor;
  final bool locked;
  final bool isDark;
  final CameraSilhouette silhouette;

  _CameraPainter({
    required this.bodyColor,
    required this.locked,
    required this.isDark,
    required this.silhouette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    switch (silhouette) {
      case CameraSilhouette.classicCompact:
        _drawClassicCompact(canvas, w, h);
        break;
      case CameraSilhouette.boxyEntryLevel:
        _drawBoxyEntryLevel(canvas, w, h);
        break;
      case CameraSilhouette.slimBar:
        _drawSlimBar(canvas, w, h);
        break;
      case CameraSilhouette.chunkyBarrel:
        _drawChunkyBarrel(canvas, w, h);
        break;
      case CameraSilhouette.ruggedArmored:
        _drawRuggedArmored(canvas, w, h);
        break;
      case CameraSilhouette.cardboardBox:
        _drawCardboardBox(canvas, w, h);
        break;
      case CameraSilhouette.bridgeSLRHump:
        _drawBridgeSLRHump(canvas, w, h);
        break;
      case CameraSilhouette.floppyBlock:
        _drawFloppyBlock(canvas, w, h);
        break;
      case CameraSilhouette.instantSquare:
        _drawInstantSquare(canvas, w, h);
        break;
      case CameraSilhouette.actionCube:
        _drawActionCube(canvas, w, h);
        break;
      case CameraSilhouette.toyRound:
        _drawToyRound(canvas, w, h);
        break;
      case CameraSilhouette.panoramaWide:
        _drawPanoramaWide(canvas, w, h);
        break;
    }
    if (locked) _drawLockHint(canvas, w, h);
  }

  // --- Shared primitives, composed differently by each archetype below ---

  Paint get _bodyFill => Paint()..color = bodyColor;

  Paint get _edgeStroke => Paint()
    ..color = Colors.black.withValues(alpha: 0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  /// The body shell — a filled rounded rect plus a thin engraved-metal edge
  /// stroke, matching the panel/bezel border treatment used everywhere else
  /// in this identity. [strokeScale] widens the edge stroke for
  /// thicker-bezeled archetypes.
  void _bodyRRect(Canvas canvas, Rect rect, double radius, {double strokeScale = 1}) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, _bodyFill);
    canvas.drawRRect(
      rrect,
      _edgeStroke..strokeWidth = 0.8 * strokeScale * (rect.width / 64).clamp(0.5, 3),
    );
  }

  /// The classic lens: a dark outer ring, a near-black inner glass, and a
  /// small specular highlight — [ringScale] controls how large the outer
  /// ring reads relative to the body (a "barrel" just uses a bigger scale).
  void _lens(Canvas canvas, Offset center, double w, double h, {double ringScale = 0.2}) {
    final outer = Paint()..color = (isDark ? Colors.black54 : const Color(0xFF3A3A3D));
    canvas.drawCircle(center, w * ringScale, outer);
    canvas.drawCircle(center, w * ringScale * 0.65, Paint()..color = const Color(0xFF16171A));
    canvas.drawCircle(
      center.translate(-w * 0.04, -h * 0.04),
      w * 0.035,
      Paint()..color = Colors.white.withValues(alpha: locked ? 0.15 : 0.55),
    );
  }

  void _flashSquare(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.15)),
      Paint()..color = locked ? Colors.black26 : const Color(0xFFEFE6D0),
    );
  }

  void _viewfinderBump(Canvas canvas, Rect rect, {double radius = 0.02}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.width * radius)),
      _bodyFill,
    );
  }

  void _drawLockHint(Canvas canvas, double w, double h) {
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

  // --- Archetype recipes ---

  /// The original FIELD UNIT 04 shape: rounded body, small viewfinder bump,
  /// centered lens ring. Most mid-2000s point-and-shoots.
  void _drawClassicCompact(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.06, h * 0.28, w * 0.88, h * 0.56);
    _bodyRRect(canvas, bodyRect, w * 0.06);
    _viewfinderBump(canvas, Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.3, h * 0.18));
    _lens(canvas, Offset(w * 0.5, h * 0.56), w, h);
    _flashSquare(canvas, Rect.fromLTWH(w * 0.68, h * 0.36, w * 0.14, h * 0.1));
  }

  /// Chunkier, squarer body with a larger bump and no chrome trim — an
  /// entry-level first camera.
  void _drawBoxyEntryLevel(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.04, h * 0.24, w * 0.92, h * 0.62);
    _bodyRRect(canvas, bodyRect, w * 0.035);
    _viewfinderBump(canvas, Rect.fromLTWH(w * 0.14, h * 0.14, w * 0.4, h * 0.16), radius: 0.015);
    _lens(canvas, Offset(w * 0.5, h * 0.58), w, h, ringScale: 0.22);
    _flashSquare(canvas, Rect.fromLTWH(w * 0.7, h * 0.34, w * 0.16, h * 0.11));
  }

  /// A thin horizontal bar with no viewfinder bump and a flush, minimal lens
  /// ring — glossy metal ultra-compacts.
  void _drawSlimBar(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.05, h * 0.38, w * 0.9, h * 0.34);
    _bodyRRect(canvas, bodyRect, w * 0.07, strokeScale: 0.6);
    _lens(canvas, Offset(w * 0.28, h * 0.55), w, h, ringScale: 0.13);
    _flashSquare(canvas, Rect.fromLTWH(w * 0.72, h * 0.46, w * 0.12, h * 0.08));
  }

  /// A protruding front lens barrel proportionally much larger than the
  /// body — superzoom bridge-compacts.
  void _drawChunkyBarrel(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.06, h * 0.24, w * 0.88, h * 0.5);
    _bodyRRect(canvas, bodyRect, w * 0.05);
    _viewfinderBump(canvas, Rect.fromLTWH(w * 0.18, h * 0.14, w * 0.28, h * 0.14));
    // Barrel: a rounded rect protruding below the body, capped with the lens.
    final barrelRect = Rect.fromLTWH(w * 0.32, h * 0.5, w * 0.36, h * 0.36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barrelRect, Radius.circular(w * 0.06)),
      Paint()..color = (isDark ? const Color(0xFF1E1E20) : const Color(0xFF54585E)),
    );
    _lens(canvas, Offset(w * 0.5, h * 0.72), w, h, ringScale: 0.24);
  }

  /// Thicker bezel with rubberized corner bumpers — waterproof/rugged and
  /// toy-class bodies built to survive drops.
  void _drawRuggedArmored(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.05, h * 0.26, w * 0.9, h * 0.56);
    _bodyRRect(canvas, bodyRect, w * 0.05, strokeScale: 2.2);
    _viewfinderBump(canvas, Rect.fromLTWH(w * 0.17, h * 0.16, w * 0.26, h * 0.14));
    _lens(canvas, Offset(w * 0.5, h * 0.55), w, h, ringScale: 0.19);
    _flashSquare(canvas, Rect.fromLTWH(w * 0.68, h * 0.34, w * 0.13, h * 0.1));
    final bumperPaint = Paint()..color = Colors.black.withValues(alpha: locked ? 0.15 : 0.35);
    for (final corner in [bodyRect.topLeft, bodyRect.topRight, bodyRect.bottomLeft, bodyRect.bottomRight]) {
      canvas.drawCircle(corner, w * 0.05, bumperPaint);
    }
  }

  /// Square-edged, no lens ring detail, no viewfinder bump — a cheap
  /// disposable shell.
  void _drawCardboardBox(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.08, h * 0.3, w * 0.84, h * 0.5);
    _bodyRRect(canvas, bodyRect, w * 0.015);
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.55),
      w * 0.15,
      Paint()..color = const Color(0xFF16171A),
    );
  }

  /// An SLR-style viewfinder hump plus a swivel-lens hint — 2000s
  /// prosumer/bridge cameras.
  void _drawBridgeSLRHump(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.06, h * 0.34, w * 0.88, h * 0.48);
    _bodyRRect(canvas, bodyRect, w * 0.05);
    // Wider/taller hump than the classic bump, centered.
    _viewfinderBump(canvas, Rect.fromLTWH(w * 0.3, h * 0.14, w * 0.4, h * 0.22), radius: 0.03);
    // Swivel-lens hint: lens barrel drawn slightly rotated off the body's
    // main axis.
    canvas.save();
    canvas.translate(w * 0.5, h * 0.62);
    canvas.rotate(-0.12);
    canvas.translate(-w * 0.5, -h * 0.62);
    _lens(canvas, Offset(w * 0.5, h * 0.62), w, h, ringScale: 0.23);
    canvas.restore();
  }

  /// A boxy body with a floppy-disk slot notch along one edge — the
  /// earliest floppy-based digicams.
  void _drawFloppyBlock(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.05, h * 0.26, w * 0.9, h * 0.58);
    _bodyRRect(canvas, bodyRect, w * 0.03);
    _viewfinderBump(canvas, Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.28, h * 0.14));
    _lens(canvas, Offset(w * 0.34, h * 0.56), w, h, ringScale: 0.17);
    // Floppy-disk slot: a thin dark notch along the right edge.
    final slotRect = Rect.fromLTWH(w * 0.72, h * 0.36, w * 0.16, h * 0.32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(slotRect, Radius.circular(w * 0.015)),
      Paint()..color = Colors.black.withValues(alpha: locked ? 0.2 : 0.45),
    );
  }

  /// A square body with a bottom print-slot line — instant-hybrid cameras
  /// that eject a physical print.
  void _drawInstantSquare(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.1, h * 0.16, w * 0.8, h * 0.68);
    _bodyRRect(canvas, bodyRect, w * 0.04);
    _lens(canvas, Offset(w * 0.5, h * 0.42), w, h, ringScale: 0.2);
    // Print-slot: a thin horizontal line near the bottom edge.
    final slotRect = Rect.fromLTWH(w * 0.22, h * 0.72, w * 0.56, h * 0.035);
    canvas.drawRRect(
      RRect.fromRectAndRadius(slotRect, Radius.circular(w * 0.01)),
      Paint()..color = Colors.black.withValues(alpha: locked ? 0.15 : 0.4),
    );
  }

  /// A small cube body with a dome-shaped wide lens — wearable action
  /// cameras.
  void _drawActionCube(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.2, h * 0.24, w * 0.6, h * 0.56);
    _bodyRRect(canvas, bodyRect, w * 0.06, strokeScale: 1.6);
    // Dome lens fills most of the front face.
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.52),
      w * 0.24,
      Paint()..color = (isDark ? Colors.black54 : const Color(0xFF3A3A3D)),
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.16, Paint()..color = const Color(0xFF16171A));
    canvas.drawCircle(
      Offset(w * 0.44, h * 0.46),
      w * 0.045,
      Paint()..color = Colors.white.withValues(alpha: locked ? 0.15 : 0.6),
    );
  }

  /// Oversized rounded corners and a chunky handle nub — kids'/toy cameras.
  void _drawToyRound(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.08, h * 0.3, w * 0.84, h * 0.54);
    _bodyRRect(canvas, bodyRect, w * 0.14, strokeScale: 1.4);
    // Chunky handle nub on top.
    final nubRect = Rect.fromLTWH(w * 0.36, h * 0.16, w * 0.28, h * 0.16);
    canvas.drawRRect(RRect.fromRectAndRadius(nubRect, Radius.circular(w * 0.08)), _bodyFill);
    _lens(canvas, Offset(w * 0.5, h * 0.56), w, h, ringScale: 0.21);
    _flashSquare(canvas, Rect.fromLTWH(w * 0.66, h * 0.4, w * 0.15, h * 0.11));
  }

  /// A wider, flatter body with a small offset lens — panorama-era
  /// superzoom compacts.
  void _drawPanoramaWide(Canvas canvas, double w, double h) {
    final bodyRect = Rect.fromLTWH(w * 0.02, h * 0.36, w * 0.96, h * 0.34);
    _bodyRRect(canvas, bodyRect, w * 0.04);
    _lens(canvas, Offset(w * 0.32, h * 0.53), w, h, ringScale: 0.15);
    _flashSquare(canvas, Rect.fromLTWH(w * 0.74, h * 0.42, w * 0.13, h * 0.09));
  }

  @override
  bool shouldRepaint(covariant _CameraPainter oldDelegate) =>
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.locked != locked ||
      oldDelegate.silhouette != silhouette;
}
