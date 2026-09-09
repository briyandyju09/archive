import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/camera_catalog.dart';
import '../data/skin_catalog.dart';
import '../models/camera_customization.dart';
import '../models/camera_profile.dart';
import '../models/owned_camera.dart';
import '../state/archive_store.dart';
import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';
import '../widgets/camera_icon.dart';
import '../widgets/device_icons.dart';
import '../widgets/device_panel.dart';
import '../widgets/lcd_date_stamp_preview.dart';
import '../widgets/rarity_badge.dart';
import 'capture_screen.dart';

class CameraDetailScreen extends StatelessWidget {
  final String cameraId;

  const CameraDetailScreen({super.key, required this.cameraId});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final profile = CameraCatalog.byId(cameraId);
    final store = context.watch<ArchiveStore>();
    final owned = store.ownedById(cameraId);

    if (owned == null) {
      return Scaffold(
        appBar: AppBar(title: Text(profile.name)),
        body: Center(
          child: Text(
            'You have not discovered this camera yet.',
            style: skin.prose(color: skin.mutedText),
          ),
        ),
      );
    }

    final isEquipped = store.equippedCameraId == cameraId;

    return Scaffold(
      appBar: AppBar(title: Text(profile.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Center(
            child: CameraIcon(bodyColor: owned.customization.bodyColor, size: 130),
          ),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                RarityBadge(rarity: profile.rarity),
                if (profile.isEasterEgg)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: skin.charcoal,
                      borderRadius: BorderRadius.circular(AppRadii.tight),
                      border: Border.all(color: skin.graphite),
                    ),
                    child: Text('EASTER EGG', style: skin.uppercaseLabel(fontSize: 10, color: skin.dimAmber)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: _EquipToggle(
              equipped: isEquipped,
              onTap: () => store.equipCamera(cameraId),
            ),
          ),
          const SizedBox(height: 16),
          Text(profile.description, style: skin.prose(color: skin.lcdWhite)),
          const SizedBox(height: 20),
          _SpecsCard(profile: profile),
          const SizedBox(height: 20),
          Text('CUSTOMIZE', style: skin.uppercaseLabel(fontSize: 13, color: skin.lcdWhite)),
          const SizedBox(height: 8),
          _CustomizationCard(profile: profile, owned: owned),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CaptureScreen(cameraId: cameraId)),
            );
          },
          icon: DeviceIcon(DeviceGlyph.shutterRelease, size: 16, color: skin.amber),
          label: const Text('USE THIS CAMERA'),
        ),
      ),
    );
  }
}

/// A small bordered action showing/toggling whether this is the app's
/// globally-equipped camera — the one whose skin drives the whole app's
/// chrome outside the capture screen (which always shows the shooting
/// camera's own skin regardless of equip state). There's no "unequip";
/// `ArchiveStore.equippedProfile` always falls back to the starter camera,
/// so the only real transition is equipping a *different* camera from
/// *that* camera's own detail screen.
class _EquipToggle extends StatelessWidget {
  final bool equipped;
  final VoidCallback onTap;

  const _EquipToggle({required this.equipped, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final color = equipped ? skin.amber : skin.lcdWhite;
    return InkWell(
      onTap: equipped ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: skin.charcoal,
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: equipped ? skin.amber : skin.graphite, width: equipped ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: equipped ? skin.lcdGreen : skin.graphite,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              equipped ? 'EQUIPPED' : 'EQUIP THIS CAMERA',
              style: skin.uppercaseLabel(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecsCard extends StatelessWidget {
  final CameraProfile profile;

  const _SpecsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final rows = <(String, String)>[
      ('YEAR', '${profile.year}'),
      ('RESOLUTION', '${profile.megapixels.toStringAsFixed(profile.megapixels % 1 == 0 ? 0 : 1)}MP'),
      ('SENSOR', profile.sensorType),
      ('LENS', profile.lensInfo),
      ('FLASH', profile.flashInfo),
      ('ASPECT RATIO', profile.aspectRatio.label),
      ('DIGITAL ZOOM', '${profile.maxDigitalZoom.toStringAsFixed(1)}x'),
      ('SHUTTER LAG', '${profile.shutterLagMs}ms'),
      ('STORAGE', '${profile.storageCapacityShots} SHOTS/ROLL'),
    ];
    return DevicePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: skin.graphite, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rows[i].$1, style: skin.uppercaseLabel(fontSize: 11.5, color: skin.dimAmber)),
                  Text(rows[i].$2, style: skin.readout(fontSize: 13, color: skin.lcdWhite, weight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomizationCard extends StatelessWidget {
  final CameraProfile profile;
  final OwnedCamera owned;

  const _CustomizationCard({required this.profile, required this.owned});

  @override
  Widget build(BuildContext context) {
    final store = context.read<ArchiveStore>();
    final c = owned.customization;

    void update(CameraCustomization next) => store.updateCustomization(profile.id, next);

    return DevicePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(
            label: 'Body Color',
            child: Wrap(
              spacing: 8,
              children: BodyColor.values.map((b) {
                return _DeviceChoiceChip(
                  label: b.label,
                  selected: c.bodyColor == b,
                  onSelected: () => update(c.copyWith(bodyColor: b)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            label: 'Strap',
            child: Wrap(
              spacing: 8,
              children: CameraStrap.values.map((s) {
                return _DeviceChoiceChip(
                  label: s.label,
                  selected: c.strap == s,
                  onSelected: () => update(c.copyWith(strap: s)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            label: 'Date Stamp',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DateStampFormat.values.map((f) {
                    return _DeviceChoiceChip(
                      label: f.sample,
                      selected: c.dateStampFormat == f,
                      onSelected: () => update(c.copyWith(dateStampFormat: f)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                LcdDateStampPreview(
                  text: c.dateStampFormat == DateStampFormat.off
                      ? ''
                      : c.dateStampFormat.format(DateTime.now()),
                  color: c.skinId.skin.dateStampColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            label: 'Flash',
            child: Wrap(
              spacing: 8,
              children: FlashMode.values.map((f) {
                final locked = profile.flashCapability != FlashCapability.autoOffOn;
                return _DeviceChoiceChip(
                  label: f.label,
                  selected: c.flashMode == f,
                  onSelected: locked ? null : () => update(c.copyWith(flashMode: f)),
                );
              }).toList(),
            ),
          ),
          if (profile.flashCapability == FlashCapability.alwaysOn)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "This camera's flash is stuck on — it always fires.",
                style: context.skin.prose(fontSize: 12.5, color: context.skin.mutedText),
              ),
            ),
          if (profile.flashCapability == FlashCapability.none)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'This camera has no flash hardware.',
                style: context.skin.prose(fontSize: 12.5, color: context.skin.mutedText),
              ),
            ),
          const SizedBox(height: 14),
          _Section(
            label: 'Skin',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CameraSkinId.values.map((s) {
                return _DeviceChoiceChip(
                  label: s.skin.name,
                  swatchColor: s.skin.amber,
                  selected: c.skinId == s,
                  onSelected: () => update(c.copyWith(skinId: s)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rectangular bordered toggle replacing Material's filled-pill
/// [ChoiceChip] — 1px graphite hairline at rest, 1.5px amber when selected.
/// [swatchColor], when given, draws a small color dot before the label (used
/// by the Skin picker, since a bare skin name doesn't communicate material
/// the way "Silver"/"Black" body-color labels already do on their own).
class _DeviceChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final Color? swatchColor;

  const _DeviceChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.swatchColor,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final color = onSelected == null ? skin.mutedText : (selected ? skin.amber : skin.lcdWhite);
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: skin.charcoal,
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: selected ? skin.amber : skin.graphite, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (swatchColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: swatchColor,
                  borderRadius: BorderRadius.circular(1.5),
                  border: Border.all(color: skin.graphite, width: 0.5),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(label.toUpperCase(), style: skin.uppercaseLabel(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final Widget child;

  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: skin.uppercaseLabel(fontSize: 11.5, color: skin.dimAmber)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
