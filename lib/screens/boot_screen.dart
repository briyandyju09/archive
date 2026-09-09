import 'dart:async';

import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../theme/app_skin_extension.dart';
import '../widgets/segmented_bar.dart';

/// A camera-hardware boot sequence shown once at launch — not an artificial
/// delay, but a re-skin of the wait that already exists while [ArchiveStore]
/// loads. Fixed ~1.5s duration, well under the "fast, delightful, not a
/// loading screen" ceiling; never gated on real I/O finishing.
class BootScreen extends StatefulWidget {
  final VoidCallback onDone;

  const BootScreen({super.key, required this.onDone});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 1500);
  final SoundService _sound = SoundService();
  bool _chimePlayed = false;

  late final AnimationController _controller = AnimationController(vsync: this, duration: _totalDuration)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _controller.dispose();
    _sound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    // MaterialApp's theme (and this skin) is already resolved from the
    // equipped camera before BootScreen is ever shown — fire the chime
    // once, on the first build, using this specific skin's own chime.
    if (!_chimePlayed) {
      _chimePlayed = true;
      unawaited(_sound.playBootChime(skin.bootChimeAsset));
    }
    return Scaffold(
      backgroundColor: skin.black,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _stageOpacity(t, 0.0, 0.12),
                  child: Column(
                    children: [
                      Text('DIGITAL CAMERA', style: skin.display(fontSize: 32, color: skin.warmWhite)),
                      const SizedBox(height: 4),
                      Text('SYSTEM 04.27', style: skin.uppercaseLabel(fontSize: 11, color: skin.dimAmber)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: _stageOpacity(t, 0.12, 0.2),
                  child: SizedBox(
                    width: 180,
                    child: SegmentedBar(value: _stageProgress(t, 0.12, 0.55)),
                  ),
                ),
                const SizedBox(height: 20),
                _StatusLine(label: 'LENS OK', visible: t >= 0.58),
                _StatusLine(label: 'SENSOR OK', visible: t >= 0.68),
                _StatusLine(label: 'MEMORY OK', visible: t >= 0.78),
                const SizedBox(height: 12),
                Opacity(
                  opacity: _stageOpacity(t, 0.85, 0.92),
                  child: Text('READY', style: skin.uppercaseLabel(fontSize: 13, color: skin.amber)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _stageOpacity(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }

  double _stageProgress(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }
}

class _StatusLine extends StatelessWidget {
  final String label;
  final bool visible;

  const _StatusLine({required this.label, required this.visible});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 120),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(label, style: skin.uppercaseLabel(fontSize: 11, color: skin.lcdGreen)),
      ),
    );
  }
}
