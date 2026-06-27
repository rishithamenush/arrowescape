import 'package:flame_audio/flame_audio.dart';

/// Plays short sound effects for the game, gated on the user's sound setting.
///
/// Audio files are expected under `assets/audio/` (declared in pubspec). Calls
/// are wrapped so a missing file never crashes the game — drop the real `.mp3`
/// files in later and they start playing automatically.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool enabled = true;

  /// Maps logical SFX names to asset filenames.
  static const Map<String, String> _files = {
    'shoot': 'shoot.mp3',
    'snap': 'snap.mp3',
    'pop': 'pop.mp3',
    'combo': 'combo.mp3',
    'bomb': 'bomb.mp3',
    'win': 'win.mp3',
    'lose': 'lose.mp3',
    'tap': 'tap.mp3',
  };

  /// Best-effort preload; silently ignores files that aren't present yet.
  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll(_files.values.toList());
    } catch (_) {
      // Assets not bundled yet — fine, plays become no-ops.
    }
  }

  void play(String name) {
    if (!enabled) return;
    final file = _files[name];
    if (file == null) return;
    _safePlay(file);
  }

  // Fire-and-forget; swallow errors for assets that aren't bundled yet.
  Future<void> _safePlay(String file) async {
    try {
      await FlameAudio.play(file);
    } catch (_) {}
  }
}
