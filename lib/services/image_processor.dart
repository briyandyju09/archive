import 'dart:math';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/camera_profile.dart';
import '../models/camera_skin.dart';

/// Whether/how the flash was dialed in for this shot. `auto` fires based on
/// how dark the actual captured frame turned out to be, decided during
/// processing rather than guessed ahead of time.
enum ShotFlashMode { off, auto, forced }

/// Everything the pixel pipeline needs, flattened to primitives so the whole
/// job can cross the `compute()` isolate boundary cheaply.
class ProcessJob {
  final Uint8List jpegBytes;
  final double aspectRatio;
  final double megapixels;
  final double saturation;
  final double contrast;
  final double brightness;
  final double warmth;
  final double sensorNoise;
  final double sharpenAmount;
  final double vignetteStrength;
  final double bloomAmount;
  final double highlightClip;
  final double shadowCrush;
  final double lensDistortion;
  final double softness;
  final double extraBlur; // digital-zoom quality falloff, 0..1
  final ShotFlashMode flashMode;
  final double flashStrength;
  final double redEyeChance;
  final double fingerOverLensChance;
  final String dateStampText;
  final int dateStampColorValue; // ARGB32 — a Color, flattened for the isolate boundary
  final int seed;

  const ProcessJob({
    required this.jpegBytes,
    required this.aspectRatio,
    required this.megapixels,
    required this.saturation,
    required this.contrast,
    required this.brightness,
    required this.warmth,
    required this.sensorNoise,
    required this.sharpenAmount,
    required this.vignetteStrength,
    required this.bloomAmount,
    required this.highlightClip,
    required this.shadowCrush,
    required this.lensDistortion,
    required this.softness,
    required this.extraBlur,
    required this.flashMode,
    required this.flashStrength,
    required this.redEyeChance,
    required this.fingerOverLensChance,
    required this.dateStampText,
    this.dateStampColorValue = 0xFFFF8C1E,
    required this.seed,
  });

  /// The original, skin-less factory — every knob straight from the
  /// profile. Kept alongside [fromProfileAndSkin] (not replaced by it) for
  /// any caller that has no skin to blend in.
  factory ProcessJob.fromProfile({
    required Uint8List jpegBytes,
    required CameraProfile profile,
    required ShotFlashMode flashMode,
    required String dateStampText,
    double extraBlur = 0,
    int? seed,
  }) {
    return ProcessJob(
      jpegBytes: jpegBytes,
      aspectRatio: profile.aspectRatio.ratio,
      megapixels: profile.megapixels,
      saturation: profile.saturation,
      contrast: profile.contrast,
      brightness: profile.brightness,
      warmth: profile.warmth,
      sensorNoise: profile.sensorNoise,
      sharpenAmount: profile.sharpenAmount,
      vignetteStrength: profile.vignetteStrength,
      bloomAmount: profile.bloomAmount,
      highlightClip: profile.highlightClip,
      shadowCrush: profile.shadowCrush,
      lensDistortion: profile.lensDistortion,
      softness: profile.softness,
      extraBlur: extraBlur.clamp(0, 1),
      flashMode: flashMode,
      flashStrength: profile.flashStrength,
      redEyeChance: profile.redEyeChance,
      fingerOverLensChance: profile.fingerOverLensChance,
      dateStampText: dateStampText,
      seed: seed ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Blends a [CameraSkin]'s processing-tilt deltas on top of a camera's own
  /// knobs (nudging, never overriding — the skin's "coat of paint," not a
  /// different camera) and uses the skin's own date-stamp tint. Hardware/
  /// optical traits (lens distortion, flash strength, red-eye chance,
  /// finger-over-lens) are left untouched — those are the camera's
  /// physical identity, not a skin's.
  factory ProcessJob.fromProfileAndSkin({
    required Uint8List jpegBytes,
    required CameraProfile profile,
    required CameraSkin skin,
    required ShotFlashMode flashMode,
    required String dateStampText,
    double extraBlur = 0,
    int? seed,
  }) {
    double blend(double base, double delta, double lo, double hi) => (base + delta).clamp(lo, hi);
    return ProcessJob(
      jpegBytes: jpegBytes,
      aspectRatio: profile.aspectRatio.ratio,
      megapixels: profile.megapixels,
      saturation: blend(profile.saturation, skin.saturationDelta, 0.0, 2.0),
      contrast: blend(profile.contrast, skin.contrastDelta, 0.0, 2.0),
      brightness: blend(profile.brightness, skin.brightnessDelta, -0.6, 0.6),
      warmth: blend(profile.warmth, skin.warmthDelta, -1.0, 1.0),
      sensorNoise: blend(profile.sensorNoise, skin.sensorNoiseDelta, 0.0, 1.0),
      sharpenAmount: blend(profile.sharpenAmount, skin.sharpenDelta, 0.0, 1.0),
      vignetteStrength: blend(profile.vignetteStrength, skin.vignetteDelta, 0.0, 1.0),
      bloomAmount: blend(profile.bloomAmount, skin.bloomDelta, 0.0, 1.0),
      highlightClip: blend(profile.highlightClip, skin.highlightClipDelta, 0.0, 1.0),
      shadowCrush: blend(profile.shadowCrush, skin.shadowCrushDelta, 0.0, 1.0),
      lensDistortion: profile.lensDistortion, // untouched — optical/hardware trait
      softness: blend(profile.softness, skin.softnessDelta, 0.0, 1.0),
      extraBlur: extraBlur.clamp(0, 1),
      flashMode: flashMode,
      flashStrength: profile.flashStrength, // untouched — hardware trait
      redEyeChance: profile.redEyeChance, // untouched — hardware trait
      fingerOverLensChance: profile.fingerOverLensChance, // untouched — easter-egg quirk
      dateStampText: dateStampText,
      dateStampColorValue: skin.dateStampColor.toARGB32(),
      seed: seed ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class ProcessedPhoto {
  final Uint8List fullJpeg;
  final Uint8List thumbJpeg;
  final int width;
  final int height;

  const ProcessedPhoto({
    required this.fullJpeg,
    required this.thumbJpeg,
    required this.width,
    required this.height,
  });
}

/// Runs a captured JPEG through a camera profile's full processing pipeline.
/// Heavy enough to run on a background isolate via [compute].
Future<ProcessedPhoto> processCapture(ProcessJob job) => compute(_process, job);

ProcessedPhoto _process(ProcessJob job) {
  final decoded = img.decodeImage(job.jpegBytes);
  if (decoded == null) {
    throw const FormatException('Could not decode captured frame');
  }
  final rnd = Random(job.seed);
  var image = decoded;

  // 1. Crop to the profile's aspect ratio (centered).
  image = _cropToAspect(image, job.aspectRatio);

  // 2. Downsample to the profile's effective resolution.
  final targetPixels = job.megapixels * 1000000;
  final targetWidth = sqrt(targetPixels * job.aspectRatio).round().clamp(160, image.width);
  if (targetWidth < image.width) {
    image = img.copyResize(image, width: targetWidth, interpolation: img.Interpolation.average);
  }

  // 3. Color science: contrast/saturation/brightness via the library, warmth
  // by hand (per-channel push), all in one pass together with the
  // highlight/shadow tone curve and flash brightening.
  image = img.adjustColor(
    image,
    contrast: job.contrast,
    saturation: job.saturation,
    brightness: (1.0 + job.brightness).clamp(0.0, 3.0),
  );
  _applyToneAndWarmth(image, job);

  // 4. Bloom: blur the bright areas and screen them back on top for a CCD
  // highlight glow.
  if (job.bloomAmount > 0.02) {
    image = _applyBloom(image, job.bloomAmount);
  }

  // 5. Lens softness / zoom quality falloff.
  final blurRadius = ((job.softness + job.extraBlur) * 3.5).round();
  if (blurRadius > 0) {
    image = img.gaussianBlur(image, radius: blurRadius.clamp(0, 8));
  }

  // 6. Lens distortion (barrel bulge / mild pincushion).
  if (job.lensDistortion.abs() > 0.02) {
    image = img.bulgeDistortion(
      image,
      scale: job.lensDistortion * 0.35,
      interpolation: img.Interpolation.linear,
    );
  }

  // 7. Sensor noise.
  if (job.sensorNoise > 0.01) {
    image = img.noise(image, job.sensorNoise * 45, type: img.NoiseType.gaussian, random: rnd);
  }

  // 8. Sharpen / oversharpen via an unsharp-mask style 3x3 convolution.
  if (job.sharpenAmount > 0.01) {
    image = img.convolution(
      image,
      filter: const [0, -1, 0, -1, 5, -1, 0, -1, 0],
      amount: job.sharpenAmount.clamp(0, 1),
    );
  }

  // 9. Vignette.
  if (job.vignetteStrength > 0.01) {
    image = img.vignette(image, start: 0.25, end: 0.95, amount: job.vignetteStrength);
  }

  // 10. Flash: fires immediately if forced, never if off, and for auto
  // mode based on how dark the actual captured frame is. Center
  // brightening + optional stylized red-eye when it fires.
  final flashFired = switch (job.flashMode) {
    ShotFlashMode.forced => true,
    ShotFlashMode.off => false,
    ShotFlashMode.auto => _averageLuminance(image) < 0.35,
  };
  if (flashFired && job.flashStrength > 0.01) {
    _applyFlash(image, job.flashStrength);
    if (rnd.nextDouble() < job.redEyeChance) {
      _drawRedEye(image, rnd);
    }
  }

  // 11. Easter-egg gag: a finger creeping over the edge of the lens.
  if (rnd.nextDouble() < job.fingerOverLensChance) {
    _drawFingerOverLens(image, rnd);
  }

  // 12. Date stamp.
  if (job.dateStampText.isNotEmpty) {
    _drawDateStamp(image, job.dateStampText, job.dateStampColorValue);
  }

  final thumb = img.copyResize(image, width: min(360, image.width));

  return ProcessedPhoto(
    fullJpeg: Uint8List.fromList(img.encodeJpg(image, quality: 90)),
    thumbJpeg: Uint8List.fromList(img.encodeJpg(thumb, quality: 78)),
    width: image.width,
    height: image.height,
  );
}

img.Image _cropToAspect(img.Image src, double aspect) {
  final currentAspect = src.width / src.height;
  int x = 0, y = 0, w = src.width, h = src.height;
  if (currentAspect > aspect) {
    w = (src.height * aspect).round();
    x = ((src.width - w) / 2).round();
  } else if (currentAspect < aspect) {
    h = (src.width / aspect).round();
    y = ((src.height - h) / 2).round();
  }
  if (w == src.width && h == src.height) return src;
  return img.copyCrop(src, x: x, y: y, width: w, height: h);
}

void _applyToneAndWarmth(img.Image image, ProcessJob job) {
  final warm = job.warmth.clamp(-1.0, 1.0);
  final highlightClip = job.highlightClip.clamp(0.0, 1.0);
  final shadowCrush = job.shadowCrush.clamp(0.0, 1.0);
  for (final frame in image.frames) {
    for (final p in frame) {
      var r = p.r.toDouble();
      var g = p.g.toDouble();
      var b = p.b.toDouble();

      if (warm != 0) {
        r *= 1 + warm * 0.18;
        b *= 1 - warm * 0.18;
      }

      final lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
      if (lum > 1 - highlightClip * 0.5 && highlightClip > 0) {
        final t = (lum - (1 - highlightClip * 0.5)) / max(0.001, highlightClip * 0.5);
        final boost = 1 + t * highlightClip * 0.8;
        r *= boost;
        g *= boost;
        b *= boost;
      }
      if (lum < shadowCrush * 0.35 && shadowCrush > 0) {
        final t = 1 - (lum / max(0.001, shadowCrush * 0.35));
        final crush = 1 - t * shadowCrush * 0.9;
        r *= crush;
        g *= crush;
        b *= crush;
      }

      p.r = r.clamp(0, 255);
      p.g = g.clamp(0, 255);
      p.b = b.clamp(0, 255);
    }
  }
}

img.Image _applyBloom(img.Image image, double amount) {
  final bright = img.Image.from(image);
  for (final frame in bright.frames) {
    for (final p in frame) {
      final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b) / 255.0;
      if (lum < 0.72) {
        p.r = 0;
        p.g = 0;
        p.b = 0;
      }
    }
  }
  final blurred = img.gaussianBlur(bright, radius: (amount * 10).round().clamp(2, 14));
  return img.compositeImage(image, blurred, blend: img.BlendMode.screen);
}

double _averageLuminance(img.Image image) {
  double sum = 0;
  int count = 0;
  for (var y = 0; y < image.height; y += 5) {
    for (var x = 0; x < image.width; x += 5) {
      final p = image.getPixel(x, y);
      sum += (0.299 * p.r + 0.587 * p.g + 0.114 * p.b) / 255.0;
      count++;
    }
  }
  return count == 0 ? 1.0 : sum / count;
}

void _applyFlash(img.Image image, double strength) {
  final w = image.width, h = image.height;
  final cx = w / 2, cy = h / 2;
  final maxDist = sqrt(cx * cx + cy * cy);
  for (final frame in image.frames) {
    for (final p in frame) {
      final dx = p.x - cx, dy = p.y - cy;
      final dist = sqrt(dx * dx + dy * dy) / maxDist;
      final falloff = (1 - dist).clamp(0.0, 1.0);
      final boost = 1 + falloff * strength * 0.9;
      p.r = (p.r * boost).clamp(0, 255);
      p.g = (p.g * boost).clamp(0, 255);
      p.b = (p.b * boost).clamp(0, 255);
    }
  }
}

void _drawRedEye(img.Image image, Random rnd) {
  final cx = image.width * (0.42 + rnd.nextDouble() * 0.16);
  final cy = image.height * (0.32 + rnd.nextDouble() * 0.12);
  final r = max(2, (image.width * 0.012).round());
  final spacing = image.width * 0.09;
  final color = img.ColorRgba8(200, 20, 20, 160);
  img.fillCircle(image, x: cx.round(), y: cy.round(), radius: r, color: color);
  img.fillCircle(image, x: (cx + spacing).round(), y: cy.round(), radius: r, color: color);
}

void _drawFingerOverLens(img.Image image, Random rnd) {
  final w = image.width, h = image.height;
  final fromLeft = rnd.nextBool();
  final color = img.ColorRgba8(15, 12, 10, 210);
  final baseX = fromLeft ? -w * 0.05 : w * 1.05;
  for (var i = 0; i < 5; i++) {
    final t = i / 4;
    final x = baseX + (fromLeft ? 1 : -1) * w * 0.22 * t;
    final y = h * (0.55 + rnd.nextDouble() * 0.15 - 0.075);
    final r = (w * (0.16 - t * 0.05)).round();
    img.fillCircle(image, x: x.round(), y: y.round(), radius: r, color: color);
  }
}

void _drawDateStamp(img.Image image, String text, int colorValue) {
  final font = image.width > 1400
      ? img.arial48
      : (image.width > 700 ? img.arial24 : img.arial14);
  final c = Color(colorValue);
  final color = img.ColorRgba8(
    (c.r * 255).round(),
    (c.g * 255).round(),
    (c.b * 255).round(),
    235, // keep the original stamp's fixed alpha regardless of skin
  );
  final margin = (image.width * 0.02).round().clamp(6, 40);
  img.drawString(
    image,
    text,
    font: font,
    x: image.width - margin,
    y: image.height - margin - font.lineHeight,
    color: color,
    rightJustify: true,
  );
}
