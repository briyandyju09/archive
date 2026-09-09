import 'package:flutter/material.dart';

import '../models/camera_skin.dart';

/// The five selectable camera bodies. Values/order match the original
/// brief exactly (01 Night Vision .. 05 Industrial).
enum CameraSkinId { nightVision, silver2003, oceanic, archive, industrial }

extension CameraSkinIdX on CameraSkinId {
  CameraSkin get skin => SkinCatalog.byId(this);

  static CameraSkinId fromName(String name) =>
      CameraSkinId.values.firstWhere((s) => s.name == name, orElse: () => CameraSkinId.nightVision);
}

/// The five [CameraSkin] definitions. Night Vision is the existing shipped
/// identity, essentially unchanged — every camera defaults to it, so a
/// fresh install and every pre-existing save file look exactly as they did
/// before this feature shipped.
class SkinCatalog {
  SkinCatalog._();

  static final CameraSkin nightVision = CameraSkin(
    id: 'nightVision',
    name: 'Night Vision',
    personality: 'The house standard — matte-black body, amber LCD, grain-heavy high-contrast image character.',
    black: const Color(0xFF060606),
    charcoal: const Color(0xFF141414),
    graphite: const Color(0xFF222222),
    lcdWhite: const Color(0xFFE8E8E2),
    warmWhite: const Color(0xFFFFF4D6),
    amber: const Color(0xFFF2A72E),
    dimAmber: const Color(0xFF8C621F),
    lcdGreen: const Color(0xFFB8C99A),
    warningRed: const Color(0xFFC94B3D),
    panelBevel: PanelBevelStyle.softBezel,
    bootChimeAsset: 'sounds/boot_chime.wav',
    sensorNoiseDelta: 0.15,
    contrastDelta: 0.15,
    vignetteDelta: 0.05,
    dateStampColor: const Color(0xFFF2A72E),
  );

  static final CameraSkin silver2003 = CameraSkin(
    id: 'silver2003',
    name: 'Silver 2003',
    personality: 'A crisp early-2000s point-and-shoot — brushed aluminum, an icy blue-cyan LCD, clean flash-lit images.',
    black: const Color(0xFF0A0B0D),
    charcoal: const Color(0xFF1B1D21),
    graphite: const Color(0xFF2E3136),
    lcdWhite: const Color(0xFFEDEFF2),
    warmWhite: const Color(0xFFF5F7FA),
    amber: const Color(0xFF5FC6E8),
    dimAmber: const Color(0xFF2F5A66),
    lcdGreen: const Color(0xFFA9C9B8),
    warningRed: const Color(0xFFC94B3D),
    labelLetterSpacing: 0.04,
    panelBevel: PanelBevelStyle.hairline,
    bootChimeAsset: 'sounds/boot_chime_silver2003.wav',
    shutterSoundOverride: 'sounds/shutter_silver2003.wav',
    warmthDelta: -0.10,
    highlightClipDelta: -0.10,
    sharpenDelta: 0.05,
    sensorNoiseDelta: -0.05,
    dateStampColor: const Color(0xFF5FC6E8),
  );

  static final CameraSkin oceanic = CameraSkin(
    id: 'oceanic',
    name: 'Oceanic',
    personality: 'A dive-logbook camera — navy-blue body, a cold slate LCD, and a soft, slightly hazy film character.',
    black: const Color(0xFF070B12),
    charcoal: const Color(0xFF101823),
    graphite: const Color(0xFF1C2A3A),
    lcdWhite: const Color(0xFFD8E2E8),
    warmWhite: const Color(0xFFEAF3F5),
    amber: const Color(0xFF5FA8C4),
    dimAmber: const Color(0xFF2E4A56),
    lcdGreen: const Color(0xFF8FBFA8),
    warningRed: const Color(0xFFD1584A),
    panelBevel: PanelBevelStyle.softBezel,
    bootChimeAsset: 'sounds/boot_chime_oceanic.wav',
    shutterSoundOverride: 'sounds/shutter_oceanic.wav',
    warmthDelta: -0.15,
    softnessDelta: 0.10,
    contrastDelta: -0.05,
    bloomDelta: 0.05,
    dateStampColor: const Color(0xFF5FA8C4),
  );

  /// The one light-body skin — deliberate and scene-justified (real
  /// disposables are cream plastic used in casual daylight, unlike the
  /// other four controlled/dim-use bodies). `lcdWhite` (primary text) is
  /// dark ink here; `black` (void/background) is a warm stone, not stark
  /// white, so the bezel depth cue still reads. See CameraSkin's
  /// luminance-based highlight/shadow getters for how this stays correct.
  static final CameraSkin archive = CameraSkin(
    id: 'archive',
    name: 'Archive',
    personality: 'A drugstore disposable — cream plastic body, a faded green counter LCD, washed-out grainy snapshots.',
    black: const Color(0xFFC9C4B8),
    charcoal: const Color(0xFFDDD8C9),
    graphite: const Color(0xFFEDE8DA),
    lcdWhite: const Color(0xFF2A271E),
    warmWhite: const Color(0xFF4A4636),
    amber: const Color(0xFF7A9B6E),
    dimAmber: const Color(0xFFA9B79E),
    lcdGreen: const Color(0xFF7A9B6E),
    warningRed: const Color(0xFFB25C4E),
    labelWeight: FontWeight.w600,
    panelBevel: PanelBevelStyle.softBezel,
    bootChimeAsset: 'sounds/boot_chime_archive.wav',
    shutterSoundOverride: 'sounds/shutter_soft.wav',
    saturationDelta: -0.30,
    sensorNoiseDelta: 0.20,
    vignetteDelta: 0.10,
    highlightClipDelta: 0.15,
    softnessDelta: 0.05,
    warmthDelta: 0.05,
    contrastDelta: 0.05,
    dateStampColor: const Color(0xFF7A9B6E),
  );

  static final CameraSkin industrial = CameraSkin(
    id: 'industrial',
    name: 'Industrial',
    personality: 'Technical instrumentation — sharp edges, red telemetry accents on graphite metal, information-dense.',
    black: const Color(0xFF0C0C0D),
    charcoal: const Color(0xFF18181A),
    graphite: const Color(0xFF2B2B2E),
    lcdWhite: const Color(0xFFE6E6E4),
    warmWhite: const Color(0xFFF0EDE8),
    amber: const Color(0xFFC9503D),
    dimAmber: const Color(0xFF6B372C),
    lcdGreen: const Color(0xFF8FA66B),
    warningRed: const Color(0xFFE8432B),
    labelLetterSpacing: 0.05,
    panelBevel: PanelBevelStyle.hardEdge,
    bootChimeAsset: 'sounds/boot_chime_industrial.wav',
    shutterSoundOverride: 'sounds/shutter_industrial.wav',
    sharpenDelta: 0.15,
    contrastDelta: 0.10,
    saturationDelta: -0.10,
    sensorNoiseDelta: 0.05,
    vignetteDelta: 0.05,
    warmthDelta: -0.05,
    dateStampColor: const Color(0xFFC9503D),
  );

  static final List<CameraSkin> all = [nightVision, silver2003, oceanic, archive, industrial];

  static CameraSkin byId(CameraSkinId id) => switch (id) {
    CameraSkinId.nightVision => nightVision,
    CameraSkinId.silver2003 => silver2003,
    CameraSkinId.oceanic => oceanic,
    CameraSkinId.archive => archive,
    CameraSkinId.industrial => industrial,
  };
}
