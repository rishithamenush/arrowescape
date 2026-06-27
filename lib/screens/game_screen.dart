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
    } else if (status == BoardStatus.lost) {
      _resultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOver());
    }
    if (mounted) setState(() {});
  }

  Future<void> _showGameOver() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.overlay,
      barrierLabel: 'gameover',
      pageBuilder: (_, __, ___) => GameOverDialog(
        onRetry: () {
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
              _topBar(),
              const SizedBox(height: AppSpacing.md),
              _statsRow(),
              const SizedBox(height: AppSpacing.md),
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

  Widget _topBar() {
    final title = widget.daily ? 'Daily Challenge' : 'Level $_currentLevelId';
    return Row(
      children: [
        RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            height: 46,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFEFF1FF)],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        HeartsBar(lives: _board.lives, maxLives: _board.maxLives),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.touch_app_rounded,
            label: 'MOVES',
            value: '${_board.moves}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatChip(
            icon: Icons.flag_rounded,
            label: 'TARGET',
            value: '${_board.level.targetMoves}',
            color: AppColors.success,
          ),
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
              color: AppColors.primary,
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
              color: AppColors.warning,
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
              color: AppColors.danger,
              onTap: _restart,
            ),
          ),
        ),
      ],
    );
  }
}

/// A big, clearly-labelled stat chip (e.g. MOVES / TARGET) so younger players
/// can read the goal at a glance.
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFEFF1FF)],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.26),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colourful glossy icon disc.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(color, Colors.white, 0.30)!, color],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
