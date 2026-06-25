/// Persistent player state: currency, unlocked levels, stars and settings.
///
/// For the UI phase this is held in memory by [GameState]; wiring it to Hive /
/// shared_preferences happens in the storage phase.
class PlayerProgress {
  int coins;
  int currentLevel;

  /// levelId -> stars earned (0..3).
  final Map<int, int> levelStars;

  int hints;
  int undos;

  bool soundOn;
  bool musicOn;
  bool vibrationOn;

  /// Index into the available arrow skins / board themes (cosmetic).
  int arrowSkin;
  int boardTheme;

  /// Daily-challenge login streak in days.
  int streak;

  PlayerProgress({
    this.coins = 120,
    this.currentLevel = 1,
    Map<int, int>? levelStars,
    this.hints = 3,
    this.undos = 3,
    this.soundOn = true,
    this.musicOn = true,
    this.vibrationOn = true,
    this.arrowSkin = 0,
    this.boardTheme = 0,
    this.streak = 1,
  }) : levelStars = levelStars ?? {};

  int starsFor(int levelId) => levelStars[levelId] ?? 0;

  bool isCompleted(int levelId) => starsFor(levelId) > 0;

  /// A level is unlocked if it's the first, or the previous level is done.
  bool isUnlocked(int levelId) => levelId <= 1 || isCompleted(levelId - 1);

  int get totalStars => levelStars.values.fold(0, (sum, stars) => sum + stars);
}
