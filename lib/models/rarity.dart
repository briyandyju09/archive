import 'package:flutter/material.dart';

/// How hard a camera is to find/collect, from most to least common.
enum Rarity { common, uncommon, rare, vintage, legendary }

extension RarityDisplay on Rarity {
  String get label => switch (this) {
    Rarity.common => 'Common',
    Rarity.uncommon => 'Uncommon',
    Rarity.rare => 'Rare',
    Rarity.vintage => 'Vintage',
    Rarity.legendary => 'Legendary',
  };

  Color get color => switch (this) {
    Rarity.common => const Color(0xFF4CAF6D),
    Rarity.uncommon => const Color(0xFF4C8DFF),
    Rarity.rare => const Color(0xFFB16CFF),
    Rarity.vintage => const Color(0xFFE0912F),
    Rarity.legendary => const Color(0xFFE0473F),
  };

  /// Relative pull-weight used by the discover mechanic. Higher = more likely.
  int get discoverWeight => switch (this) {
    Rarity.common => 40,
    Rarity.uncommon => 26,
    Rarity.rare => 16,
    Rarity.vintage => 10,
    Rarity.legendary => 4,
  };

  static Rarity fromName(String name) =>
      Rarity.values.firstWhere((r) => r.name == name, orElse: () => Rarity.common);
}
