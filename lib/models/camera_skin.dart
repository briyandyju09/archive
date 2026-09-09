import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// The "material" lever for [CameraSkin.panelDecoration] — how a skin's
/// panels/controls read as machined into the body, without adding any new
/// call sites (every caller still just says `skin.panelDecoration(...)`).
enum PanelBevelStyle {
  /// The original FIELD UNIT 04 treatment: hairline border + a 1px top
  /// highlight / bottom shadow line. Reads as a soft-edged injection-molded
  /// body.
  softBezel,

  /// Thicker hairline, no bevel lines — flatter, sharper-edged metal.
  hardEdge,

  /// Thin hairline only, no bevel lines at all — the cleanest, most
  /// minimal read (brushed aluminum).
  hairline,
}

/// One complete alternate "camera body": every structural color, the
/// typographic tuning, the panel material, a shutter/boot-chime sound
/// identity, and an image-processing tilt. This is the full replacement for
/// what used to be the single, fixed `AppColors`/`AppTheme` constant set —
/// every app-wide static color/style reference now resolves through
/// whichever `CameraSkin` is current (see `app_skin_extension.dart`).
class CameraSkin {
  final String id;
  final String name;
  final String personality;

  // --- Structural color roles — same 9 names/meanings AppColors used to
  // have as global consts. For one skin (Archive) these roles are
  // deliberately inverted (a light body), which is why the derived getters
  // below resolve highlight/shadow/scrim by relative luminance rather than
  // assuming `black` is always the darker tone.
  final Color black; // void / app background
  final Color charcoal; // primary panel fill
  final Color graphite; // raised control face / hairline border
  final Color lcdWhite; // primary text/icon color
  final Color warmWhite; // secondary emphasis / hero numerals
  final Color amber; // primary accent — active/selected/recording
  final Color dimAmber; // inactive accent / label half of HUD rows
  final Color lcdGreen; // "OK / nominal / locked" signal
  final Color warningRed; // error / critical only

  // --- Typography ---
  final String displayFamily; // default 'VT323'
  final String labelFamily; // default 'SpaceMono'
  final String proseFamily; // default 'IBMPlexMono'
  final FontWeight labelWeight;
  final double labelLetterSpacing;
  final double displayLetterSpacing;

  // --- Material ---
  final PanelBevelStyle panelBevel;

  // --- Sound identity ---
  final String bootChimeAsset;
  final String? shutterSoundOverride; // null = defer to CameraProfile.shutterSoundAsset

  // --- Image-processing tilt: deltas blended with (never replacing) a
  // camera's own knobs. Unspecified = 0 = no nudge.
  final double saturationDelta;
  final double contrastDelta;
  final double brightnessDelta;
  final double warmthDelta;
  final double sensorNoiseDelta;
  final double sharpenDelta;
  final double vignetteDelta;
  final double bloomDelta;
  final double highlightClipDelta;
  final double shadowCrushDelta;
  final double softnessDelta;

  /// Also drives the on-screen date-stamp preview and the burned-in JPEG
  /// date stamp — one color, two consumers.
  final Color dateStampColor;

  const CameraSkin({
    required this.id,
    required this.name,
    required this.personality,
    required this.black,
    required this.charcoal,
    required this.graphite,
    required this.lcdWhite,
    required this.warmWhite,
    required this.amber,
    required this.dimAmber,
    required this.lcdGreen,
    required this.warningRed,
    this.displayFamily = 'VT323',
    this.labelFamily = 'SpaceMono',
    this.proseFamily = 'IBMPlexMono',
    this.labelWeight = FontWeight.w700,
    this.labelLetterSpacing = 0.08,
    this.displayLetterSpacing = 0.5,
    this.panelBevel = PanelBevelStyle.softBezel,
    required this.bootChimeAsset,
    this.shutterSoundOverride,
    this.saturationDelta = 0,
    this.contrastDelta = 0,
    this.brightnessDelta = 0,
    this.warmthDelta = 0,
    this.sensorNoiseDelta = 0,
    this.sharpenDelta = 0,
    this.vignetteDelta = 0,
    this.bloomDelta = 0,
    this.highlightClipDelta = 0,
    this.shadowCrushDelta = 0,
    this.softnessDelta = 0,
    required this.dateStampColor,
  });

  // Resolve highlight/shadow/scrim by relative luminance rather than
  // assuming `black` is the darker tone — the one thing that keeps Archive's
  // inverted (light-body) polarity from producing backwards bevel lines.
  Color get _lighterNeutral => black.computeLuminance() >= lcdWhite.computeLuminance() ? black : lcdWhite;
  Color get _darkerNeutral => black.computeLuminance() >= lcdWhite.computeLuminance() ? lcdWhite : black;

  Color get mutedText => lcdWhite.withValues(alpha: 0.55);
  Color get scrim => _darkerNeutral.withValues(alpha: 0.78);
  Color get hudScrim => _darkerNeutral.withValues(alpha: 0.55);
  Color get bezelHighlight => _lighterNeutral.withValues(alpha: 0.08);
  Color get bezelShadow => _darkerNeutral.withValues(alpha: 0.40);
  Color get engraveShadow => _darkerNeutral.withValues(alpha: 0.30);

  /// Hero/display numerals — boot title, collection-count numeral.
  TextStyle display({double fontSize = 40, Color? color, double? letterSpacing}) {
    return TextStyle(
      fontFamily: displayFamily,
      fontSize: fontSize,
      color: color ?? warmWhite,
      letterSpacing: letterSpacing ?? displayLetterSpacing,
      height: 1.0,
    );
  }

  /// Uppercase technical labels & controls. Callers pass already-cased text
  /// (this never forces a text-transform) so literal-string test
  /// assertions keep rendering exactly as written.
  TextStyle uppercaseLabel({double fontSize = 12, Color? color, double? letterSpacing}) {
    return TextStyle(
      fontFamily: labelFamily,
      fontWeight: labelWeight,
      fontSize: fontSize,
      color: color ?? lcdWhite,
      letterSpacing: letterSpacing ?? labelLetterSpacing,
    );
  }

  /// HUD/LCD numeric readouts — the value half of label:value pairs, the
  /// date-stamp digits, filenames, timestamps.
  TextStyle lcd({double fontSize = 14, Color? color}) => readout(fontSize: fontSize, color: color);

  TextStyle readout({double fontSize = 14, Color? color, FontWeight weight = FontWeight.w600}) {
    return TextStyle(
      fontFamily: labelFamily,
      fontSize: fontSize,
      color: color ?? lcdWhite,
      fontWeight: weight,
    );
  }

  /// Body/description prose — camera descriptions, roll notes, empty states.
  TextStyle prose({double fontSize = 14, Color? color, double height = 1.5}) {
    return TextStyle(
      fontFamily: proseFamily,
      fontSize: fontSize,
      color: color ?? lcdWhite,
      height: height,
    );
  }

  /// The "machined into the body" bezel/inset treatment standing in for
  /// Material elevation — never a blurred boxShadow. [panelBevel] is the
  /// per-skin material lever; every caller still just says
  /// `skin.panelDecoration(...)`, so this adds zero call-site churn.
  BoxDecoration panelDecoration({bool raised = false, Color? borderColor}) {
    final fill = raised ? graphite : charcoal;
    final border = Border.all(
      color: borderColor ?? graphite,
      width: panelBevel == PanelBevelStyle.hardEdge ? 1.5 : 1,
    );
    final radius = BorderRadius.circular(AppRadii.panel);
    if (panelBevel == PanelBevelStyle.softBezel) {
      return BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: border,
        boxShadow: [
          BoxShadow(color: bezelHighlight, offset: const Offset(0, -1), blurRadius: 0),
          BoxShadow(color: bezelShadow, offset: const Offset(0, 1), blurRadius: 0),
        ],
      );
    }
    return BoxDecoration(color: fill, borderRadius: radius, border: border);
  }

  /// A one-pixel "engraved" text cue for tiny firmware labels — a
  /// legibility technique on the glyph itself, never a panel shadow.
  List<Shadow> engraved() => [Shadow(color: engraveShadow, offset: const Offset(0, 1))];
}
