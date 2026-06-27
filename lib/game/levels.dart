/// Per-level configuration (ported from the Bubble Pop prototype).
class LevelConfig {
  const LevelConfig({
    required this.rows,
    required this.colors,
    required this.shots,
  });

  /// Number of pre-filled rows at the top of the board.
  final int rows;

  /// How many colours from the palette this level uses.
  final int colors;

  /// Starting moves (before the difficulty multiplier).
  final int shots;
}

const List<LevelConfig> kLevels = [
  LevelConfig(rows: 4, colors: 4, shots: 18),
  LevelConfig(rows: 5, colors: 4, shots: 18),
  LevelConfig(rows: 6, colors: 5, shots: 17),
  LevelConfig(rows: 7, colors: 6, shots: 16),
];
