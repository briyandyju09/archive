import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/camera_catalog.dart';
import '../state/archive_store.dart';
import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';
import '../widgets/device_icons.dart';
import 'capture_screen.dart';
import 'photo_viewer_screen.dart';

class RollDetailScreen extends StatelessWidget {
  final String rollId;

  const RollDetailScreen({super.key, required this.rollId});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final store = context.watch<ArchiveStore>();
    final roll = store.rollById(rollId);
    if (roll == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('This roll was deleted.', style: skin.prose(color: skin.mutedText))),
      );
    }
    final camera = CameraCatalog.tryById(roll.primaryCameraId);
    final photos = store.photosForRoll(rollId);
    final owned = camera != null ? store.isOwned(camera.id) : false;

    return Scaffold(
      appBar: AppBar(
        title: Text(roll.name),
        actions: [
          PopupMenuButton<String>(
            icon: DeviceIcon(DeviceGlyph.info, size: 20, color: skin.lcdWhite),
            onSelected: (v) async {
              if (v == 'rename') {
                await _rename(context, roll.name, (name) => store.renameRoll(rollId, name));
              } else if (v == 'notes') {
                await _editNotes(context, roll.notes, (n) => store.updateRollNotes(rollId, n));
              } else if (v == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('DELETE ROLL?'),
                    content: Text('This deletes "${roll.name}" and its ${photos.length} photo(s) permanently.'),
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
                if (confirm == true) {
                  await store.deleteRoll(rollId);
                  if (context.mounted) Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'rename', child: Text('RENAME')),
              PopupMenuItem(value: 'notes', child: Text('EDIT NOTES')),
              PopupMenuItem(value: 'delete', child: Text('DELETE ROLL')),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _MetaField(label: 'CAM', value: camera?.name ?? 'Unknown camera'),
                  _MetaField(label: 'DATE', value: _formatDate(roll.createdAt)),
                  if (roll.locationLabel != null) _MetaField(label: 'LOC', value: roll.locationLabel!),
                  _MetaField(
                    label: 'EXPOSURES',
                    value: camera == null ? '${photos.length}' : '${photos.length}/${camera.storageCapacityShots}',
                  ),
                ],
              ),
            ),
          ),
          if (roll.notes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(roll.notes, style: skin.prose(color: skin.lcdWhite)),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            sliver: photos.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No photos in this roll yet.', style: skin.prose(color: skin.mutedText)),
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final photo = photos[index];
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PhotoViewerScreen(rollId: rollId, initialPhotoId: photo.id),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadii.tight),
                            border: Border.all(color: skin.graphite),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.file(File(photo.thumbPath), fit: BoxFit.cover),
                        ),
                      );
                    }, childCount: photos.length),
                  ),
          ),
        ],
      ),
      floatingActionButton: owned
          ? FloatingActionButton.extended(
              backgroundColor: skin.charcoal,
              foregroundColor: skin.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.control),
                side: BorderSide(color: skin.amber, width: 1),
              ),
              onPressed: () {
                store.setActiveRoll(rollId);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CaptureScreen(cameraId: camera.id)),
                );
              },
              icon: DeviceIcon(DeviceGlyph.shutterRelease, size: 16, color: skin.amber),
              label: Text('Keep Shooting', style: skin.uppercaseLabel(fontSize: 13, color: skin.amber)),
            )
          : null,
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _rename(BuildContext context, String current, void Function(String) onSave) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('RENAME ROLL'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('SAVE')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) onSave(name);
  }

  Future<void> _editNotes(BuildContext context, String current, void Function(String) onSave) async {
    final controller = TextEditingController(text: current);
    final notes = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ROLL NOTES'),
        content: TextField(controller: controller, autofocus: true, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('SAVE')),
        ],
      ),
    );
    if (notes != null) onSave(notes);
  }
}

/// A firmware-style inline "LABEL: value" field, replacing the old
/// icon+text pill chip.
class _MetaField extends StatelessWidget {
  final String label;
  final String value;

  const _MetaField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: skin.charcoal,
        borderRadius: BorderRadius.circular(AppRadii.tight),
        border: Border.all(color: skin.graphite),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label: ', style: skin.uppercaseLabel(fontSize: 10.5, color: skin.dimAmber)),
            TextSpan(text: value, style: skin.readout(fontSize: 11.5, color: skin.lcdWhite)),
          ],
        ),
      ),
    );
  }
}
