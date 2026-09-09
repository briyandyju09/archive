import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';
import 'device_icons.dart';

/// Small dark chrome readout cells for the capture-screen HUD (battery,
/// shot counter, flash state), styled like an old digicam's status LCD — a
/// rectangular bezel on a translucent black ground, never a pill.
class ChromePill extends StatelessWidget {
  final DeviceGlyph? glyph;
  final Widget? leading;
  final String label;
  final Color? accentColor;

  const ChromePill({super.key, this.glyph, this.leading, required this.label, this.accentColor})
    : assert(glyph != null || leading != null, 'ChromePill needs a glyph or a leading widget');

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final color = accentColor ?? skin.lcdWhite;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: skin.hudScrim,
        borderRadius: BorderRadius.circular(AppRadii.tight),
        border: Border.all(color: skin.graphite),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading ?? DeviceIcon(glyph!, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: skin.readout(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class BatteryPill extends StatelessWidget {
  final double percent;

  const BatteryPill({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final color = percent <= 15 ? skin.warningRed : (percent <= 40 ? skin.amber : skin.lcdWhite);
    return ChromePill(
      leading: BatteryGlyph(percent: percent, size: 13, color: color),
      label: '${percent.round()}%',
      accentColor: color,
    );
  }
}

class ShotCounterPill extends StatelessWidget {
  final int remaining;
  final int capacity;

  const ShotCounterPill({super.key, required this.remaining, required this.capacity});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final low = remaining <= (capacity * 0.1).clamp(1, 6);
    return ChromePill(
      glyph: DeviceGlyph.filmRoll,
      label: '$remaining LEFT',
      accentColor: low ? skin.warningRed : skin.lcdWhite,
    );
  }
}
