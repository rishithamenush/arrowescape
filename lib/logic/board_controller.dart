import 'package:flutter/foundation.dart';

import '../models/arrow.dart';
import '../models/level.dart';

enum BoardStatus { playing, won, stuck, lost }

/// Holds the live board state for one level and implements the core rules:
/// `canEscape`, `tapArrow`, win/stuck detection, lives and `undo`.
class BoardController extends ChangeNotifier {
  BoardController(this.level, {this.maxLives = 5}) {
    _reset();
  }

  final LevelModel level;

  /// Number of wrong taps allowed before the level is lost.
  final int maxLives;

  late List<ArrowModel> arrows;
  int moves = 0;
  late int lives;
  bool hintUsed = false;
  bool undoUsed = false;
  BoardStatus status = BoardStatus.playing;

  /// True for one notify cycle right after a heart was just lost (for the UI
  /// to play a "damage" reaction).
  bool justLostLife = false;

  /// Id of the arrow currently animating off the board (for the view layer).
  String? escapingId;

  /// Id of the arrow currently shaking because it was blocked.
  String? blockedId;

  /// Snapshots of arrow positions for undo (most recent last).
  final List<List<ArrowModel>> _history = [];

  void _reset() {
    arrows = level.freshArrows();
    moves = 0;
    lives = maxLives;
    justLostLife = false;
    hintUsed = false;
    undoUsed = false;
    status = BoardStatus.playing;
    escapingId = null;
    blockedId = null;
    _history.clear();
  }

  ArrowModel? arrowAt(int row, int col) {
    for (final a in arrows) {
      if (a.row == row && a.col == col) return a;
    }
    return null;
  }

  bool _inside(int row, int col) =>
      row >= 0 && row < level.rows && col >= 0 && col < level.cols;

  /// Core rule: is the path from this arrow to the board edge fully clear?
  bool canEscape(ArrowModel arrow) {
    final step = arrow.dir.vector;
    var r = arrow.row + step.row;
    var c = arrow.col + step.col;
    while (_inside(r, c)) {
      if (arrowAt(r, c) != null) return false;
      r += step.row;
      c += step.col;
    }
    return true;
  }

  /// Player tapped an arrow. Either it escapes (and we re-check win/stuck) or
  /// it shakes. Returns true if the arrow escaped.
  bool tapArrow(ArrowModel arrow) {
    if (status != BoardStatus.playing) return false;

    justLostLife = false;
    if (canEscape(arrow)) {
      _pushHistory();
      escapingId = arrow.id;
      blockedId = null;
      arrows.removeWhere((a) => a.id == arrow.id);
      moves++;
      _evaluate();
      notifyListeners();
      return true;
    } else {
      // Wrong tap: shake and lose a heart.
      blockedId = arrow.id;
      lives = (lives - 1).clamp(0, maxLives);
      justLostLife = true;
      if (lives <= 0) status = BoardStatus.lost;
      notifyListeners();
      return false;
    }
  }

  /// Clears the transient escaping marker once the view finished animating.
  void clearEscaping() {
    escapingId = null;
  }

  void clearBlocked() {
    blockedId = null;
  }

  void _pushHistory() {
    _history.add(arrows.map((a) => a.copyWith()).toList());
  }

  void undo() {
    if (_history.isEmpty ||
        status == BoardStatus.won ||
        status == BoardStatus.lost) {
      return;
    }
    arrows = _history.removeLast();
    moves = (moves - 1).clamp(0, 1 << 30);
    undoUsed = true;
    status = BoardStatus.playing;
    escapingId = null;
    blockedId = null;
    notifyListeners();
  }

  void restart() {
    _reset();
    notifyListeners();
  }

  /// Returns an arrow that currently has a clear path, or null if none — used
  /// by the hint button and for stuck detection.
  ArrowModel? firstSolvable() {
    for (final a in arrows) {
      if (canEscape(a)) return a;
    }
    return null;
  }

  void markHintUsed() => hintUsed = true;

  void _evaluate() {
    if (arrows.isEmpty) {
      status = BoardStatus.won;
    } else if (firstSolvable() == null) {
      status = BoardStatus.stuck;
    } else {
      status = BoardStatus.playing;
    }
  }

  /// Stars: 1 for finishing, +1 for under target moves, +1 for no hint/undo.
  int get starsEarned {
    if (status != BoardStatus.won) return 0;
    var stars = 1;
    if (moves <= level.targetMoves) stars++;
    if (!hintUsed && !undoUsed) stars++;
    return stars;
  }

  bool get canUndo =>
      _history.isNotEmpty &&
      status != BoardStatus.won &&
      status != BoardStatus.lost;
}
