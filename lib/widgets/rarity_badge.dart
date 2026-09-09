import 'package:flutter/material.dart';

import '../models/rarity.dart';
import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';

/// A firmware-style rarity indicator: a small drawn status-LED square (never
/// an emoji standing in for one) plus an uppercase label, in a rectangular
/// bezel — the pill shape is retired app-wide in favor of AppRadii.tight.
class RarityBadge extends StatelessWidget {
  final Rarity rarity;
  final bool compact;

  const RarityBadge({super.key, required this.rarity, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final ledSize = compact ? 6.0 : 8.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: skin.charcoal,
        borderRadius: BorderRadius.circular(AppRadii.tight),
        border: Border.all(color: rarity.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ledSize,
            height: ledSize,
            decoration: BoxDecoration(
              color: rarity.color,
              borderRadius: BorderRadius.circular(1.5),
              border: Border.all(color: skin.graphite, width: 0.5),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            rarity.label,
            style: skin.uppercaseLabel(fontSize: compact ? 9.5 : 11, color: rarity.color),
          ),
        ],
      ),
    );
  }
}
