import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/camera_catalog.dart';
import '../models/rarity.dart';
import '../state/archive_store.dart';
import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';
import '../widgets/camera_shelf_card.dart';
import '../widgets/device_icons.dart';
import '../widgets/device_panel.dart';
import '../widgets/segmented_bar.dart';
import 'camera_detail_screen.dart';
import 'discover_screen.dart';
import 'skins_screen.dart';

class HomeShelfScreen extends StatelessWidget {
  const HomeShelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final store = context.watch<ArchiveStore>();
    final owned = store.ownedRarityCounts;

    return Scaffold(
      // Literal string preserved — test/widget_test.dart asserts this exact
      // AppBar title. Sentence case, no uppercase transform: uppercase
      // treatment is reserved for chrome text the test doesn't check.
      appBar: AppBar(
        title: const Text('My Cameras'),
        actions: [
          IconButton(
            icon: DeviceIcon(DeviceGlyph.skinSwap, size: 20, color: skin.amber),
            tooltip: 'Skins',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SkinsScreen()),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: _CollectionSummary(
                owned: store.ownedCameraCount,
                total: store.totalCameraCount,
                counts: owned,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final profile = CameraCatalog.all[index];
                final ownedCamera = store.ownedById(profile.id);
                return CameraShelfCard(
                  profile: profile,
                  owned: ownedCamera != null,
                  equipped: store.equippedCameraId == profile.id,
                  bodyColor: ownedCamera?.customization.bodyColor,
                  onTap: () {
                    if (ownedCamera == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CameraDetailScreen(cameraId: profile.id)),
                    );
                  },
                );
              }, childCount: CameraCatalog.all.length),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: skin.charcoal,
        foregroundColor: skin.amber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: BorderSide(color: skin.amber, width: 1),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DiscoverScreen()),
        ),
        icon: DeviceIcon(DeviceGlyph.aperture, size: 18, color: skin.amber),
        // Literal string preserved — test/widget_test.dart asserts this
        // exact FAB label.
        label: Text('Discover Cameras', style: skin.uppercaseLabel(fontSize: 13, color: skin.amber)),
      ),
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  final int owned;
  final int total;
  final Map<Rarity, int> counts;

  const _CollectionSummary({required this.owned, required this.total, required this.counts});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return DevicePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$owned', style: skin.display(fontSize: 40, color: skin.warmWhite)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 6),
                child: Text(
                  '/ $total CAMERAS COLLECTED',
                  style: skin.uppercaseLabel(fontSize: 11, color: skin.dimAmber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedBar(value: total == 0 ? 0 : owned / total),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: Rarity.values.map((r) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: r.color,
                      borderRadius: BorderRadius.circular(1.5),
                      border: Border.all(color: skin.graphite, width: 0.5),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${counts[r] ?? 0} ${r.label}',
                    style: skin.uppercaseLabel(fontSize: 10.5, color: skin.lcdWhite),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
