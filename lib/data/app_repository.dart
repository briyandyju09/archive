import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/owned_camera.dart';
import '../models/photo.dart';
import '../models/photo_roll.dart';
import 'camera_catalog.dart';

/// Everything persisted about the user's app state, loaded/saved as a single
/// JSON blob. Small enough at this scale that a database would be overkill —
/// photo pixel data lives on disk separately, this just holds metadata.
class AppState {
  List<OwnedCamera> ownedCameras;
  List<PhotoRoll> rolls;
  List<Photo> photos;
  Set<String> discoveredEasterEggIds;
  String? equippedCameraId;
  String? activeRollId;

  /// Monotonic counter backing Photo.frameNumber's "IMG_0421"-style firmware
  /// filenames. Starts at 0 for both new and pre-existing (older) state
  /// files, so it never collides with frame numbers already assigned.
  int nextFrameCounter;

  AppState({
    required this.ownedCameras,
    required this.rolls,
    required this.photos,
    required this.discoveredEasterEggIds,
    this.equippedCameraId,
    this.activeRollId,
    this.nextFrameCounter = 0,
  });

  factory AppState.initial() => AppState(
    ownedCameras: [
      OwnedCamera(cameraId: CameraCatalog.starterCameraId, acquiredAt: DateTime.now()),
    ],
    rolls: [],
    photos: [],
    discoveredEasterEggIds: {},
    equippedCameraId: CameraCatalog.starterCameraId,
  );

  Map<String, dynamic> toJson() => {
    'ownedCameras': ownedCameras.map((c) => c.toJson()).toList(),
    'rolls': rolls.map((r) => r.toJson()).toList(),
    'photos': photos.map((p) => p.toJson()).toList(),
    'discoveredEasterEggIds': discoveredEasterEggIds.toList(),
    'equippedCameraId': equippedCameraId,
    'activeRollId': activeRollId,
    'nextFrameCounter': nextFrameCounter,
  };

  factory AppState.fromJson(Map<String, dynamic> json) => AppState(
    ownedCameras: (json['ownedCameras'] as List? ?? [])
        .map((e) => OwnedCamera.fromJson(e as Map<String, dynamic>))
        .toList(),
    rolls: (json['rolls'] as List? ?? [])
        .map((e) => PhotoRoll.fromJson(e as Map<String, dynamic>))
        .toList(),
    photos: (json['photos'] as List? ?? [])
        .map((e) => Photo.fromJson(e as Map<String, dynamic>))
        .toList(),
    discoveredEasterEggIds:
        ((json['discoveredEasterEggIds'] as List?)?.cast<String>() ?? const []).toSet(),
    equippedCameraId: json['equippedCameraId'] as String?,
    activeRollId: json['activeRollId'] as String?,
    nextFrameCounter: json['nextFrameCounter'] as int? ?? 0,
  );
}

class AppRepository {
  static const _stateFileName = 'archive_state.json';

  Future<Directory> get _docsDir async => getApplicationDocumentsDirectory();

  Future<Directory> get photosDir async {
    final dir = Directory('${(await _docsDir).path}/photos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> get thumbsDir async {
    final dir = Directory('${(await _docsDir).path}/thumbs');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> get _stateFile async => File('${(await _docsDir).path}/$_stateFileName');

  Future<AppState> load() async {
    try {
      final file = await _stateFile;
      if (!await file.exists()) return AppState.initial();
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return AppState.initial();
      return AppState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt or unreadable state file — start fresh rather than crash.
      return AppState.initial();
    }
  }

  Future<void> save(AppState state) async {
    final file = await _stateFile;
    await file.writeAsString(jsonEncode(state.toJson()));
  }
}
