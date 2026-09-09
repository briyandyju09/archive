import 'camera_profile.dart';

/// Firmware-style HUD readout strings derived from a [CameraProfile]'s
/// existing capture/processing characteristics.
///
/// This app has no real ISO, aperture, or exposure-time state — only static
/// spec text and the image-character knobs the pixel pipeline already uses.
/// Rather than overclaim real metering, every value here is computed once,
/// deterministically, from fields the profile already has: the same camera
/// always shows the same reading, never a per-frame/random flicker.
extension CameraReadout on CameraProfile {
  static final _apertureRe = RegExp(r'f/(\d+(\.\d+)?)');
  static const _isoLadder = [100, 200, 400, 800, 1600];
  static const _shutterLadder = ['1/500', '1/250', '1/125', '1/60', '1/30'];
  static const _apertureLadder = [2.8, 3.5, 4.0, 4.5, 5.6, 8.0];

  /// e.g. "F2.8" — parsed from the catalog's own lensInfo text where
  /// present (most profiles already write one, e.g. "3x optical, f/2.8-4.9"
  /// — the wide end is used); falls back to a value derived from the
  /// profile's shadowCrush character for the handful of fixed-focus
  /// profiles with no f-number in their lens text.
  String get apertureDisplay {
    final match = _apertureRe.firstMatch(lensInfo);
    if (match != null) {
      final f = double.tryParse(match.group(1)!);
      if (f != null) return 'F${_trimZero(f)}';
    }
    final synthetic = (2.8 + shadowCrush * 3.2).clamp(2.8, 8.0);
    final nearest = _apertureLadder.reduce(
      (a, b) => (a - synthetic).abs() <= (b - synthetic).abs() ? a : b,
    );
    return 'F${_trimZero(nearest)}';
  }

  /// e.g. "ISO 400" — noisier sensor character reads as higher ISO, matching
  /// the grain the pixel pipeline actually renders for this profile.
  String get isoDisplay {
    final index = (sensorNoise * (_isoLadder.length - 1)).round().clamp(0, _isoLadder.length - 1);
    return 'ISO ${_isoLadder[index]}';
  }

  /// e.g. "1/125" — ties two real fields together (a laggier, noisier
  /// sensor reads as a slower shutter) rather than inventing an unrelated
  /// value.
  String get shutterDisplay {
    final lagStep = (shutterLagMs / 120).round();
    final noiseStep = (sensorNoise * 3).round();
    final index = (lagStep + noiseStep).clamp(0, _shutterLadder.length - 1);
    return _shutterLadder[index];
  }

  /// e.g. "EV +0.3" — a direct, signed mapping of the profile's own
  /// brightness knob, rounded to the nearest third-stop.
  String get evDisplay {
    final raw = brightness * 2.0;
    final stepped = (raw / 0.3).round() * 0.3;
    final sign = stepped > 0 ? '+' : '';
    return 'EV $sign${stepped.toStringAsFixed(1)}';
  }

  /// e.g. "AWB" / "WB SUN" / "WB FLUO" — derived from the profile's warmth
  /// character.
  String get wbDisplay {
    if (warmth > 0.15) return 'WB SUN';
    if (warmth < -0.15) return 'WB FLUO';
    return 'AWB';
  }

  String _trimZero(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
