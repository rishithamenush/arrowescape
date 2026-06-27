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

/// Total number of playable levels.
const int kLevelCount = 1005; // 67 sections × 15

/// The full level progression (1000+ levels). Difficulty ramps up across the
/// early levels — more pre-filled rows, more colours, fewer moves — then
/// plateaus at a hard tier with light variation per level.
final List<LevelConfig> kLevels = List<LevelConfig>.generate(kLevelCount, (i) {
  final rows = (4 + i ~/ 8).clamp(4, 10);
  final colors = (4 + i ~/ 20).clamp(4, 6);
  // Slight saw-tooth so consecutive levels feel a little different.
  final shots = (20 - i ~/ 10 - (i % 3)).clamp(9, 20);
  return LevelConfig(rows: rows, colors: colors, shots: shots);
});
