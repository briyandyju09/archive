import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/skin_catalog.dart';
import '../models/camera_skin.dart';
import '../state/archive_store.dart';
import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';
import '../widgets/device_icons.dart';

/// A browsing/reference gallery of the five camera bodies — not a
/// gacha-style single reveal like Discover, since skins are always-visible,
/// always-selectable reference material, not something gated behind a
/// reveal. Tapping a card applies that skin, instantly, to the currently-
/// equipped camera (equippedProfile always resolves to a valid, owned
/// camera — no empty state is needed).
class SkinsScreen extends StatelessWidget {
  const SkinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final store = context.watch<ArchiveStore>();
    final equippedProfile = store.equippedProfile;
    final equippedOwned = store.ownedById(equippedProfile.id)!;
    final currentSkinId = equippedOwned.customization.skinId;

    return Scaffold(
      appBar: AppBar(title: const Text('Skins')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: SkinCatalog.all.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final candidate = SkinCatalog.all[index];
          return _SkinCard(
            skinDef: candidate,
            applied: candidate.id == currentSkinId.skin.id,
            onTap: () {
              store.updateCustomization(
                equippedProfile.id,
                equippedOwned.customization.copyWith(skinId: CameraSkinIdX.fromName(candidate.id)),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${candidate.name.toUpperCase()} applied to ${equippedProfile.name}',
                    style: skin.readout(fontSize: 13, color: skin.lcdWhite),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Deliberately NOT styled from the ambient app skin — each card is a
/// literal mini-demonstration built from that skin's own colors, so it
/// shows what your controls will actually look like rather than just
/// naming a color.
class _SkinCard extends StatelessWidget {
  final CameraSkin skinDef;
  final bool applied;
  final VoidCallback onTap;

  const _SkinCard({required this.skinDef, required this.applied, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.panel),
      onTap: onTap,
      child: Container(
        decoration: skinDef.panelDecoration(borderColor: applied ? skinDef.amber : null),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  skinDef.name.toUpperCase(),
                  style: skinDef.uppercaseLabel(fontSize: 14, color: skinDef.lcdWhite),
                ),
                if (applied)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: skinDef.lcdGreen, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text('APPLIED', style: skinDef.uppercaseLabel(fontSize: 9.5, color: skinDef.lcdGreen)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(skinDef.personality, style: skinDef.prose(fontSize: 12.5, color: skinDef.mutedText)),
            const SizedBox(height: 12),
            Row(
              children: [
                _swatch(skinDef.charcoal, skinDef),
                const SizedBox(width: 4),
                _swatch(skinDef.graphite, skinDef),
                const SizedBox(width: 4),
                _swatch(skinDef.amber, skinDef),
                const SizedBox(width: 4),
                _swatch(skinDef.warningRed, skinDef),
                const Spacer(),
                // A miniature "this is what your controls will look like"
                // preview, in this skin's own colors.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: skinDef.charcoal,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                    border: Border.all(color: skinDef.amber, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DeviceIcon(DeviceGlyph.cameraBody, size: 13, color: skinDef.amber),
                      const SizedBox(width: 5),
                      Text(
                        skinDef.name.toUpperCase(),
                        style: skinDef.uppercaseLabel(fontSize: 9.5, color: skinDef.amber),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color color, CameraSkin skinDef) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: skinDef.graphite, width: 1),
      ),
    );
  }
}
