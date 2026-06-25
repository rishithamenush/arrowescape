// Smoke + logic + responsiveness tests for Arrow Escape.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrowescape/main.dart';
import 'package:arrowescape/core/theme.dart';
import 'package:arrowescape/logic/board_controller.dart';
import 'package:arrowescape/logic/level_loader.dart';
import 'package:arrowescape/models/arrow.dart';
import 'package:arrowescape/models/level.dart';
import 'package:arrowescape/state/game_state.dart';
import 'package:arrowescape/screens/home_screen.dart';
import 'package:arrowescape/screens/level_select_screen.dart';
import 'package:arrowescape/screens/settings_screen.dart';
import 'package:arrowescape/screens/shop_screen.dart';
import 'package:arrowescape/screens/daily_challenge_screen.dart';

/// Hosts a screen inside the app's providers at a given text scale.
Widget _host(Widget screen, {double textScale = 1.0}) {
  return GameScope(
    state: GameState(),
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: screen,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('App boots to the splash screen then navigates home', (
    tester,
  ) async {
    await tester.pumpWidget(const ArrowEscapeApp());
    expect(find.text('ARROW ESCAPE'), findsOneWidget);
    // Fire the splash auto-navigate timer and settle the route transition.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('PLAY'), findsOneWidget);
  });

  group('Responsiveness (no overflow on a small screen)', () {
    // Tiny phone viewport (e.g. iPhone SE width).
    const small = Size(320, 568);

    final screens = <String, Widget>{
      'Home': const HomeScreen(),
      'LevelSelect': const LevelSelectScreen(),
      'Settings': const SettingsScreen(),
      'Shop': const ShopScreen(),
      'DailyChallenge': const DailyChallengeScreen(),
    };

    for (final entry in screens.entries) {
      testWidgets('${entry.key} fits at 320x568 with large fonts', (
        tester,
      ) async {
        tester.view.physicalSize = small;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_host(entry.value, textScale: 1.3));
        await tester.pumpAndSettle();

        // Any RenderFlex overflow / layout assertion surfaces here.
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('BoardController', () {
    test('arrow with a clear path to the edge escapes', () {
      final level = LevelModel(
        id: 1,
        rows: 3,
        cols: 3,
        targetMoves: 5,
        arrows: [ArrowModel(id: 'a', row: 1, col: 1, dir: ArrowDir.up)],
      );
      final board = BoardController(level);
      expect(board.canEscape(board.arrows.first), isTrue);
    });

    test('arrow blocked by another in its path cannot escape', () {
      final level = LevelModel(
        id: 2,
        rows: 3,
        cols: 3,
        targetMoves: 5,
        arrows: [
          ArrowModel(id: 'a', row: 2, col: 1, dir: ArrowDir.up),
          ArrowModel(id: 'b', row: 0, col: 1, dir: ArrowDir.down),
        ],
      );
      final board = BoardController(level);
      expect(board.canEscape(board.arrowAt(2, 1)!), isFalse);
    });

    test('clearing the blocker lets the arrow escape and win', () {
      final level = LevelModel(
        id: 3,
        rows: 3,
        cols: 1,
        targetMoves: 5,
        arrows: [
          ArrowModel(id: 'top', row: 0, col: 0, dir: ArrowDir.up),
          ArrowModel(id: 'bottom', row: 1, col: 0, dir: ArrowDir.up),
        ],
      );
      final board = BoardController(level);
      // bottom is blocked by top
      expect(board.tapArrow(board.arrowAt(1, 0)!), isFalse);
      // remove top first
      expect(board.tapArrow(board.arrowAt(0, 0)!), isTrue);
      // now bottom can escape and the board is cleared
      expect(board.tapArrow(board.arrowAt(1, 0)!), isTrue);
      expect(board.status, BoardStatus.won);
    });

    test('undo restores the previous state (non-winning move)', () {
      final level = LevelModel(
        id: 4,
        rows: 3,
        cols: 3,
        targetMoves: 5,
        arrows: [
          ArrowModel(id: 'a', row: 1, col: 1, dir: ArrowDir.right),
          ArrowModel(id: 'b', row: 2, col: 2, dir: ArrowDir.down),
        ],
      );
      final board = BoardController(level);
      expect(board.tapArrow(board.arrowAt(1, 1)!), isTrue);
      expect(board.arrows.length, 1); // not yet won
      board.undo();
      expect(board.arrows.length, 2);
      expect(board.moves, 0);
    });
  });

  group('Level generation', () {
    test('every generated level is non-empty and solvable', () {
      for (var id = 1; id <= LevelLoader.totalLevels; id++) {
        final level = LevelLoader.byId(id);
        expect(level.arrows, isNotEmpty, reason: 'Level $id has no arrows');
        expect(
          LevelLoader.isSolvable(level),
          isTrue,
          reason: 'Level $id is not solvable',
        );
      }
    });

    test('daily challenges are solvable across a range of dates', () {
      for (var d = 0; d < 90; d++) {
        final date = DateTime(2026, 1, 1).add(Duration(days: d));
        final level = LevelLoader.dailyChallenge(date);
        expect(level.arrows, isNotEmpty);
        expect(
          LevelLoader.isSolvable(level),
          isTrue,
          reason: 'Daily for $date is not solvable',
        );
      }
    });

    test('a fully solvable board can never deadlock mid-play', () {
      // Greedy play in arbitrary order should always clear a solvable level.
      final level = LevelLoader.byId(17);
      final board = BoardController(level);
      var guard = 0;
      while (board.status == BoardStatus.playing && guard++ < 1000) {
        final next = board.firstSolvable();
        expect(next, isNotNull, reason: 'Deadlocked on a solvable level');
        board.tapArrow(next!);
      }
      expect(board.status, BoardStatus.won);
    });
  });
}
