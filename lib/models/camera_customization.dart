import '../data/skin_catalog.dart';

enum BodyColor { silver, black, pink, blue, white }

extension BodyColorX on BodyColor {
  String get label => switch (this) {
    BodyColor.silver => 'Silver',
    BodyColor.black => 'Black',
    BodyColor.pink => 'Pink',
    BodyColor.blue => 'Blue',
    BodyColor.white => 'White',
  };

  static BodyColor fromName(String name) =>
      BodyColor.values.firstWhere((b) => b.name == name, orElse: () => BodyColor.silver);
}

enum CameraStrap { none, wrist, lanyard }

extension CameraStrapX on CameraStrap {
  String get label => switch (this) {
    CameraStrap.none => 'None',
    CameraStrap.wrist => 'Wrist strap',
    CameraStrap.lanyard => 'Lanyard',
  };

  static CameraStrap fromName(String name) =>
      CameraStrap.values.firstWhere((s) => s.name == name, orElse: () => CameraStrap.none);
}

enum DateStampFormat { mdy, dmyText, ymdDots, off }

extension DateStampFormatX on DateStampFormat {
  String get sample => switch (this) {
    DateStampFormat.mdy => '09/01/06',
    DateStampFormat.dmyText => '01 SEP 2006',
    DateStampFormat.ymdDots => '2006.09.01',
    DateStampFormat.off => 'Off',
  };

  String format(DateTime d) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return switch (this) {
      DateStampFormat.mdy => '${two(d.month)}/${two(d.day)}/${two(d.year % 100)}',
      DateStampFormat.dmyText => '${two(d.day)} ${months[d.month - 1]} ${d.year}',
      DateStampFormat.ymdDots => '${d.year}.${two(d.month)}.${two(d.day)}',
      DateStampFormat.off => '',
    };
  }

  static DateStampFormat fromName(String name) => DateStampFormat.values
      .firstWhere((f) => f.name == name, orElse: () => DateStampFormat.mdy);
}

/// Flash *mode* the user has dialed in — separate from a profile's
/// [FlashCapability], which decides which of these are actually available.
enum FlashMode { auto, forced, off }

extension FlashModeX on FlashMode {
  String get label => switch (this) {
    FlashMode.auto => 'Auto',
    FlashMode.forced => 'Forced',
    FlashMode.off => 'Off',
  };

  static FlashMode fromName(String name) =>
      FlashMode.values.firstWhere((f) => f.name == name, orElse: () => FlashMode.auto);
}

/// A user's personalization of one owned camera. Cosmetic (body/strap) plus
/// the functional dials (date stamp format, flash mode, camera skin) called
/// out in instructions.md section 7 and the Camera Skins feature.
class CameraCustomization {
  final BodyColor bodyColor;
  final CameraStrap strap;
  final DateStampFormat dateStampFormat;
  final FlashMode flashMode;
  final CameraSkinId skinId;

  const CameraCustomization({
    this.bodyColor = BodyColor.silver,
    this.strap = CameraStrap.none,
    this.dateStampFormat = DateStampFormat.off,
    this.flashMode = FlashMode.auto,
    this.skinId = CameraSkinId.nightVision,
  });

  CameraCustomization copyWith({
    BodyColor? bodyColor,
    CameraStrap? strap,
    DateStampFormat? dateStampFormat,
    FlashMode? flashMode,
    CameraSkinId? skinId,
  }) {
    return CameraCustomization(
      bodyColor: bodyColor ?? this.bodyColor,
      strap: strap ?? this.strap,
      dateStampFormat: dateStampFormat ?? this.dateStampFormat,
      flashMode: flashMode ?? this.flashMode,
      skinId: skinId ?? this.skinId,
    );
  }

  Map<String, dynamic> toJson() => {
    'bodyColor': bodyColor.name,
    'strap': strap.name,
    'dateStampFormat': dateStampFormat.name,
    'flashMode': flashMode.name,
    'skinId': skinId.name,
  };

  factory CameraCustomization.fromJson(Map<String, dynamic> json) => CameraCustomization(
    bodyColor: BodyColorX.fromName(json['bodyColor'] as String? ?? 'silver'),
    strap: CameraStrapX.fromName(json['strap'] as String? ?? 'none'),
    dateStampFormat: DateStampFormatX.fromName(json['dateStampFormat'] as String? ?? 'off'),
    flashMode: FlashModeX.fromName(json['flashMode'] as String? ?? 'auto'),
    // Missing on every pre-existing save (this field is new) — defaults to
    // Night Vision, which is what every camera looked like before this
    // feature shipped, so old saves render unchanged.
    skinId: CameraSkinIdX.fromName(json['skinId'] as String? ?? 'nightVision'),
  );
}
