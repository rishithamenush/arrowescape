// Engine + smoke tests for Bubble Pop.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrowescape/main.dart';
import 'package:arrowescape/game/bubble_engine.dart';
import 'package:arrowescape/screens/game_screen.dart';
import 'package:arrowescape/state/game_state.dart';

/// Boots an engine at a fixed board size for deterministic geometry tests.
BubbleEngine _engine() {
  final e = BubbleEngine(aimGuide: false);
  e.setSize(360, 640);
  return e;
}

void main() {
  testWidgets('App boots to the Bubble Pop home screen', (tester) async {
    await tester.pumpWidget(const BubblePopApp());
    await tester.pump();
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Bubble\nPop'), findsOneWidget);
  });

  testWidgets('GameScreen mounts without a setState-during-build error', (
    tester,
  ) async {
    await tester.pumpWidget(
      GameScope(
        state: GameState(),
        child: const MaterialApp(home: GameScreen(level: 0)),
      ),
    );
    // The engine boots inside Flame's onLoad (during layout) and fires onSync;
    // pumping a few frames would throw here if rebuilds weren't deferred.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
    expect(find.text('MOVES'), findsOneWidget);
  });

  group('Hex geometry', () {
    test('even rows have 9 cells, odd rows 8 (staggered)', () {
      final e = _engine();
      expect(e.rowLen(0), 9);
      expect(e.rowLen(1), 8);
      expect(e.rowLen(2), 9);
    });

    test('neighbors are filtered to valid in-grid cells', () {
      final e = _engine();
      e.boot(0);
      // A middle cell has all 6 neighbors.
      expect(e.neighbors(2, 4).length, 6);
      // A top-left corner has fewer.
      expect(e.neighbors(0, 0).length, lessThan(6));
    });
  });

  group('Matching & clearing', () {
    test('aim never points downward', () {
      final e = _engine();
      e.boot(0);
      e.aim = Offset(e.sx, e.sy + 200); // below the launcher
      final d = e.aimDir();
      expect(d.dy, lessThan(0)); // forced upward
    });

    test('boot fills row 0 completely and respects maxRow', () {
      final e = _engine();
      e.boot(0);
      expect(e.grid[0].every((v) => v != null), isTrue);
      expect(e.grid.length, e.maxRow + 1);
      expect(e.filledCount(), greaterThan(0));
    });

    test('a fresh level is running and not finished', () {
      final e = _engine();
      e.boot(0);
      expect(e.running, isTrue);
      expect(e.finished, isFalse);
      expect(e.shots, greaterThan(0));
    });

    test('clearing the last colour wins the level', () {
      final e = _engine();
      var wonStars = -1;
      e.onWin = (s) => wonStars = s;
      e.boot(0);
      // Wipe the board and leave a small cluster of colour 0 directly above
      // the launcher (column 4 aligns with sx for a 9-wide board).
      for (final row in e.grid) {
        for (var c = 0; c < row.length; c++) {
          row[c] = null;
        }
      }
      e.grid[0][4] = 0;
      e.grid[1][3] = 0;
      e.grid[1][4] = 0;
      // Fire the colour-clear power-up straight up — it removes every colour-0
      // bubble, emptying the board.
      e.active = 'clear';
      e.onShoot(Offset(e.sx, e.top));
      var guard = 0;
      while (!e.finished && guard++ < 600) {
        e.update(0.016);
      }
      expect(e.finished, isTrue);
      expect(e.filledCount(), 0);
      expect(wonStars, inInclusiveRange(1, 3));
    });

    test('running out of moves loses the level', () {
      final e = _engine();
      var lostReason = '';
      e.onLose = (r) => lostReason = r;
      e.boot(0);
      // Leave a single bubble far from where shots land so matches never clear
      // the board, then exhaust the moves.
      for (final row in e.grid) {
        for (var c = 0; c < row.length; c++) {
          row[c] = null;
        }
      }
      e.grid[0][0] = 0;
      e.shots = 1;
      e.cur = 1; // a colour that won't match the lone bubble
      e.onShoot(Offset(e.sx, e.top));
      var guard = 0;
      while (!e.finished && guard++ < 600) {
        e.update(0.016);
      }
      expect(e.finished, isTrue);
      expect(lostReason, 'moves');
    });
  });
}
