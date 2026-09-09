import 'package:flutter/material.dart';

import '../theme/app_skin_extension.dart';

/// A discrete-tick loading/progress bar — rectangular segments filling left
/// to right — used everywhere this identity needs a bar: the boot sequence,
/// the home-shelf collection progress, and the capture screen's
/// startup/processing overlays. Replaces every rounded Material
/// [LinearProgressIndicator] in the redesign.
class SegmentedBar extends StatelessWidget {
  final double value; // 0..1
  final int segments;
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;

  const SegmentedBar({
    super.key,
    required this.value,
    this.segments = 16,
    this.activeColor,
    this.inactiveColor,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final active = activeColor ?? skin.amber;
    final inactive = inactiveColor ?? skin.graphite;
    final filled = (value.clamp(0, 1) * segments).round();
    return SizedBox(
      height: height,
      child: Row(
        children: List.generate(segments, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == segments - 1 ? 0 : 2),
              decoration: BoxDecoration(
                color: i < filled ? active : inactive,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }),
      ),
    );
  }
}
