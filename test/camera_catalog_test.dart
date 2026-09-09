// Catalog integrity: every camera has a unique id, the starter camera
// resolves, and every pair of cameras is visually distinct — turning the
// catalog's own "no two cameras look the same" claim into an enforced
// invariant rather than an eyeballed one.
import 'package:camera_archive/data/camera_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CameraCatalog', () {
    test('has the expected number of cameras', () {
      expect(CameraCatalog.all.length, 17);
    });

    test('every camera has a unique id', () {
      final ids = CameraCatalog.all.map((c) => c.id).toSet();
      expect(ids.length, CameraCatalog.all.length);
    });

    test('starterCameraId resolves to the starter profile', () {
      final starter = CameraCatalog.byId(CameraCatalog.starterCameraId);
      expect(starter.isStarter, isTrue);
    });

    test('tryById returns null for an unknown id', () {
      expect(CameraCatalog.tryById('nonexistent_camera'), isNull);
    });

    test('every camera is visually distinct from every other camera', () {
      const threshold = 0.05;
      const minDistinctKnobs = 3;
      final all = CameraCatalog.all;
      for (var i = 0; i < all.length; i++) {
        for (var j = i + 1; j < all.length; j++) {
          final a = all[i], b = all[j];
          final diffs = [
            (a.saturation - b.saturation).abs(),
            (a.contrast - b.contrast).abs(),
            (a.brightness - b.brightness).abs(),
            (a.warmth - b.warmth).abs(),
            (a.sensorNoise - b.sensorNoise).abs(),
            (a.sharpenAmount - b.sharpenAmount).abs(),
            (a.vignetteStrength - b.vignetteStrength).abs(),
            (a.bloomAmount - b.bloomAmount).abs(),
            (a.highlightClip - b.highlightClip).abs(),
            (a.shadowCrush - b.shadowCrush).abs(),
            (a.lensDistortion - b.lensDistortion).abs(),
            (a.softness - b.softness).abs(),
            (a.chromaticAberration - b.chromaticAberration).abs(),
            (a.lightLeakChance - b.lightLeakChance).abs(),
            (a.scanlineStrength - b.scanlineStrength).abs(),
            (a.crossProcessAmount - b.crossProcessAmount).abs(),
            (a.doubleCompressionAmount - b.doubleCompressionAmount).abs(),
          ];
          final distinctCount = diffs.where((d) => d > threshold).length;
          expect(
            distinctCount >= minDistinctKnobs,
            isTrue,
            reason:
                '${a.id} and ${b.id} only differ meaningfully on $distinctCount '
                'knob(s), need >= $minDistinctKnobs',
          );
        }
      }
    });
  });
}
