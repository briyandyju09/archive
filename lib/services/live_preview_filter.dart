import 'package:flutter/material.dart';

import '../models/camera_profile.dart';

/// Builds a cheap, real-time approximation of a camera profile's look for
/// the live viewfinder (color grade + vignette + a few signature-effect
/// hints). The full pixel pipeline in `image_processor.dart` only runs
/// once, on the captured frame — this is just so the viewfinder already
/// feels like "looking through" the camera. Every hint here is a coarser,
/// cheaper stand-in for its full-pipeline counterpart, per this file's
/// existing "cheap approximation only" rule — never a claim of matching it
/// exactly.
class LivePreviewFilter extends StatelessWidget {
  final CameraProfile profile;
  final Widget child;

  const LivePreviewFilter({super.key, required this.profile, required this.child});

  static List<double> _colorMatrix(CameraProfile p) {
    const lumR = 0.213, lumG = 0.715, lumB = 0.072;
    final s = p.saturation;
    final sr = (1 - s) * lumR, sg = (1 - s) * lumG, sb = (1 - s) * lumB;
    final satRows = [
      [sr + s, sg, sb],
      [sr, sg + s, sb],
      [sr, sg, sb + s],
    ];
    final c = p.contrast;
    final scaled = satRows.map((row) => row.map((v) => v * c).toList()).toList();
    final contrastTranslate = 128 * (1 - c);
    final brightnessAdd = p.brightness * 180;
    final warmAdd = p.warmth * 22;
    // Coarse cross-process hint: a flat warm-red / cool-blue nudge across
    // the whole frame. The real effect splits by shadow/highlight
    // luminance per-pixel (see image_processor.dart's _applyCrossProcess)
    // — this is just enough of a live cue that the viewfinder isn't a
    // total surprise for cross-process cameras.
    final crossR = p.crossProcessAmount * 10;
    final crossB = p.crossProcessAmount * 8;
    final t = [
      contrastTranslate + brightnessAdd + warmAdd + crossR,
      contrastTranslate + brightnessAdd,
      contrastTranslate + brightnessAdd - warmAdd - crossB,
    ];
    return [
      scaled[0][0], scaled[0][1], scaled[0][2], 0, t[0],
      scaled[1][0], scaled[1][1], scaled[1][2], 0, t[1],
      scaled[2][0], scaled[2][1], scaled[2][2], 0, t[2],
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Chromatic aberration ghosting is the one hint expensive enough to
    // gate behind a threshold — only ever built for the one camera whose
    // profile actually calls for it.
    final content = profile.chromaticAberration > 0.15
        ? _ChromaticAberrationHint(amount: profile.chromaticAberration, child: child)
        : child;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_colorMatrix(profile)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (profile.vignetteStrength > 0.02)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: profile.vignetteStrength * 0.85),
                    ],
                    stops: const [0.55, 1.0],
                  ),
                ),
              ),
            ),
          if (profile.softness > 0.2)
            IgnorePointer(
              child: ColoredBox(color: Colors.white.withValues(alpha: profile.softness * 0.06)),
            ),
          if (profile.scanlineStrength > 0.05)
            IgnorePointer(
              child: CustomPaint(painter: _ScanlinePainter(strength: profile.scanlineStrength)),
            ),
          if (profile.lightLeakChance > 0.05)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.1,
                    colors: [
                      Colors.orange.withValues(alpha: (profile.lightLeakChance * 0.4).clamp(0.0, 0.3)),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A cheap real-time hint of chromatic aberration: two extra copies of the
/// preview, each isolated to a single channel and nudged a few pixels in
/// opposite directions, layered under reduced opacity. Far cheaper than the
/// capture pipeline's true per-pixel radial split — just enough of a live
/// cue for the one camera whose profile calls for it.
class _ChromaticAberrationHint extends StatelessWidget {
  final double amount;
  final Widget child;

  const _ChromaticAberrationHint({required this.amount, required this.child});

  static const _redOnly = ColorFilter.matrix([
    1, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 1, 0,
  ]);
  static const _blueOnly = ColorFilter.matrix([
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final shift = (amount * 3).clamp(1.0, 4.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: Opacity(
            opacity: 0.45,
            child: Transform.translate(
              offset: Offset(shift, 0),
              child: ColorFiltered(colorFilter: _redOnly, child: child),
            ),
          ),
        ),
        IgnorePointer(
          child: Opacity(
            opacity: 0.45,
            child: Transform.translate(
              offset: Offset(-shift, 0),
              child: ColorFiltered(colorFilter: _blueOnly, child: child),
            ),
          ),
        ),
      ],
    );
  }
}

/// A static repeating dark-row overlay hinting at the capture pipeline's
/// scanline/CRT artifact.
class _ScanlinePainter extends CustomPainter {
  final double strength;

  _ScanlinePainter({required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = (strength * 0.35).clamp(0.0, 0.5);
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: alpha)
      ..strokeWidth = 1;
    for (double y = 1; y < size.height; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) => oldDelegate.strength != strength;
}
