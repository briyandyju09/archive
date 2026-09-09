import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/camera_catalog.dart';
import '../models/photo_roll.dart';
import '../state/archive_store.dart';
import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';
import '../widgets/device_icons.dart';
import '../widgets/device_panel.dart';
import 'roll_detail_screen.dart';

class RollListScreen extends StatelessWidget {
  const RollListScreen({super.key});

  Future<void> _createRoll(BuildContext context) async {
    final store = context.read<ArchiveStore>();
    final owned = store.ownedProfiles;
    if (owned.isEmpty) return;

    final nameController = TextEditingController();
    String selectedCameraId = store.equippedCameraId ?? owned.first.id;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('NEW ROLL'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Roll name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCameraId,
                  decoration: const InputDecoration(labelText: 'Camera'),
                  items: owned
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCameraId = v ?? selectedCameraId),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CREATE')),
            ],
          ),
        );
      },
    );

    if (result != true || !context.mounted) return;
    final name = nameController.text.trim().isEmpty
        ? 'Untitled Roll'
        : nameController.text.trim();
    final roll = store.createRoll(name: name, primaryCameraId: selectedCameraId);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RollDetailScreen(rollId: roll.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final store = context.watch<ArchiveStore>();
    final rolls = store.rolls;
    // Purely display-layer ordinal — the roll's position by creation order
    // (oldest = 001), independent of this screen's own newest-first sort.
    final ascending = [...rolls]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final ordinals = {for (var i = 0; i < ascending.length; i++) ascending[i].id: i + 1};

    return Scaffold(
      appBar: AppBar(title: const Text('My Rolls')),
      body: rolls.isEmpty
          ? _EmptyState(onCreate: () => _createRoll(context))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: rolls.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final roll = rolls[index];
                return _RollTile(
                  roll: roll,
                  count: store.photoCountForRoll(roll.id),
                  ordinal: ordinals[roll.id] ?? index + 1,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: skin.charcoal,
        foregroundColor: skin.amber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: BorderSide(color: skin.amber, width: 1),
        ),
        onPressed: () => _createRoll(context),
        icon: DeviceIcon(DeviceGlyph.filmRoll, size: 16, color: skin.amber),
        label: Text('New Roll', style: skin.uppercaseLabel(fontSize: 13, color: skin.amber)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DeviceIcon(DeviceGlyph.filmRoll, size: 48, color: skin.graphite),
            const SizedBox(height: 16),
            Text(
              "No rolls yet. Take some photos and they'll show up here.",
              textAlign: TextAlign.center,
              style: skin.prose(color: skin.mutedText),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onCreate, child: const Text('START A ROLL')),
          ],
        ),
      ),
    );
  }
}

class _RollTile extends StatelessWidget {
  final PhotoRoll roll;
  final int count;
  final int ordinal;

  const _RollTile({required this.roll, required this.count, required this.ordinal});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final camera = CameraCatalog.tryById(roll.primaryCameraId);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.panel),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RollDetailScreen(rollId: roll.id)),
      ),
      child: DevicePanel(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: skin.graphite,
                borderRadius: BorderRadius.circular(AppRadii.control),
                border: Border.all(color: skin.dimAmber.withValues(alpha: 0.4)),
              ),
              child: Center(child: DeviceIcon(DeviceGlyph.cameraBody, size: 22, color: skin.amber)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROLL ${ordinal.toString().padLeft(3, '0')}',
                    style: skin.uppercaseLabel(fontSize: 10.5, color: skin.dimAmber),
                  ),
                  const SizedBox(height: 2),
                  Text(roll.name, style: skin.readout(fontSize: 15, color: skin.lcdWhite, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    [
                      camera?.name ?? 'Unknown camera',
                      if (roll.locationLabel != null) roll.locationLabel!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: skin.prose(fontSize: 12.5, color: skin.mutedText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count EXPOSURE${count == 1 ? '' : 'S'}',
              style: skin.uppercaseLabel(fontSize: 10.5, color: skin.dimAmber),
            ),
          ],
        ),
      ),
    );
  }
}
