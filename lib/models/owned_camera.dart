import 'camera_customization.dart';

/// A camera the user actually owns: which catalog profile it is, plus their
/// personalization of it.
class OwnedCamera {
  final String cameraId; // CameraProfile.id
  final DateTime acquiredAt;
  final CameraCustomization customization;

  const OwnedCamera({
    required this.cameraId,
    required this.acquiredAt,
    this.customization = const CameraCustomization(),
  });

  OwnedCamera copyWith({CameraCustomization? customization}) => OwnedCamera(
    cameraId: cameraId,
    acquiredAt: acquiredAt,
    customization: customization ?? this.customization,
  );

  Map<String, dynamic> toJson() => {
    'cameraId': cameraId,
    'acquiredAt': acquiredAt.toIso8601String(),
    'customization': customization.toJson(),
  };

  factory OwnedCamera.fromJson(Map<String, dynamic> json) => OwnedCamera(
    cameraId: json['cameraId'] as String,
    acquiredAt: DateTime.tryParse(json['acquiredAt'] as String? ?? '') ?? DateTime.now(),
    customization: json['customization'] == null
        ? const CameraCustomization()
        : CameraCustomization.fromJson(json['customization'] as Map<String, dynamic>),
  );
}
