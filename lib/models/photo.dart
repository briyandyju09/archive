/// A single captured photo.
class Photo {
  final String id;
  final String rollId;
  final String cameraId; // CameraProfile.id it was shot with
  final String filePath;
  final String thumbPath;
  final DateTime takenAt;
  final int width;
  final int height;

  /// Monotonically-increasing per-archive shot counter, assigned at capture
  /// time (see ArchiveStore.nextFrameNumber) so the playback screen can show
  /// a firmware-style "IMG_0421" filename. Null for photos captured before
  /// this field existed — the playback screen falls back to a per-roll index
  /// in that case rather than treating it as an error.
  final int? frameNumber;

  const Photo({
    required this.id,
    required this.rollId,
    required this.cameraId,
    required this.filePath,
    required this.thumbPath,
    required this.takenAt,
    required this.width,
    required this.height,
    this.frameNumber,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'rollId': rollId,
    'cameraId': cameraId,
    'filePath': filePath,
    'thumbPath': thumbPath,
    'takenAt': takenAt.toIso8601String(),
    'width': width,
    'height': height,
    'frameNumber': frameNumber,
  };

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    id: json['id'] as String,
    rollId: json['rollId'] as String,
    cameraId: json['cameraId'] as String,
    filePath: json['filePath'] as String,
    thumbPath: json['thumbPath'] as String,
    takenAt: DateTime.tryParse(json['takenAt'] as String? ?? '') ?? DateTime.now(),
    width: json['width'] as int? ?? 0,
    height: json['height'] as int? ?? 0,
    frameNumber: json['frameNumber'] as int?,
  );
}
