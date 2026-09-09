/// A named collection of photos, like a physical roll of film or an old
/// digicam's memory card — see instructions.md section 5.
class PhotoRoll {
  final String id;
  final String name;
  final String primaryCameraId; // camera the roll was started with
  final DateTime createdAt;
  final String notes;
  final String? locationLabel; // reverse-geocoded, e.g. "Dubai, UAE"
  final double? latitude;
  final double? longitude;
  final List<String> photoIds;

  const PhotoRoll({
    required this.id,
    required this.name,
    required this.primaryCameraId,
    required this.createdAt,
    this.notes = '',
    this.locationLabel,
    this.latitude,
    this.longitude,
    this.photoIds = const [],
  });

  PhotoRoll copyWith({
    String? name,
    String? notes,
    String? locationLabel,
    double? latitude,
    double? longitude,
    List<String>? photoIds,
  }) {
    return PhotoRoll(
      id: id,
      name: name ?? this.name,
      primaryCameraId: primaryCameraId,
      createdAt: createdAt,
      notes: notes ?? this.notes,
      locationLabel: locationLabel ?? this.locationLabel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoIds: photoIds ?? this.photoIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'primaryCameraId': primaryCameraId,
    'createdAt': createdAt.toIso8601String(),
    'notes': notes,
    'locationLabel': locationLabel,
    'latitude': latitude,
    'longitude': longitude,
    'photoIds': photoIds,
  };

  factory PhotoRoll.fromJson(Map<String, dynamic> json) => PhotoRoll(
    id: json['id'] as String,
    name: json['name'] as String,
    primaryCameraId: json['primaryCameraId'] as String,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    notes: json['notes'] as String? ?? '',
    locationLabel: json['locationLabel'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    photoIds: (json['photoIds'] as List?)?.cast<String>() ?? const [],
  );
}
