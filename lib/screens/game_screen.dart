import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/arrow_escape_game.dart';
import '../logic/board_controller.dart';
import '../logic/level_loader.dart';
import '../models/player_progress.dart';
import '../state/game_state.dart';
import '../widgets/app_background.dart';
import '../widgets/hud.dart';
import '../widgets/result_dialog.dart';

/// The main gameplay screen: HUD + Flame board + action bar, with win / stuck
/// overlays. Pass [levelId] == -1 with [daily] for the daily challenge.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelId, this.daily = false});

  final int levelId;
  final bool daily;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late BoardController _board;
  late ArrowEscapeGame _game;

  /// The level currently being played. Tracked in state (not `widget.levelId`)
  /// so "Next" advances correctly instead of reloading the same level.
  late int _currentLevelId;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.levelId);
  }

  void _loadLevel(int id) {
    _currentLevelId = id;
    final level = widget.daily
        ? LevelLoader.dailyChallenge(DateTime.now())
        : LevelLoader.byId(id);
    _board = BoardController(level);
    _resultShown = false;
    _game = ArrowEscapeGame(
      controller: _board,
      onChanged: () {
        if (mounted) setState(() {});
      },
      onResolved: _onResolved,
    );
  }

  /// Fired by the Flame game once an escape animation completes and the board
  /// has either been cleared (won) or deadlocked (stuck).
  void _onResolved(BoardStatus status) {
    if (_resultShown) return;
    if (status == BoardStatus.won) {
      _resultShown = true;
      _finishLevel();
    } else if (status == BoardStatus.stuck) {
      _resultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showStuck());
    }
    if (mounted) setState(() {});
  }

  void _finishLevel() {
    final stars = _board.starsEarned;
    final state = GameScope.read(context);
    if (!widget.daily) {
      state.recordResult(levelId: _currentLevelId, stars: stars);
    } else {
      state.addCoins(50);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWin(stars));
  }

  Future<void> _showWin(int stars) async {
    final coins = widget.daily ? 50 : 20 + stars * 10;
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.overlay,
      barrierLabel: 'win',
      pageBuilder: (_, __, ___) => WinDialog(
        stars: stars,
        coins: coins,
        onNext: () {
          Navigator.of(context).pop();
          // The daily challenge has no "next"; return to the previous screen.
          if (widget.daily) {
            Navigator.of(context).pop();
          } else {
            _goToLevel(_currentLevelId + 1);
          }
        },
        onReplay: () {
          Navigator.of(context).pop();
          _restart();
        },
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _showStuck() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.overlay,
      barrierLabel: 'stuck',
      pageBuilder: (_, __, ___) => StuckDialog(
        canUndo: _board.canUndo,
        onUndo: () {
          Navigator.of(context).pop();
          _doUndo();
        },
        onRestart: () {
          Navigator.of(context).pop();
          _restart();
        },
        onHint: () {
          Navigator.of(context).pop();
          _resultShown = false;
        },
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _goToLevel(int id) {
    setState(() => _loadLevel(id));
  }

  void _restart() {
    setState(() {
      _board.restart();
      _resultShown = false;
      _game.syncFromController();
    });
  }

  /// Restores the previous board state and re-syncs the Flame components.
  void _doUndo() {
    setState(() {
      _board.undo();
      _resultShown = false;
      _game.syncFromController();
    });
  }

  void _undo() {
    if (!_board.canUndo) return;
    final state = GameScope.read(context);
    if (state.useUndo()) {
      _doUndo();
    } else {
      _snack('No undos left — get more in the Shop');
    }
  }

  void _hint() {
    final state = GameScope.read(context);
    final solvable = _board.firstSolvable();
    if (solvable == null) {
      _snack('No clear path — try Undo or Restart');
      return;
    }
    if (state.useHint()) {
      _board.markHintUsed();
      _game.highlight(solvable.id);
    } else {
      _snack('No hints left — get more in the Shop');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    final p = state.progress;

    return Scaffold(
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _topBar(p.coins),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GameWidget(game: _game),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _actionBar(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(int coins) {
    final title = widget.daily ? 'Daily Challenge' : 'Level $_currentLevelId';
    return Row(
      children: [
        RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Moves ${_board.moves}  •  Target ${_board.level.targetMoves}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatPill(
          icon: Icons.monetization_on_rounded,
          label: '$coins',
          color: AppColors.coin,
        ),
      ],
    );
  }

  Widget _actionBar(PlayerProgress p) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: BoardActionButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              count: p.undos,
              enabled: _board.canUndo,
              onTap: _undo,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: BoardActionButton(
              icon: Icons.lightbulb_rounded,
              label: 'Hint',
              count: p.hints,
              onTap: _hint,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: BoardActionButton(
              icon: Icons.refresh_rounded,
              label: 'Restart',
              onTap: _restart,
            ),
          ),
        ),
      ],
    );
  }
}
