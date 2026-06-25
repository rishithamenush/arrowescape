import 'dart:math';

import '../models/arrow.dart';
import '../models/level.dart';

/// Provides the level catalogue.
///
/// For the UI phase levels are generated deterministically in code so the game
/// is fully playable without bundling JSON assets yet. Swapping this for a
/// `rootBundle.loadString('assets/levels/..')` loader later keeps the same API.
class LevelLoader {
  LevelLoader._();

  static const int worldSize = 30;
  static const int worldCount = 4;
  static int get totalLevels => worldSize * worldCount;

  static final Map<int, LevelModel> _cache = {};

  static LevelModel byId(int id) => _cache.putIfAbsent(id, () => _generate(id));

  /// Builds a puzzle that is **guaranteed solvable**, scaling size and density
  /// with the id.
  ///
  /// Reverse construction: arrows are added one at a time, and each new arrow
  /// is only placed if its escape path is clear of the arrows already on the
  /// board. Because removing an arrow can never block another (it only frees
  /// cells), the reverse of the placement order is always a valid solution —
  /// and the player can never reach a dead end.
  static LevelModel _generate(int id) {
    final rng = Random(id * 9973 + 7);
    final grid = _gridSizeFor(id);
    final density = (0.32 + (id % worldSize) * 0.006).clamp(0.30, 0.55);
    final cellCount = grid * grid;
    final target = max(2, (cellCount * density).round());
    final colored = id > worldSize; // introduce colors after world 1

    final occupied = <int>{};
    final arrows = <ArrowModel>[];

    var attempts = 0;
    final maxAttempts = cellCount * 60;
    while (arrows.length < target && attempts < maxAttempts) {
      attempts++;
      final r = rng.nextInt(grid);
      final c = rng.nextInt(grid);
      if (occupied.contains(r * grid + c)) continue;

      // Try directions in a random order; keep the first whose path to the
      // edge is clear of every already-placed arrow.
      final dirs = List<ArrowDir>.of(ArrowDir.values)..shuffle(rng);
      ArrowDir? chosen;
      for (final d in dirs) {
        if (_pathClear(occupied, grid, r, c, d)) {
          chosen = d;
          break;
        }
      }
      if (chosen == null) continue;

      final color = colored && rng.nextDouble() < 0.35 ? 1 + rng.nextInt(3) : 0;
      arrows.add(
        ArrowModel(
          id: 'a${arrows.length}',
          row: r,
          col: c,
          dir: chosen,
          color: color,
        ),
      );
      occupied.add(r * grid + c);
    }

    return LevelModel(
      id: id,
      rows: grid,
      cols: grid,
      arrows: arrows,
      // A clean solve takes exactly `arrows.length` moves; allow a small margin
      // for the 2-star target.
      targetMoves: arrows.length + (arrows.length ~/ 4) + 1,
    );
  }

  /// True if the straight line from ([r],[c]) towards [dir] reaches the edge
  /// without passing through an [occupied] cell.
  static bool _pathClear(
    Set<int> occupied,
    int grid,
    int r,
    int c,
    ArrowDir dir,
  ) {
    final step = dir.vector;
    var rr = r + step.row;
    var cc = c + step.col;
    while (rr >= 0 && rr < grid && cc >= 0 && cc < grid) {
      if (occupied.contains(rr * grid + cc)) return false;
      rr += step.row;
      cc += step.col;
    }
    return true;
  }

  /// Verifies a level can be fully cleared, by greedily removing every
  /// escapable arrow until nothing changes. Used by tests as a safety net.
  static bool isSolvable(LevelModel level) {
    final remaining = level.freshArrows();

    bool pathClear(ArrowModel a) {
      final step = a.dir.vector;
      var rr = a.row + step.row;
      var cc = a.col + step.col;
      while (rr >= 0 && rr < level.rows && cc >= 0 && cc < level.cols) {
        if (remaining.any((o) => o.row == rr && o.col == cc)) return false;
        rr += step.row;
        cc += step.col;
      }
      return true;
    }

    while (remaining.isNotEmpty) {
      final escapable = remaining.where(pathClear).toList();
      if (escapable.isEmpty) return false; // deadlocked
      remaining.removeWhere((a) => escapable.contains(a));
    }
    return true;
  }

  static int _gridSizeFor(int id) {
    final world = (id - 1) ~/ worldSize; // 0-based world
    return (5 + world).clamp(5, 9);
  }

  /// Today's daily challenge, seeded by the date so everyone gets the same one.
  static LevelModel dailyChallenge(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final cached = _cache[-seed];
    if (cached != null) return cached;
    final level = _generate(seed % 200 + 5);
    final daily = LevelModel(
      id: -1,
      rows: level.rows,
      cols: level.cols,
      arrows: level.arrows,
      targetMoves: level.targetMoves,
    );
    _cache[-seed] = daily;
    return daily;
  }
}
