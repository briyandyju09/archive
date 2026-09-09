import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/camera_profile.dart';
import '../state/archive_store.dart';
import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';
import '../widgets/camera_icon.dart';
import '../widgets/device_icons.dart';
import '../widgets/rarity_badge.dart';
import 'camera_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  // Mechanical "snap into focus" reveal — no bounce/overshoot. A short scale
  // settle plus a brief fade, replacing the old elasticOut spring.
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOutExpo)), weight: 70),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
  ]).animate(_anim);
  late final Animation<double> _fade = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );

  CameraProfile? _revealed;
  bool _revealing = false;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _reveal() async {
    final store = context.read<ArchiveStore>();
    if (!store.hasUndiscovered || _revealing) return;
    setState(() => _revealing = true);
    await Future.delayed(const Duration(milliseconds: 200));
    final found = store.discover();
    setState(() {
      _revealed = found;
      _revealing = false;
    });
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ArchiveStore>();
    final hasMore = store.hasUndiscovered;

    return Scaffold(
      appBar: AppBar(title: const Text('Discover Cameras')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _revealed == null
              ? _MysteryCard(loading: _revealing, enabled: hasMore, onTap: _reveal)
              : FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: _RevealedCard(
                      profile: _revealed!,
                      onDone: () => Navigator.of(context).pop(),
                      onView: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => CameraDetailScreen(cameraId: _revealed!.id),
                          ),
                        );
                      },
                      onAnother: hasMore
                          ? () => setState(() {
                              _revealed = null;
                            })
                          : null,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MysteryCard extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _MysteryCard({required this.loading, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    if (!enabled) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DeviceIcon(DeviceGlyph.aperture, size: 56, color: skin.amber),
          const SizedBox(height: 16),
          Text(
            "You've found every camera in the Archive.",
            textAlign: TextAlign.center,
            style: skin.prose(fontSize: 14, color: skin.lcdWhite),
          ),
        ],
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.panel),
      onTap: loading ? null : onTap,
      child: Container(
        width: 220,
        height: 280,
        decoration: skin.panelDecoration(raised: true),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2, color: skin.amber),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DeviceIcon(DeviceGlyph.unknownUnit, size: 72, color: skin.dimAmber),
                    const SizedBox(height: 16),
                    Text('TAP TO REVEAL', style: skin.uppercaseLabel(fontSize: 12, color: skin.lcdWhite)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RevealedCard extends StatelessWidget {
  final CameraProfile profile;
  final VoidCallback onDone;
  final VoidCallback onView;
  final VoidCallback? onAnother;

  const _RevealedCard({
    required this.profile,
    required this.onDone,
    required this.onView,
    this.onAnother,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          (profile.isEasterEgg ? 'A SECRET CAMERA' : 'NEW CAMERA'),
          style: skin.uppercaseLabel(fontSize: 13, color: skin.amber),
        ),
        const SizedBox(height: 14),
        const CameraIcon(size: 110),
        const SizedBox(height: 14),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: skin.readout(fontSize: 20, color: skin.warmWhite, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        RarityBadge(rarity: profile.rarity),
        const SizedBox(height: 18),
        FilledButton(onPressed: onView, child: const Text('VIEW CAMERA')),
        const SizedBox(height: 8),
        if (onAnother != null)
          TextButton(onPressed: onAnother, child: const Text('DISCOVER ANOTHER'))
        else
          TextButton(onPressed: onDone, child: const Text('DONE')),
      ],
    );
  }
}
