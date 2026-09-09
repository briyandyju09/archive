import 'package:flutter/material.dart';

import '../models/camera_customization.dart';
import '../models/camera_profile.dart';
import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';
import 'camera_icon.dart';
import 'device_panel.dart';
import 'rarity_badge.dart';

class CameraShelfCard extends StatelessWidget {
  final CameraProfile profile;
  final bool owned;
  final bool equipped;
  final BodyColor? bodyColor;
  final VoidCallback onTap;

  const CameraShelfCard({
    super.key,
    required this.profile,
    required this.owned,
    required this.onTap,
    this.equipped = false,
    this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.panel),
      onTap: onTap,
      child: DevicePanel(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${profile.year}', style: skin.uppercaseLabel(fontSize: 11, color: skin.dimAmber)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (equipped) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: skin.lcdGreen,
                          borderRadius: BorderRadius.circular(1.5),
                          border: Border.all(color: skin.graphite, width: 0.5),
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    RarityBadge(rarity: profile.rarity, compact: true),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: CameraIcon(bodyColor: bodyColor, locked: !owned, size: 60),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              profile.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: skin.readout(fontSize: 13.5, color: skin.lcdWhite, weight: FontWeight.w700),
            ),
            if (owned)
              Text(
                '${profile.megapixels.toStringAsFixed(profile.megapixels % 1 == 0 ? 0 : 1)}MP',
                style: skin.uppercaseLabel(fontSize: 10.5, color: skin.dimAmber),
              )
            else
              Text(
                'UNDISCOVERED',
                style: skin.uppercaseLabel(fontSize: 10.5, color: skin.mutedText),
              ),
          ],
        ),
      ),
    );
  }
}
