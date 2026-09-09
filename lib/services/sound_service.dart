import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the app's hardware sound language: the shutter, plus the small set
/// of firmware-style cues (boot chime, focus beep, click, error) added for
/// the FIELD UNIT 04 identity. Failures (e.g. no audio device on a desktop
/// dev box, or the asset missing) are swallowed — sound is a nice touch,
/// never a reason to break capture.
class SoundService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playShutter(String assetPath) => _play(assetPath);

  Future<void> playBootChime([String? asset]) => _play(asset ?? 'sounds/boot_chime.wav');

  Future<void> playFocusBeep() => _play('sounds/focus_beep.wav');

  Future<void> playClick() => _play('sounds/click.wav');

  Future<void> playError() => _play('sounds/error_beep.wav');

  Future<void> _play(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('SoundService: could not play $assetPath: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
