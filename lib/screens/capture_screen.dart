import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart' as cam;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_repository.dart';
import '../data/camera_catalog.dart';
import '../data/skin_catalog.dart';
import '../models/camera_customization.dart' as archive;
import '../models/camera_profile.dart';
import '../models/camera_readout.dart';
import '../models/camera_skin.dart';
import '../services/image_processor.dart';
import '../services/live_preview_filter.dart';
import '../services/location_service.dart';
import '../services/sound_service.dart';
import '../state/archive_store.dart';
import '../state/capture_session_controller.dart';
import '../theme/app_skin_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/device_icons.dart';
import '../widgets/segmented_bar.dart';
import '../widgets/viewfinder_chrome.dart';

class CaptureScreen extends StatefulWidget {
  final String cameraId;

  const CaptureScreen({super.key, required this.cameraId});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> with SingleTickerProviderStateMixin {
  late final CameraProfile _profile = CameraCatalog.byId(widget.cameraId);
  late CaptureSessionController _session;
  final AppRepository _repo = AppRepository();
  final SoundService _sound = SoundService();
  final LocationService _location = LocationService();

  late final AnimationController _focusAnim = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: math.max(150, _profile.shutterLagMs)),
  );

  String? _rollId;
  bool _processing = false;
  bool _flashFlash = false;
  bool _showBrackets = false;
  bool _focusLocked = false;

  @override
  void initState() {
    super.initState();
    final store = context.read<ArchiveStore>();
    final owned = store.ownedById(widget.cameraId)!;
    _session = CaptureSessionController(profile: _profile, customization: owned.customization);
    _session.initialize();
    _ensureRoll(store);
  }

  /// This screen shows the camera being *shot with*, which may not be the
  /// app's globally-equipped camera — its HUD/chrome must reflect its own
  /// skin, never whatever's equipped elsewhere. See the local Theme
  /// override in build().
  CameraSkin _ownedSkin(BuildContext context) =>
      context.read<ArchiveStore>().ownedById(widget.cameraId)!.customization.skinId.skin;

  void _ensureRoll(ArchiveStore store) {
    final active = store.activeRoll;
    if (active != null && active.primaryCameraId == _profile.id) {
      _rollId = active.id;
      return;
    }
    _startNewRoll(store, name: _defaultRollName());
  }

  String _defaultRollName() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return '${_profile.name} · ${months[now.month - 1]} ${now.day}';
  }

  void _startNewRoll(ArchiveStore store, {required String name}) {
    final roll = store.createRoll(name: name, primaryCameraId: _profile.id);
    _rollId = roll.id;
    _session.resetConsumables();
    setState(() {});
    _location.currentLocation().then((loc) {
      if (loc == null || !mounted) return;
      store.attachRollLocation(
        roll.id,
        label: loc.label,
        lat: loc.latitude,
        lng: loc.longitude,
      );
    });
  }

  Future<void> _promptNewRoll() async {
    final controller = TextEditingController(text: _defaultRollName());
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('START A NEW ROLL'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Roll name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('START'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    _startNewRoll(context.read<ArchiveStore>(), name: name);
  }

  @override
  void dispose() {
    _focusAnim.dispose();
    _session.dispose();
    _sound.dispose();
    super.dispose();
  }

  ShotFlashMode _resolveShotFlashMode() {
    if (_profile.flashCapability == FlashCapability.alwaysOn) return ShotFlashMode.forced;
    if (_profile.flashCapability == FlashCapability.none) return ShotFlashMode.off;
    return switch (_session.flashMode) {
      archive.FlashMode.auto => ShotFlashMode.auto,
      archive.FlashMode.forced => ShotFlashMode.forced,
      archive.FlashMode.off => ShotFlashMode.off,
    };
  }

  Future<void> _shoot() async {
    final store = context.read<ArchiveStore>();
    final skin = _ownedSkin(context);
    if (_processing || !_session.canShoot || _rollId == null) {
      if (_session.shotsRemaining <= 0) {
        _snack('This roll is full. Start a new roll to keep shooting.');
      } else if (_session.batteryPercent <= 0) {
        _snack('Battery dead. Start a new roll for a fresh battery.');
      }
      unawaited(_sound.playError());
      return;
    }

    // Mechanical focus-lock cue, honestly tied to this camera's real
    // shutterLagMs — not a claim of real subject/face detection.
    setState(() {
      _showBrackets = true;
      _focusLocked = false;
    });
    _focusAnim.forward(from: 0);

    final rawFile = await _session.capture();
    if (rawFile == null) {
      setState(() => _showBrackets = false);
      _snack('Could not take the photo.');
      return;
    }
    setState(() {
      _processing = true;
      _focusLocked = true;
    });
    unawaited(_sound.playFocusBeep());
    unawaited(_sound.playShutter(skin.shutterSoundOverride ?? _profile.shutterSoundAsset));
    setState(() => _flashFlash = true);
    Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _flashFlash = false);
    });
    Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _showBrackets = false);
    });

    try {
      final bytes = await rawFile.readAsBytes();
      final owned = store.ownedById(widget.cameraId)!;
      final chosenFormat = owned.customization.dateStampFormat;
      final effectiveDateText = chosenFormat != archive.DateStampFormat.off
          ? chosenFormat.format(DateTime.now())
          : (_profile.defaultDateStampOn
                ? archive.DateStampFormat.mdy.format(DateTime.now())
                : '');

      final processed = await processCapture(
        ProcessJob.fromProfileAndSkin(
          jpegBytes: bytes,
          profile: _profile,
          skin: skin,
          flashMode: _resolveShotFlashMode(),
          dateStampText: effectiveDateText,
          extraBlur: _session.zoomQualityBlur,
        ),
      );

      final id = store.newPhotoId();
      final photosDir = await _repo.photosDir;
      final thumbsDir = await _repo.thumbsDir;
      final fullFile = File('${photosDir.path}/$id.jpg');
      final thumbFile = File('${thumbsDir.path}/$id.jpg');
      await fullFile.writeAsBytes(processed.fullJpeg);
      await thumbFile.writeAsBytes(processed.thumbJpeg);

      store.addPhotoToRoll(
        rollId: _rollId!,
        cameraId: _profile.id,
        filePath: fullFile.path,
        thumbPath: thumbFile.path,
        width: processed.width,
        height: processed.height,
      );

      unawaited(
        rawFile.delete().catchError((e) {
          // Cleanup failing shouldn't interrupt the shot flow — the photo is
          // already saved — but a swallowed error here was previously
          // undiagnosable if temp files ever piled up.
          debugPrint('Failed to delete temp capture file ${rawFile.path}: $e');
          return rawFile;
        }),
      );
    } catch (e) {
      unawaited(_sound.playError());
      _snack('Something went wrong processing that shot.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // This screen always themes itself from the SHOOTING camera's own skin
    // — never the app's globally-equipped skin — via a local Theme
    // override. Everything inside reads context.skin as usual and gets the
    // right value because it's inside this subtree.
    final ownedSkin = context.watch<ArchiveStore>().ownedById(widget.cameraId)!.customization.skinId.skin;
    return Theme(
      data: AppTheme.themeFor(ownedSkin),
      child: Builder(
        builder: (context) {
          final skin = context.skin;
          return ChangeNotifierProvider.value(
            value: _session,
            child: Scaffold(
              backgroundColor: skin.black,
              body: Consumer<CaptureSessionController>(
                builder: (context, session, _) {
                  return CameraBodyBezel(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _Viewfinder(profile: _profile, session: session),
                        const GripTexture(),
                        if (_showBrackets)
                          AnimatedBuilder(
                            animation: _focusAnim,
                            builder: (context, _) =>
                                _FocusBrackets(progress: _focusAnim.value, locked: _focusLocked),
                          ),
                        if (_flashFlash) Container(color: Colors.white.withValues(alpha: 0.85)),
                        SafeArea(
                          child: Column(
                            children: [
                              _TopBar(
                                profile: _profile,
                                session: session,
                                rollName: _rollId == null
                                    ? null
                                    : context.watch<ArchiveStore>().rollById(_rollId!)?.name,
                                onRollTap: _promptNewRoll,
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(left: 20, bottom: 10),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: BrandBadge(modelName: _profile.name),
                                ),
                              ),
                              _BottomBar(
                                profile: _profile,
                                session: session,
                                processing: _processing,
                                onShoot: _shoot,
                              ),
                            ],
                          ),
                        ),
                        if (session.stage == CaptureStage.starting) _StartupOverlay(profile: _profile),
                        if (session.stage == CaptureStage.error)
                          _ErrorOverlay(message: session.errorMessage ?? 'Camera error'),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  final CameraProfile profile;
  final CaptureSessionController session;

  const _Viewfinder({required this.profile, required this.session});

  @override
  Widget build(BuildContext context) {
    final controller = session.controller;
    if (controller == null || !controller.value.isInitialized) {
      return ColoredBox(color: context.skin.black);
    }
    final preview = LivePreviewFilter(
      profile: profile,
      child: AspectRatio(
        aspectRatio: 1 / controller.value.aspectRatio,
        child: cam.CameraPreview(controller),
      ),
    );
    if (!profile.instantFrameBorder) {
      return Center(child: preview);
    }
    // Instant-print cameras bake a white border into the final photo — hint
    // at it live so the viewfinder isn't a surprise once the print comes
    // out. Kept outside LivePreviewFilter so the neutral border itself
    // never gets color-graded along with the actual preview.
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 54),
        color: const Color(0xFFFAF8F0),
        child: preview,
      ),
    );
  }
}

/// Four corner-bracket marks that ease inward over the camera's real
/// per-profile shutter lag, then flash lcdGreen right at capture — a
/// mechanical "focus then fire" cue. There is no real subject/face
/// detection in this app, so the label reads AF (a spot/lock indicator),
/// never FACE.
class _FocusBrackets extends StatelessWidget {
  final double progress; // 0..1
  final bool locked;

  const _FocusBrackets({required this.progress, required this.locked});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final color = locked ? skin.lcdGreen : skin.amber;
    return IgnorePointer(
      child: CustomPaint(
        painter: _BracketPainter(progress: progress, color: color),
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.only(top: 40 + 60 * (1 - progress)),
            child: Text(
              locked ? 'AF ●' : 'AF',
              style: skin.readout(fontSize: 12, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BracketPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.86,
      height: size.width * 0.86,
    );
    final inner = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.42,
      height: size.width * 0.42,
    );
    final rect = Rect.lerp(outer, inner, progress)!;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    const arm = 18.0;
    for (final corner in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
      final dx = corner.dx == rect.left ? 1.0 : -1.0;
      final dy = corner.dy == rect.top ? 1.0 : -1.0;
      canvas.drawLine(corner, corner.translate(dx * arm, 0), paint);
      canvas.drawLine(corner, corner.translate(0, dy * arm), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BracketPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _StartupOverlay extends StatelessWidget {
  final CameraProfile profile;

  const _StartupOverlay({required this.profile});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      color: skin.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DeviceIcon(DeviceGlyph.cameraBody, color: skin.mutedText, size: 42),
          const SizedBox(height: 14),
          Text(profile.name, style: skin.lcd(fontSize: 16, color: skin.lcdWhite)),
          const SizedBox(height: 10),
          const SizedBox(width: 140, child: SegmentedBar(value: 1, segments: 10)),
          const SizedBox(height: 8),
          Text('STARTING…', style: skin.uppercaseLabel(fontSize: 11, color: skin.dimAmber)),
        ],
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final String message;

  const _ErrorOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      color: skin.scrim,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DeviceIcon(DeviceGlyph.warning, color: skin.warningRed, size: 40),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: skin.prose(color: skin.lcdWhite)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('GO BACK'),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final CameraProfile profile;
  final CaptureSessionController session;
  final String? rollName;
  final VoidCallback onRollTap;

  const _TopBar({
    required this.profile,
    required this.session,
    required this.rollName,
    required this.onRollTap,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: DeviceIcon(DeviceGlyph.chevronBack, color: skin.lcdWhite),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.tight),
              onTap: onRollTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: skin.hudScrim,
                  borderRadius: BorderRadius.circular(AppRadii.tight),
                  border: Border.all(color: skin.graphite),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RecDot(active: rollName != null),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        rollName?.toUpperCase() ?? 'UNTITLED ROLL',
                        overflow: TextOverflow.ellipsis,
                        style: skin.readout(fontSize: 12, color: skin.lcdWhite),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (profile.flashCapability == FlashCapability.autoOffOn)
            IconButton(
              icon: DeviceIcon(
                _flashGlyph(session.flashMode),
                color: session.flashMode == archive.FlashMode.forced ? skin.amber : skin.lcdWhite,
              ),
              onPressed: () {
                final next = switch (session.flashMode) {
                  archive.FlashMode.auto => archive.FlashMode.forced,
                  archive.FlashMode.forced => archive.FlashMode.off,
                  archive.FlashMode.off => archive.FlashMode.auto,
                };
                session.setFlashMode(next);
              },
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  DeviceGlyph _flashGlyph(archive.FlashMode mode) => switch (mode) {
    archive.FlashMode.auto => DeviceGlyph.flashAuto,
    archive.FlashMode.forced => DeviceGlyph.flashOn,
    archive.FlashMode.off => DeviceGlyph.flashOff,
  };
}

/// The "● REC" indicator — pulses amber/dimAmber while a roll is active,
/// a genuine state cue rather than decoration.
class _RecDot extends StatefulWidget {
  final bool active;

  const _RecDot({required this.active});

  @override
  State<_RecDot> createState() => _RecDotState();
}

class _RecDotState extends State<_RecDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return const SizedBox(width: 6, height: 6);
    }
    final skin = context.skin;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Color.lerp(skin.dimAmber, skin.amber, _controller.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  final CameraProfile profile;
  final CaptureSessionController session;
  final bool processing;
  final VoidCallback onShoot;

  const _BottomBar({
    required this.profile,
    required this.session,
    required this.processing,
    required this.onShoot,
  });

  String _fmtElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          // Firmware HUD readout strip — every value here is either real
          // session/profile state or a deterministic per-camera derivation
          // (see CameraReadout); never randomized per frame. Housed in an
          // extra recessed bevel so it reads as a physical LCD window set
          // into the body, not a floating pill.
          LcdHousing(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: skin.hudScrim,
                borderRadius: BorderRadius.circular(AppRadii.tight),
                border: Border.all(color: skin.graphite),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  _hud(context, '${profile.megapixels.toStringAsFixed(profile.megapixels % 1 == 0 ? 0 : 1)}MP'),
                  _hud(context, profile.isoDisplay),
                  _hud(context, profile.shutterDisplay),
                  _hud(context, profile.apertureDisplay),
                  _hud(context, profile.evDisplay),
                  _hud(context, profile.wbDisplay),
                  _hud(context, _fmtElapsed(session.elapsed)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BatteryPill(percent: session.batteryPercent),
              ShotCounterPill(
                remaining: session.shotsRemaining,
                capacity: profile.storageCapacityShots,
              ),
            ],
          ),
          if (profile.maxDigitalZoom > 1.05) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                DeviceIcon(DeviceGlyph.zoomOut, color: skin.mutedText, size: 16),
                Expanded(
                  child: Slider(
                    value: session.zoom,
                    min: 1,
                    max: profile.maxDigitalZoom,
                    onChanged: session.stage == CaptureStage.ready
                        ? (v) => session.setZoom(v)
                        : null,
                  ),
                ),
                DeviceIcon(DeviceGlyph.zoomIn, color: skin.mutedText, size: 16),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ModeDialGlyph(),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: processing ? null : onShoot,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: session.canShoot && !processing ? skin.amber : skin.graphite,
                      width: 4,
                    ),
                    color: skin.black,
                  ),
                  child: Center(
                    child: processing
                        ? SizedBox(
                            width: 30,
                            height: 30,
                            child: CustomPaint(painter: _ProcessingTickPainter(color: skin.dimAmber)),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: session.canShoot ? skin.amber : skin.graphite,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              const SizedBox(width: 22), // balances ModeDialGlyph so the shutter stays centered
            ],
          ),
        ],
      ),
    );
  }

  Widget _hud(BuildContext context, String text) =>
      Text(text, style: context.skin.readout(fontSize: 11, color: context.skin.amber));
}

/// A segmented radial "processing" tick — matches the boot/loading bar's
/// discrete-segment language instead of a smooth Material spinner.
class _ProcessingTickPainter extends CustomPainter {
  final Color color;

  _ProcessingTickPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const ticks = 8;
    for (var i = 0; i < ticks; i++) {
      final angle = (i / ticks) * math.pi * 2;
      final inner = center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.6);
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProcessingTickPainter oldDelegate) => oldDelegate.color != color;
}
