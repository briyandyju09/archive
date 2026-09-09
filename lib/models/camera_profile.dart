import 'camera_silhouette.dart';
import 'rarity.dart';

export 'camera_silhouette.dart';

/// Output frame shape a profile shoots in.
enum CameraAspectRatio { r4x3, r3x2, r1x1 }

extension CameraAspectRatioX on CameraAspectRatio {
  double get ratio => switch (this) {
    CameraAspectRatio.r4x3 => 4 / 3,
    CameraAspectRatio.r3x2 => 3 / 2,
    CameraAspectRatio.r1x1 => 1,
  };

  String get label => switch (this) {
    CameraAspectRatio.r4x3 => '4:3',
    CameraAspectRatio.r3x2 => '3:2',
    CameraAspectRatio.r1x1 => '1:1',
  };
}

/// What flash modes a physical camera of this type actually supports.
enum FlashCapability { autoOffOn, alwaysOn, none }

/// Static, immutable description of one virtual camera "model". This is the
/// catalog entry — an [OwnedCamera] is a user's personalized instance of one.
class CameraProfile {
  final String id;
  final String name;
  final int year;
  final double megapixels;
  final String sensorType;
  final String lensInfo;
  final String flashInfo;
  final String description;
  final Rarity rarity;
  final bool isEasterEgg;
  final bool isStarter;

  // --- Capture behavior ---
  final CameraAspectRatio aspectRatio;
  final double maxDigitalZoom;
  final double digitalZoomQuality; // 0..1, 1 = crisp all the way, 0 = mush past 1x
  final int shutterLagMs;
  final int startupAnimationMs;
  final FlashCapability flashCapability;
  final double flashStrength; // 0..1
  final double redEyeChance; // 0..1 chance per forced/fired flash shot
  final bool defaultDateStampOn;
  final double batteryDrainPerShot; // 0..100 scale, percent per shot
  final int storageCapacityShots;
  final String shutterSoundAsset;

  // --- Image processing character ---
  final double saturation; // 1 = neutral
  final double contrast; // 1 = neutral
  final double brightness; // 0 = neutral, +/-
  final double warmth; // -1 (cool/blue) .. 1 (warm/amber)
  final double sensorNoise; // 0..1
  final double sharpenAmount; // 0..1
  final double vignetteStrength; // 0..1
  final double bloomAmount; // 0..1
  final double highlightClip; // 0..1, how aggressively highlights blow out
  final double shadowCrush; // 0..1, how aggressively shadows crush to black
  final double lensDistortion; // -1 (pincushion) .. 1 (barrel), 0 = none
  final double softness; // 0..1 extra gaussian softness (cheap plastic lens)
  final double fingerOverLensChance; // 0..1, easter-egg gag

  // --- Signature processing effects — each one is a genuine optical/
  // hardware quirk (not a skin re-grade), so ProcessJob.fromProfileAndSkin
  // leaves all of these untouched by a CameraSkin's deltas, same as
  // lensDistortion/flashStrength above.
  final double chromaticAberration; // 0..1, RGB channel split radiating from center
  final double lightLeakChance; // 0..1, per-shot chance of a warm light leak
  final double scanlineStrength; // 0..1, alternating-row darkening (CRT/interlace)
  final double crossProcessAmount; // 0..1, teal-shadow/orange-highlight split tone
  final double doubleCompressionAmount; // 0..1, re-encode severity (block/ringing artifacts)
  final bool instantFrameBorder; // true only for instant-print bodies — pads the final canvas

  /// Which hand-drawn body shape [CameraIcon] renders for this camera.
  final CameraSilhouette silhouette;

  const CameraProfile({
    required this.id,
    required this.name,
    required this.year,
    required this.megapixels,
    required this.sensorType,
    required this.lensInfo,
    required this.flashInfo,
    required this.description,
    required this.rarity,
    this.isEasterEgg = false,
    this.isStarter = false,
    this.aspectRatio = CameraAspectRatio.r4x3,
    this.maxDigitalZoom = 2,
    this.digitalZoomQuality = 0.6,
    this.shutterLagMs = 250,
    this.startupAnimationMs = 900,
    this.flashCapability = FlashCapability.autoOffOn,
    this.flashStrength = 0.5,
    this.redEyeChance = 0,
    this.defaultDateStampOn = false,
    this.batteryDrainPerShot = 4,
    this.storageCapacityShots = 36,
    this.shutterSoundAsset = 'sounds/shutter_click.wav',
    this.saturation = 1.0,
    this.contrast = 1.0,
    this.brightness = 0.0,
    this.warmth = 0.0,
    this.sensorNoise = 0.1,
    this.sharpenAmount = 0.2,
    this.vignetteStrength = 0.15,
    this.bloomAmount = 0.1,
    this.highlightClip = 0.2,
    this.shadowCrush = 0.1,
    this.lensDistortion = 0.0,
    this.softness = 0.0,
    this.fingerOverLensChance = 0.0,
    this.chromaticAberration = 0.0,
    this.lightLeakChance = 0.0,
    this.scanlineStrength = 0.0,
    this.crossProcessAmount = 0.0,
    this.doubleCompressionAmount = 0.0,
    this.instantFrameBorder = false,
    this.silhouette = CameraSilhouette.classicCompact,
  });
}
