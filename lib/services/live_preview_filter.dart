import 'package:flutter/material.dart';

import '../models/camera_profile.dart';

/// Builds a cheap, real-time approximation of a camera profile's look for
/// the live viewfinder (color grade + vignette). The full pixel pipeline in
/// `image_processor.dart` only runs once, on the captured frame — this is
/// just so the viewfinder already feels like "looking through" the camera.
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
    final t = [
      contrastTranslate + brightnessAdd + warmAdd,
      contrastTranslate + brightnessAdd,
      contrastTranslate + brightnessAdd - warmAdd,
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
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_colorMatrix(profile)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
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
        ],
      ),
    );
  }
}
