import 'package:flame_audio/flame_audio.dart';

/// Central audio: preloaded low-latency sound effects with per-sound volumes,
/// plus looping background music. Sound effects and background music are
/// toggled independently via [setSfxEnabled] / [setMusicEnabled].
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;

  bool _ready = false;

  /// Logical name -> asset filename (under `assets/audio/`).
  static const Map<String, String> _sfx = {
    'shoot': 'shoot.mp3',
    'snap': 'snap.mp3',
    'pop': 'pop.mp3',
    'combo': 'combo.mp3',
    'bomb': 'bomb.mp3',
    'win': 'win.mp3',
    'lose': 'lose.mp3',
    'tap': 'tap.mp3',
    'star': 'star.mp3',
  };

  static const String _music = 'music_loop.mp3';

  /// Per-sound playback volume (0..1).
  static const Map<String, double> _volume = {
    'shoot': 0.45,
    'snap': 0.45,
    'pop': 0.7,
    'combo': 0.85,
    'bomb': 0.9,
    'win': 0.95,
    'lose': 0.8,
    'tap': 0.5,
    'star': 0.85,
  };

  static const double _musicVolume = 0.32;

  /// Preloads every clip into the cache (so the first play has no lag) and
  /// starts the background music. Safe to call once at startup.
  Future<void> init() async {
    try {
      FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll([..._sfx.values, _music]);
      _ready = true;
      await startMusic();
    } catch (_) {
      // Missing/corrupt assets must never crash the game.
    }
  }

  /// Plays a one-shot sound effect by logical [name].
  void play(String name) {
    if (!_sfxEnabled || !_ready) return;
    final file = _sfx[name];
    if (file == null) return;
    _safePlay(file, _volume[name] ?? 0.7);
  }

  Future<void> _safePlay(String file, double volume) async {
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (_) {}
  }

  // ---------- background music ----------
  Future<void> startMusic() async {
    if (!_musicEnabled || !_ready) return;
    if (FlameAudio.bgm.isPlaying) return;
    try {
      await FlameAudio.bgm.play(_music, volume: _musicVolume);
    } catch (_) {}
  }

  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }

  // ---------- independent toggles ----------
  /// Enables/disables one-shot sound effects (pops, shots, win chimes…).
  void setSfxEnabled(bool on) {
    _sfxEnabled = on;
  }

  /// Enables/disables the looping background music.
  void setMusicEnabled(bool on) {
    _musicEnabled = on;
    if (on) {
      startMusic();
    } else {
      try {
        FlameAudio.bgm.pause();
      } catch (_) {}
    }
  }
}
