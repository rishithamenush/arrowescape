import 'package:flutter/widgets.dart';

import '../models/player_progress.dart';

/// App-wide player state. Kept package-free (plain [ChangeNotifier] +
/// [InheritedNotifier]) so the UI layer builds without extra dependencies;
/// can be replaced with Riverpod later without touching screen code.
class GameState extends ChangeNotifier {
  GameState({PlayerProgress? progress})
    : progress = progress ?? PlayerProgress();

  final PlayerProgress progress;

  void recordResult({required int levelId, required int stars}) {
    final previous = progress.starsFor(levelId);
    if (stars > previous) {
      progress.levelStars[levelId] = stars;
    }
    // Reward coins for first-time and improved completions.
    if (stars > previous) {
      progress.coins += 20 + stars * 10;
    }
    if (levelId == progress.currentLevel && levelId > 0) {
      progress.currentLevel = levelId + 1;
    }
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (progress.coins < amount) return false;
    progress.coins -= amount;
    notifyListeners();
    return true;
  }

  void addCoins(int amount) {
    progress.coins += amount;
    notifyListeners();
  }

  void addHints(int amount) {
    progress.hints += amount;
    notifyListeners();
  }

  void addUndos(int amount) {
    progress.undos += amount;
    notifyListeners();
  }

  bool useHint() {
    if (progress.hints <= 0) return false;
    progress.hints--;
    notifyListeners();
    return true;
  }

  bool useUndo() {
    if (progress.undos <= 0) return false;
    progress.undos--;
    notifyListeners();
    return true;
  }

  void setArrowSkin(int index) {
    progress.arrowSkin = index;
    notifyListeners();
  }

  void setBoardTheme(int index) {
    progress.boardTheme = index;
    notifyListeners();
  }

  void toggleSound() {
    progress.soundOn = !progress.soundOn;
    notifyListeners();
  }

  void toggleMusic() {
    progress.musicOn = !progress.musicOn;
    notifyListeners();
  }

  void toggleVibration() {
    progress.vibrationOn = !progress.vibrationOn;
    notifyListeners();
  }
}

/// Inherited access to [GameState] from anywhere in the widget tree.
class GameScope extends InheritedNotifier<GameState> {
  const GameScope({super.key, required GameState state, required super.child})
    : super(notifier: state);

  static GameState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'GameScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Read without subscribing to rebuilds (for callbacks).
  static GameState read(BuildContext context) {
    final scope =
        context.getElementForInheritedWidgetOfExactType<GameScope>()?.widget
            as GameScope?;
    return scope!.notifier!;
  }
}
