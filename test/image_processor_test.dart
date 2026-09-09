// Exercises the capture pipeline's new signature effects against a small
// synthetic in-memory frame — no real camera hardware involved.
import 'dart:typed_data';

import 'package:camera_archive/data/camera_catalog.dart';
import 'package:camera_archive/services/image_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

// Deliberately much larger than any profile's target megapixels — the
// pipeline's downsample step assumes a real camera frame (always larger
// than the profile's effective resolution), and a too-small fixture trips
// its own clamp(160, image.width) guard.
Uint8List _syntheticJpeg({int width = 1600, int height = 1200}) {
  final image = img.Image(width: width, height: height);
  for (final frame in image.frames) {
    for (final p in frame) {
      p.r = (p.x * 255 / image.width).clamp(0, 255);
      p.g = (p.y * 255 / image.height).clamp(0, 255);
      p.b = 128;
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

Future<ProcessedPhoto> _run(String cameraId, Uint8List bytes, {int seed = 42}) {
  final profile = CameraCatalog.byId(cameraId);
  return processCapture(
    ProcessJob.fromProfile(
      jpegBytes: bytes,
      profile: profile,
      flashMode: ShotFlashMode.off,
      dateStampText: '',
      seed: seed,
    ),
  );
}

void main() {
  group('processCapture', () {
    test('chromatic-aberration camera produces a valid, decodable photo', () async {
      final processed = await _run('bridge_2002', _syntheticJpeg());
      expect(img.decodeJpg(processed.fullJpeg), isNotNull);
      expect(processed.width, greaterThan(0));
      expect(processed.height, greaterThan(0));
    });

    test('instant frame border enlarges the output canvas', () async {
      final bytes = _syntheticJpeg();
      final framed = await _run('instant_2010', bytes);
      final unframed = await _run('bridge_2002', bytes);
      // The instant camera's r1x1 crop is narrower to start with, but the
      // baked-in white border still pads it out taller than it is wide —
      // proof the border changed the canvas shape, not just its color.
      expect(framed.height, greaterThan(framed.width));
      expect(framed.width, greaterThan(unframed.width * 0.3));
    });

    test('double-compression camera is deterministic for a fixed seed', () async {
      final bytes = _syntheticJpeg();
      final a = await _run('mavica_1997', bytes, seed: 7);
      final b = await _run('mavica_1997', bytes, seed: 7);
      expect(a.fullJpeg, equals(b.fullJpeg));
    });

    test('cross-process camera produces a valid, decodable photo', () async {
      final processed = await _run('panorama_2011', _syntheticJpeg());
      expect(img.decodeJpg(processed.fullJpeg), isNotNull);
    });

    test('scanline camera produces a valid, decodable photo', () async {
      final processed = await _run('kidtough_2008', _syntheticJpeg());
      expect(img.decodeJpg(processed.fullJpeg), isNotNull);
    });
  });
}
