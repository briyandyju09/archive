import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart' as cam;
import 'package:flutter/foundation.dart';

import '../models/camera_customization.dart' as archive;
import '../models/camera_profile.dart';

enum CaptureStage { starting, ready, error }

/// Drives one shooting session with one camera: controller lifecycle, the
/// startup animation delay, shutter-lag-gated capture, and the fake
/// battery/storage counters called out in instructions.md section 1.
class CaptureSessionController extends ChangeNotifier {
  final CameraProfile profile;
  final archive.CameraCustomization customization;

  cam.CameraController? _controller;
  cam.CameraController? get controller => _controller;

  CaptureStage stage = CaptureStage.starting;
  String? errorMessage;

  double batteryPercent = 100;
  late int shotsRemaining = profile.storageCapacityShots;
  bool isCapturing = false;
  double zoom = 1.0;
  double _platformMinZoom = 1.0;
  double _platformMaxZoom = 1.0;

  archive.FlashMode _flashMode;

  DateTime? _sessionStartedAt;
  Timer? _tickTimer;

  CaptureSessionController({required this.profile, required this.customization})
    : _flashMode = customization.flashMode;

  archive.FlashMode get flashMode => _flashMode;

  /// Time since the viewfinder first became ready — the HUD's "00:13:42"
  /// firmware-style session timer. Zero.duration until then.
  Duration get elapsed =>
      _sessionStartedAt == null ? Duration.zero : DateTime.now().difference(_sessionStartedAt!);

  bool get canShoot =>
      stage == CaptureStage.ready && !isCapturing && shotsRemaining > 0 && batteryPercent > 0;

  Future<void> initialize() async {
    try {
      final cameras = await cam.availableCameras();
      if (cameras.isEmpty) {
        stage = CaptureStage.error;
        errorMessage = 'No camera found on this device.';
        notifyListeners();
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == cam.CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = cam.CameraController(
        back,
        cam.ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: cam.ImageFormatGroup.jpeg,
      );
      _controller = controller;
      await controller.initialize();
      _platformMinZoom = await controller.getMinZoomLevel();
      _platformMaxZoom = await controller.getMaxZoomLevel();
      await _applyFlashMode();

      // Simulate the camera's own boot-up time before it's usable.
      await Future.delayed(Duration(milliseconds: profile.startupAnimationMs));

      stage = CaptureStage.ready;
      _sessionStartedAt = DateTime.now();
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
      notifyListeners();
    } catch (e) {
      stage = CaptureStage.error;
      errorMessage = _friendlyError(e);
      notifyListeners();
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('CameraAccessDenied') || s.contains('permission')) {
      return 'Camera access was denied. Enable it in system settings to shoot with this camera.';
    }
    return 'Could not start the camera: $s';
  }

  Future<void> setFlashMode(archive.FlashMode mode) async {
    if (profile.flashCapability == FlashCapability.alwaysOn) return; // locked on
    if (profile.flashCapability == FlashCapability.none) return; // no flash hardware
    _flashMode = mode;
    await _applyFlashMode();
    notifyListeners();
  }

  Future<void> _applyFlashMode() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    cam.FlashMode target;
    if (profile.flashCapability == FlashCapability.alwaysOn) {
      target = cam.FlashMode.always;
    } else if (profile.flashCapability == FlashCapability.none) {
      target = cam.FlashMode.off;
    } else {
      target = switch (_flashMode) {
        archive.FlashMode.auto => cam.FlashMode.auto,
        archive.FlashMode.forced => cam.FlashMode.always,
        archive.FlashMode.off => cam.FlashMode.off,
      };
    }
    try {
      await controller.setFlashMode(target);
    } catch (_) {
      // Some devices/emulators don't support flash mode changes — ignore.
    }
  }

  bool get willFlashFire {
    if (profile.flashCapability == FlashCapability.none) return false;
    if (profile.flashCapability == FlashCapability.alwaysOn) return true;
    return _flashMode != archive.FlashMode.off;
  }

  /// Effective 1..profile.maxDigitalZoom dial exposed to the UI.
  double get maxUiZoom => profile.maxDigitalZoom;

  Future<void> setZoom(double uiZoom) async {
    final controller = _controller;
    if (controller == null) return;
    zoom = uiZoom.clamp(1.0, profile.maxDigitalZoom);
    // Map the profile's 1..maxDigitalZoom dial onto whatever optical/digital
    // zoom range the actual hardware exposes.
    final range = (_platformMaxZoom - _platformMinZoom).clamp(0.0001, double.infinity);
    final t = (zoom - 1) / (profile.maxDigitalZoom - 1).clamp(0.0001, double.infinity);
    final platformZoom = (_platformMinZoom + t * range).clamp(_platformMinZoom, _platformMaxZoom);
    try {
      await controller.setZoomLevel(platformZoom);
    } catch (_) {}
    notifyListeners();
  }

  /// Extra post-capture blur (0..1) representing digital-zoom quality
  /// falloff past the optical range, per the profile's digitalZoomQuality.
  double get zoomQualityBlur {
    if (zoom <= 1.0001) return 0;
    final t = (zoom - 1) / (profile.maxDigitalZoom - 1).clamp(0.0001, double.infinity);
    return (t * (1 - profile.digitalZoomQuality)).clamp(0, 1);
  }

  /// Fires the shutter after the profile's lag, returns the raw JPEG bytes,
  /// or null if the camera couldn't shoot (out of battery/storage/busy).
  Future<File?> capture() async {
    final controller = _controller;
    if (controller == null || !canShoot) return null;
    isCapturing = true;
    notifyListeners();
    try {
      if (profile.shutterLagMs > 0) {
        await Future.delayed(Duration(milliseconds: profile.shutterLagMs));
      }
      final xfile = await controller.takePicture();
      shotsRemaining = (shotsRemaining - 1).clamp(0, profile.storageCapacityShots);
      batteryPercent = (batteryPercent - profile.batteryDrainPerShot).clamp(0, 100);
      return File(xfile.path);
    } catch (_) {
      return null;
    } finally {
      isCapturing = false;
      notifyListeners();
    }
  }

  /// Represents inserting a fresh battery/card for a new roll/session.
  void resetConsumables() {
    batteryPercent = 100;
    shotsRemaining = profile.storageCapacityShots;
    notifyListeners();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}
