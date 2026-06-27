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

/// The full level progression. Difficulty ramps up: more pre-filled rows, more
/// colours and gradually fewer moves. Plenty of stops for the road map.
final List<LevelConfig> kLevels = List<LevelConfig>.generate(15, (i) {
  final rows = (4 + i ~/ 2).clamp(4, 10);
  final colors = (4 + i ~/ 4).clamp(4, 6);
  final shots = (18 - i ~/ 3).clamp(10, 18);
  return LevelConfig(rows: rows, colors: colors, shots: shots);
});
