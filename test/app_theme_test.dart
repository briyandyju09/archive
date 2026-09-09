// Locks in the AppTheme.themeFor brightness fix: Archive is the one
// structurally light-bodied skin and must compute as Brightness.light, not
// the previously-hardcoded Brightness.dark.
import 'package:camera_archive/data/skin_catalog.dart';
import 'package:camera_archive/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme.themeFor', () {
    test('Archive (light body) computes as Brightness.light', () {
      final theme = AppTheme.themeFor(SkinCatalog.archive);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('every other skin still computes as Brightness.dark', () {
      for (final skin in SkinCatalog.all) {
        if (skin.id == 'archive') continue;
        final theme = AppTheme.themeFor(skin);
        expect(theme.brightness, Brightness.dark, reason: '${skin.name} should be dark');
      }
    });
  });
}
