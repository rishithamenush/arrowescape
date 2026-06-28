import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/audio_service.dart';
import '../game/levels.dart';


/// App-wide progress + settings for Bubble Pop. Progress is persisted to
/// [SharedPreferences] so completed levels and earned stars survive restarts.
class GameState extends ChangeNotifier {
  static const _kUnlockedKey = 'bp_unlocked';
  static const _kProgressKey = 'bp_progress';
  static const _kSoundKey = 'bp_sound_on';

  /// Highest unlocked level index (0-based).
  int unlocked = 0;

  /// Best stars earned per level index (0..3).
  final List<int> progress = List<int>.filled(kLevels.length, 0);

  bool soundOn = true;

  SharedPreferences? _prefs;

  /// Loads persisted progress + settings. Call once before using the state.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    unlocked = (prefs.getInt(_kUnlockedKey) ?? 0).clamp(0, kLevels.length - 1);

    final saved = prefs.getStringList(_kProgressKey);
    if (saved != null) {
      for (var i = 0; i < progress.length && i < saved.length; i++) {
        progress[i] = (int.tryParse(saved[i]) ?? 0).clamp(0, 3);
      }
    }

    soundOn = prefs.getBool(_kSoundKey) ?? true;
    AudioService.instance.setEnabled(soundOn);

    notifyListeners();
  }

  bool isUnlocked(int i) => i <= unlocked;
  int starsFor(int i) => i >= 0 && i < progress.length ? progress[i] : 0;

  void recordWin({required int level, required int stars}) {
    if (level >= 0 && level < progress.length) {
      progress[level] = stars > progress[level] ? stars : progress[level];
    }
    final nextLevel = level + 1;
    if (nextLevel < kLevels.length && nextLevel > unlocked) {
      unlocked = nextLevel;
    }
    _persistProgress();
    notifyListeners();
  }

  void toggleSound() {
    soundOn = !soundOn;
    AudioService.instance.setEnabled(soundOn);
    _prefs?.setBool(_kSoundKey, soundOn);
    notifyListeners();
  }

  void _persistProgress() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setInt(_kUnlockedKey, unlocked);
    prefs.setStringList(
      _kProgressKey,
      progress.map((s) => s.toString()).toList(),
    );
  }
}

class GameScope extends InheritedNotifier<GameState> {
  const GameScope({super.key, required GameState state, required super.child})
    : super(notifier: state);

  static GameState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'GameScope not found');
    return scope!.notifier!;
  }

  static GameState read(BuildContext context) {
    final scope =
        context.getElementForInheritedWidgetOfExactType<GameScope>()?.widget
            as GameScope?;
    return scope!.notifier!;
  }
}
