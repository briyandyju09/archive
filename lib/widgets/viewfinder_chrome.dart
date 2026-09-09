import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/camera_skin.dart';
import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';
import 'device_icons.dart';
import 'device_panel.dart';

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

/// Wraps the capture screen's full viewfinder stack in a "machined into
/// the body" outer bezel — a hairline border, a 1px top-highlight/
/// bottom-shadow bevel line, and four corner rivet dots — so the whole
/// screen reads as a physical camera body, not a bare full-bleed preview.
/// Reads `context.skin` directly, same as every other chrome widget here,
/// so it automatically adapts to whichever body is active.
class CameraBodyBezel extends StatelessWidget {
  final Widget child;

  const CameraBodyBezel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(child: CustomPaint(painter: _BodyBezelPainter(skin: skin))),
      ],
    );
  }
}

class _BodyBezelPainter extends CustomPainter {
  final CameraSkin skin;

  _BodyBezelPainter({required this.skin});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    canvas.drawRect(
      rect,
      Paint()
        ..color = skin.graphite
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      const Offset(0, 3),
      Offset(size.width, 3),
      Paint()..color = skin.bezelHighlight..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(0, size.height - 3),
      Offset(size.width, size.height - 3),
      Paint()..color = skin.bezelShadow..strokeWidth = 1,
    );
    const inset = 14.0;
    final rivetFill = Paint()..color = skin.graphite;
    final rivetRing = Paint()
      ..color = skin.bezelHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final c in [
      const Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      canvas.drawCircle(c, 3.2, rivetFill);
      canvas.drawCircle(c, 3.2, rivetRing);
    }
  }

  @override
  bool shouldRepaint(covariant _BodyBezelPainter oldDelegate) => oldDelegate.skin != skin;
}

/// A small corner "engraving" showing the camera's real model name — the
/// brand/model badge a physical camera body would carry.
class BrandBadge extends StatelessWidget {
  final String modelName;

  const BrandBadge({super.key, required this.modelName});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
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
          DeviceIcon(DeviceGlyph.cameraBody, size: 13, color: skin.dimAmber),
          const SizedBox(width: 6),
          Text(modelName.toUpperCase(), style: skin.uppercaseLabel(fontSize: 10.5, color: skin.dimAmber)),
        ],
      ),
    );
  }
}

/// Subtle repeating texture confined to the screen's left/right margins —
/// where a real camera's rubber grip sits. Purely decorative and
/// [IgnorePointer]-wrapped so it never intercepts touch.
class GripTexture extends StatelessWidget {
  const GripTexture({super.key});

  @override
  Widget build(BuildContext context) {
    final color = context.skin.graphite;
    return IgnorePointer(
      child: Row(
        children: [
          SizedBox.expand(child: CustomPaint(painter: _GripPainter(color: color))),
          const Spacer(),
          SizedBox.expand(child: CustomPaint(painter: _GripPainter(color: color))),
        ],
      ),
    );
  }
}

class _GripPainter extends CustomPainter {
  final Color color;

  _GripPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    const spacing = 7.0;
    for (var y = -size.width; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + size.width), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GripPainter oldDelegate) => oldDelegate.color != color;
}

/// Wraps a firmware HUD readout in an extra recessed bevel so it reads as
/// a physical LCD window set into the body, rather than a floating pill.
class LcdHousing extends StatelessWidget {
  final Widget child;

  const LcdHousing({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DevicePanel(raised: true, padding: const EdgeInsets.all(3), child: child);
  }
}

/// A small cosmetic tick-mark dial near the shutter button — the "mode
/// dial" engraving a physical camera body would carry.
class ModeDialGlyph extends StatelessWidget {
  final double size;

  const ModeDialGlyph({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return CustomPaint(
      size: Size.square(size),
      painter: _ModeDialPainter(color: skin.graphite, accent: skin.amber),
    );
  }
}

class _ModeDialPainter extends CustomPainter {
  final Color color;
  final Color accent;

  _ModeDialPainter({required this.color, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    const ticks = 8;
    final tickPaint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 0; i < ticks; i++) {
      final angle = (i / ticks) * 2 * math.pi;
      final inner = center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.7);
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(inner, outer, tickPaint);
    }
    const pointerAngle = -math.pi / 2;
    final tip = center + Offset(math.cos(pointerAngle), math.sin(pointerAngle)) * (radius * 0.6);
    canvas.drawLine(center, tip, Paint()..color = accent..strokeWidth = 1.6);
  }

  @override
  bool shouldRepaint(covariant _ModeDialPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
}
