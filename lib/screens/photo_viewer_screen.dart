import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/camera_catalog.dart';
import '../data/skin_catalog.dart';
import '../models/camera_profile.dart';
import '../models/camera_readout.dart';
import '../models/camera_skin.dart';
import '../state/archive_store.dart';
import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';
import '../widgets/device_icons.dart';

/// Digital-camera playback chrome: a firmware header strip, a toggleable
/// firmware metadata readout, and a PREV/INFO/NEXT/DELETE control row —
/// replacing the old AppBar + bare PageView pattern.
class PhotoViewerScreen extends StatefulWidget {
  final String rollId;
  final String initialPhotoId;

  const PhotoViewerScreen({super.key, required this.rollId, required this.initialPhotoId});

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller;
  late int _index;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    final store = context.read<ArchiveStore>();
    final photos = store.photosForRoll(widget.rollId);
    _index = photos.indexWhere((p) => p.id == widget.initialPhotoId).clamp(0, photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(page, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
  }

  Future<void> _delete(BuildContext context, String photoId, int currentIndex, int total) async {
    final store = context.read<ArchiveStore>();
    final skin = context.skin;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DELETE PHOTO?'),
        content: const Text('This deletes the photo permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: skin.charcoal,
              foregroundColor: skin.warningRed,
              side: BorderSide(color: skin.warningRed),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await store.deletePhoto(photoId);
    if (!context.mounted) return;
    if (total <= 1) {
      Navigator.of(context).pop();
      return;
    }
    final nextIndex = currentIndex.clamp(0, total - 2);
    setState(() => _index = nextIndex);
    if (_controller.hasClients) _controller.jumpToPage(nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final store = context.watch<ArchiveStore>();
    final photos = store.photosForRoll(widget.rollId);
    if (photos.isEmpty) {
      return Scaffold(backgroundColor: skin.black, body: const SizedBox.shrink());
    }
    final index = _index.clamp(0, photos.length - 1);

    return Scaffold(
      backgroundColor: skin.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: DeviceIcon(DeviceGlyph.chevronBack, color: skin.lcdWhite),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text('PLAY', style: skin.uppercaseLabel(fontSize: 12, color: skin.amber)),
                    ],
                  ),
                  Text(
                    '${index + 1}/${photos.length}',
                    style: skin.readout(fontSize: 13, color: skin.lcdWhite),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final photo = photos[i];
                  final camera = CameraCatalog.tryById(photo.cameraId);
                  final cameraSkin = store.ownedById(photo.cameraId)?.customization.skinId.skin;
                  return Column(
                    children: [
                      Expanded(
                        child: InteractiveViewer(
                          child: Center(child: Image.file(File(photo.filePath))),
                        ),
                      ),
                      if (_showInfo)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          child: _MetadataBlock(
                            frameLabel: photo.frameNumber != null
                                ? 'IMG_${photo.frameNumber.toString().padLeft(4, '0')}'
                                : 'IMG_${(i + 1).toString().padLeft(4, '0')}',
                            dateTime: _formatDateTime(photo.takenAt),
                            camera: camera,
                            cameraSkin: cameraSkin,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            _PlaybackControls(
              onPrev: index > 0 ? () => _goTo(index - 1) : null,
              onNext: index < photos.length - 1 ? () => _goTo(index + 1) : null,
              onInfo: () => setState(() => _showInfo = !_showInfo),
              onDelete: () => _delete(context, photos[index].id, index, photos.length),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $hour:$minute $ampm';
  }
}

class _MetadataBlock extends StatelessWidget {
  final String frameLabel;
  final String dateTime;
  final CameraProfile? camera;
  final CameraSkin? cameraSkin;

  const _MetadataBlock({
    required this.frameLabel,
    required this.dateTime,
    required this.camera,
    required this.cameraSkin,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final profile = camera;
    // The identity-bearing readout uses the photo's OWN camera's skin
    // accent (matching what its date stamp actually looks like), falling
    // back to the ambient skin if that camera is somehow no longer owned.
    final accent = cameraSkin?.amber ?? skin.amber;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: skin.hudScrim,
        borderRadius: BorderRadius.circular(AppRadii.tight),
        border: Border.all(color: skin.graphite),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(frameLabel, style: skin.readout(fontSize: 13, color: skin.lcdWhite, weight: FontWeight.w700)),
              Text(dateTime, style: skin.readout(fontSize: 11.5, color: skin.mutedText)),
            ],
          ),
          if (profile != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(profile.isoDisplay, style: skin.readout(fontSize: 11.5, color: accent)),
                Text(profile.shutterDisplay, style: skin.readout(fontSize: 11.5, color: accent)),
                Text(profile.apertureDisplay, style: skin.readout(fontSize: 11.5, color: accent)),
              ],
            ),
            const SizedBox(height: 4),
            Text('FILM: ${profile.name}', style: skin.uppercaseLabel(fontSize: 10.5, color: skin.dimAmber)),
          ],
        ],
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onInfo;
  final VoidCallback onDelete;

  const _PlaybackControls({
    required this.onPrev,
    required this.onNext,
    required this.onInfo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: skin.charcoal,
        border: Border(top: BorderSide(color: skin.graphite)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ControlButton(label: 'PREV', glyph: DeviceGlyph.chevronLeft, onTap: onPrev),
          _ControlButton(label: 'INFO', glyph: DeviceGlyph.info, onTap: onInfo),
          _ControlButton(label: 'NEXT', glyph: DeviceGlyph.chevronRight, onTap: onNext),
          _ControlButton(label: 'DELETE', glyph: DeviceGlyph.delete, onTap: onDelete, danger: true),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final DeviceGlyph glyph;
  final VoidCallback? onTap;
  final bool danger;

  const _ControlButton({required this.label, required this.glyph, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final color = onTap == null ? skin.mutedText : (danger ? skin.warningRed : skin.lcdWhite);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DeviceIcon(glyph, size: 18, color: color),
            const SizedBox(height: 4),
            Text(label, style: skin.uppercaseLabel(fontSize: 9.5, color: color)),
          ],
        ),
      ),
    );
  }
}
