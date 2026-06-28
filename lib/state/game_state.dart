import 'package:flutter/widgets.dart';

import '../core/audio_service.dart';
import '../game/levels.dart';

/// App-wide progress + settings for Bubble Pop. Kept package-free (plain
/// [ChangeNotifier] + [InheritedNotifier]); wire to shared_preferences later.
class GameState extends ChangeNotifier {
  /// Highest unlocked level index (0-based).
  int unlocked = 0;

  /// Best stars earned per level index (0..3).
  final List<int> progress = List<int>.filled(kLevels.length, 0);

  bool soundOn = true;

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
    notifyListeners();
  }

  void toggleSound() {
    soundOn = !soundOn;
    AudioService.instance.setEnabled(soundOn);
    notifyListeners();
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
