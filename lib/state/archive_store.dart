import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/app_repository.dart';
import '../data/camera_catalog.dart';
import '../models/camera_customization.dart';
import '../models/camera_profile.dart';
import '../models/owned_camera.dart';
import '../models/photo.dart';
import '../models/photo_roll.dart';
import '../models/rarity.dart';

/// Single in-memory source of truth for everything persisted: the owned
/// camera collection, photo rolls, and photo metadata. All three live in one
/// small JSON file (see AppRepository) so one store keeping them consistent
/// is simpler than juggling cross-references between separate providers.
class ArchiveStore extends ChangeNotifier {
  final AppRepository _repo;
  static const _uuid = Uuid();

  AppState _state = AppState.initial();
  bool _loaded = false;

  ArchiveStore(this._repo);

  bool get isLoaded => _loaded;

  Future<void> load() async {
    _state = await _repo.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() => _repo.save(_state);

  // ---------------- Collection ----------------

  List<OwnedCamera> get ownedCameras => List.unmodifiable(_state.ownedCameras);

  List<CameraProfile> get ownedProfiles =>
      _state.ownedCameras.map((o) => CameraCatalog.byId(o.cameraId)).toList();

  bool isOwned(String cameraId) => _state.ownedCameras.any((o) => o.cameraId == cameraId);

  OwnedCamera? ownedById(String cameraId) {
    for (final o in _state.ownedCameras) {
      if (o.cameraId == cameraId) return o;
    }
    return null;
  }

  String? get equippedCameraId => _state.equippedCameraId;

  CameraProfile get equippedProfile =>
      CameraCatalog.tryById(_state.equippedCameraId ?? '') ??
      CameraCatalog.byId(CameraCatalog.starterCameraId);

  void equipCamera(String cameraId) {
    if (!isOwned(cameraId)) return;
    _state.equippedCameraId = cameraId;
    notifyListeners();
    _persist();
  }

  Map<Rarity, int> get ownedRarityCounts {
    final counts = {for (final r in Rarity.values) r: 0};
    for (final o in _state.ownedCameras) {
      final profile = CameraCatalog.tryById(o.cameraId);
      if (profile != null) counts[profile.rarity] = (counts[profile.rarity] ?? 0) + 1;
    }
    return counts;
  }

  int get totalCameraCount => CameraCatalog.all.length;
  int get ownedCameraCount => _state.ownedCameras.length;

  List<CameraProfile> get undiscoveredProfiles => CameraCatalog.all
      .where((c) => !isOwned(c.id))
      .toList();

  bool get hasUndiscovered => undiscoveredProfiles.isNotEmpty;

  /// Rarity-weighted pick from the not-yet-owned pool. Returns null if the
  /// whole catalog has already been collected.
  CameraProfile? discover({Random? random}) {
    final pool = undiscoveredProfiles;
    if (pool.isEmpty) return null;
    final rnd = random ?? Random();
    final totalWeight = pool.fold<int>(0, (sum, c) => sum + c.rarity.discoverWeight);
    var roll = rnd.nextInt(totalWeight);
    for (final c in pool) {
      roll -= c.rarity.discoverWeight;
      if (roll < 0) {
        _state.ownedCameras.add(OwnedCamera(cameraId: c.id, acquiredAt: DateTime.now()));
        notifyListeners();
        _persist();
        return c;
      }
    }
    // Fallback (shouldn't hit given the loop above covers the full weight).
    final c = pool.last;
    _state.ownedCameras.add(OwnedCamera(cameraId: c.id, acquiredAt: DateTime.now()));
    notifyListeners();
    _persist();
    return c;
  }

  void updateCustomization(String cameraId, CameraCustomization customization) {
    final index = _state.ownedCameras.indexWhere((o) => o.cameraId == cameraId);
    if (index == -1) return;
    _state.ownedCameras[index] = _state.ownedCameras[index].copyWith(
      customization: customization,
    );
    notifyListeners();
    _persist();
  }

  // ---------------- Rolls ----------------

  List<PhotoRoll> get rolls =>
      List.unmodifiable(_state.rolls.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  PhotoRoll? rollById(String id) {
    for (final r in _state.rolls) {
      if (r.id == id) return r;
    }
    return null;
  }

  PhotoRoll? get activeRoll =>
      _state.activeRollId == null ? null : rollById(_state.activeRollId!);

  int photoCountForRoll(String rollId) => _state.photos.where((p) => p.rollId == rollId).length;

  List<Photo> photosForRoll(String rollId) =>
      _state.photos.where((p) => p.rollId == rollId).toList()
        ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

  Photo? photoById(String id) {
    for (final p in _state.photos) {
      if (p.id == id) return p;
    }
    return null;
  }

  PhotoRoll createRoll({
    required String name,
    required String primaryCameraId,
    String? locationLabel,
    double? latitude,
    double? longitude,
  }) {
    final roll = PhotoRoll(
      id: _uuid.v4(),
      name: name,
      primaryCameraId: primaryCameraId,
      createdAt: DateTime.now(),
      locationLabel: locationLabel,
      latitude: latitude,
      longitude: longitude,
    );
    _state.rolls.add(roll);
    _state.activeRollId = roll.id;
    notifyListeners();
    _persist();
    return roll;
  }

  void setActiveRoll(String rollId) {
    _state.activeRollId = rollId;
    notifyListeners();
    _persist();
  }

  void renameRoll(String rollId, String name) {
    _replaceRoll(rollId, (r) => r.copyWith(name: name));
  }

  void updateRollNotes(String rollId, String notes) {
    _replaceRoll(rollId, (r) => r.copyWith(notes: notes));
  }

  void attachRollLocation(String rollId, {String? label, double? lat, double? lng}) {
    _replaceRoll(rollId, (r) => r.copyWith(locationLabel: label, latitude: lat, longitude: lng));
  }

  void _replaceRoll(String rollId, PhotoRoll Function(PhotoRoll) update) {
    final index = _state.rolls.indexWhere((r) => r.id == rollId);
    if (index == -1) return;
    _state.rolls[index] = update(_state.rolls[index]);
    notifyListeners();
    _persist();
  }

  /// Assigns the next firmware-style shot number (see Photo.frameNumber),
  /// persisting the counter so it never repeats across app restarts.
  int nextFrameNumber() {
    final n = _state.nextFrameCounter;
    _state.nextFrameCounter++;
    return n;
  }

  Photo addPhotoToRoll({
    required String rollId,
    required String cameraId,
    required String filePath,
    required String thumbPath,
    required int width,
    required int height,
  }) {
    final photo = Photo(
      id: _uuid.v4(),
      rollId: rollId,
      cameraId: cameraId,
      filePath: filePath,
      thumbPath: thumbPath,
      takenAt: DateTime.now(),
      width: width,
      height: height,
      frameNumber: nextFrameNumber(),
    );
    _state.photos.add(photo);
    final index = _state.rolls.indexWhere((r) => r.id == rollId);
    if (index != -1) {
      final r = _state.rolls[index];
      _state.rolls[index] = r.copyWith(photoIds: [...r.photoIds, photo.id]);
    }
    notifyListeners();
    _persist();
    return photo;
  }

  Future<void> deleteRoll(String rollId) async {
    final photos = photosForRoll(rollId);
    for (final p in photos) {
      await _tryDelete(p.filePath);
      await _tryDelete(p.thumbPath);
    }
    _state.photos.removeWhere((p) => p.rollId == rollId);
    _state.rolls.removeWhere((r) => r.id == rollId);
    if (_state.activeRollId == rollId) _state.activeRollId = null;
    notifyListeners();
    await _persist();
  }

  /// Deletes one photo (its files and metadata), removing it from whatever
  /// roll references it. Mirrors deleteRoll's best-effort file-cleanup
  /// pattern — a failed disk delete never blocks removing the metadata.
  Future<void> deletePhoto(String photoId) async {
    final photo = photoById(photoId);
    if (photo == null) return;
    await _tryDelete(photo.filePath);
    await _tryDelete(photo.thumbPath);
    _state.photos.removeWhere((p) => p.id == photoId);
    final index = _state.rolls.indexWhere((r) => r.id == photo.rollId);
    if (index != -1) {
      final r = _state.rolls[index];
      _state.rolls[index] = r.copyWith(
        photoIds: r.photoIds.where((id) => id != photoId).toList(),
      );
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _tryDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  String newPhotoId() => _uuid.v4();
}
