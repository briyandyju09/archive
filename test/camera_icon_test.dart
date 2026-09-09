// Regression coverage for the per-camera icon archetype dispatch: every
// CameraSilhouette must paint without throwing, locked or unlocked, on a
// dark-bodied skin and on the one light-bodied (Archive) skin.
import 'package:camera_archive/data/skin_catalog.dart';
import 'package:camera_archive/models/camera_silhouette.dart';
import 'package:camera_archive/theme/app_theme.dart';
import 'package:camera_archive/widgets/camera_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every CameraSilhouette renders without throwing', (tester) async {
    for (final silhouette in CameraSilhouette.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeFor(SkinCatalog.nightVision),
          home: Scaffold(
            body: Center(child: CameraIcon(silhouette: silhouette, size: 64)),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$silhouette failed to paint');
    }
  });

  testWidgets('locked state renders without throwing for every silhouette on Archive', (tester) async {
    for (final silhouette in CameraSilhouette.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeFor(SkinCatalog.archive),
          home: Scaffold(
            body: Center(child: CameraIcon(silhouette: silhouette, locked: true, size: 64)),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$silhouette (locked) failed to paint');
    }
  });
}
