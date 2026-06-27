import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/audio_service.dart';
import '../core/theme.dart';
import '../game/bubble_engine.dart';
import '../game/bubble_pop_game.dart';
import '../game/levels.dart';
import '../state/game_state.dart';
import '../widgets/candy.dart';

enum _Phase { playing, pause, win, lose }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final int level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int _level;
  late BubbleEngine _engine;
  late BubblePopGame _game;
  _Phase _phase = _Phase.playing;
  int _winStars = 0;
  String _loseReason = 'moves';
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _start(widget.level);
  }

  void _start(int level) {
    _level = level;
    _winStars = 0;
    _phase = _Phase.playing;
    _engine = BubbleEngine()
      ..soundOn = GameScope.read(context).soundOn
      ..onSync = _scheduleSync
      ..onSfx = AudioService.instance.play
      ..onWin = _handleWin
      ..onLose = _handleLose;
    _game = BubblePopGame(engine: _engine, levelIndex: level);
  }

  /// The engine fires callbacks from inside the Flame game loop / onLoad, which
  /// run during Flutter's build & layout phase — so rebuilds are deferred to
  /// the end of the frame (and coalesced) to avoid "setState during build".
  void _scheduleSync() {
    if (_syncScheduled || !mounted) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (mounted) setState(() {});
    });
  }

  void _handleWin(int stars) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      GameScope.read(context).recordWin(level: _level, stars: stars);
      setState(() {
        _winStars = stars;
        _phase = _Phase.win;
      });
    });
  }

  void _handleLose(String reason) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _loseReason = reason;
        _phase = _Phase.lose;
      });
    });
  }

  void _pause() {
    if (_phase != _Phase.playing) return;
    _engine.running = false;
    setState(() => _phase = _Phase.pause);
  }

  void _resume() {
    _engine.running = true;
    setState(() => _phase = _Phase.playing);
  }

  void _restart() => setState(() => _start(_level));

  void _nextLevel() {
    if (_level + 1 < kLevels.length) setState(() => _start(_level + 1));
  }

  void _toggleSound() {
    GameScope.read(context).toggleSound();
    _engine.soundOn = GameScope.read(context).soundOn;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    _engine.soundOn = state.soundOn;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _hud(state),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (e) => _engine.onAim(e.localPosition),
                        onPointerMove: (e) => _engine.onAim(e.localPosition),
                        onPointerUp: (e) => _engine.onShoot(e.localPosition),
                        child: GameWidget(game: _game),
                      ),
                    ),
                  ),
                  _bottomBar(),
                ],
              ),
              if (_phase == _Phase.pause) _pauseOverlay(),
              if (_phase == _Phase.win) _winOverlay(),
              if (_phase == _Phase.lose) _loseOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- HUD ----------
  Widget _hud(GameState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          // Score card with a medal badge.
          _softPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.pinkLight, AppColors.pink],
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LEVEL ${_level + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.label,
                      ),
                    ),
                    Text(
                      '${_engine.score}',
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.heading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_engine.combo >= 2) ...[_comboBadge(), const SizedBox(width: 8)],
          _movesChip(),
          const SizedBox(width: 8),
          _circleButton(
            onTap: _toggleSound,
            icon: state.soundOn
                ? Icons.music_note_rounded
                : Icons.music_off_rounded,
          ),
          const SizedBox(width: 8),
          _circleButton(onTap: _pause, icon: Icons.pause_rounded),
        ],
      ),
    );
  }

  Widget _softPill({required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFF3F1FF)],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.heading.withValues(alpha: 0.12),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  /// A vibrant moves chip that turns red/urgent when running low.
  Widget _movesChip() {
    final low = _engine.shots <= 3;
    final colors = low
        ? const [Color(0xFFFF8FA8), Color(0xFFFF3B6B)]
        : const [Color(0xFFFFD27A), Color(0xFFFF9A3D)];
    final shadow = low ? const Color(0xFFD62F76) : const Color(0xFFD77A1E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_engine.shots}',
            style: const TextStyle(
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Text(
            'MOVES',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required VoidCallback onTap,
    required IconData icon,
    Color color = AppColors.accent,
  }) {
    return CandyButton(
      color: Colors.white,
      shadow: AppColors.pillShadow,
      radius: 21,
      depth: 3,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Center(child: Icon(icon, color: color, size: 22)),
      ),
    );
  }

  Widget _comboBadge() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_engine.combo),
      tween: Tween(begin: 0.3, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (_, v, child) =>
          Transform.scale(scale: v.clamp(0, 1.15), child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD23F), Color(0xFFFF9A3D)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD77A1E), offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '×${_engine.combo}',
              style: const TextStyle(
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Text(
              'COMBO',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- bottom bar ----------
  Widget _bottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _PowerButton(
            label: 'Bomb',
            count: _engine.bomb,
            armed: _engine.active == 'bomb',
            icon: _bombIcon(),
            onTap: _engine.selectBomb,
          ),
          const SizedBox(width: 10),
          _PowerButton(
            label: 'Clear',
            count: _engine.clear,
            armed: _engine.active == 'clear',
            icon: _clearIcon(),
            onTap: _engine.selectClear,
          ),
          const Spacer(),
          _circleButton(
            onTap: _engine.swap,
            icon: Icons.swap_horiz_rounded,
            color: AppColors.body,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'NEXT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: AppColors.label,
                ),
              ),
              const SizedBox(height: 3),
              _glossyBubble(BubblePalette.base[_engine.next], 34),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bombIcon() => Container(
    width: 30,
    height: 30,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: Alignment(-0.3, -0.4),
        colors: [Color(0xFF6B6B7A), Color(0xFF25252E)],
        stops: [0, 0.7],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          top: -2,
          right: 4,
          child: Transform.rotate(
            angle: 0.35,
            child: Container(
              width: 6,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCE3D),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _clearIcon() => Container(
    width: 30,
    height: 30,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: SweepGradient(
        colors: [
          Color(0xFFFF4D8D),
          Color(0xFFFFD23F),
          Color(0xFF44D0E6),
          Color(0xFF3DDC84),
          Color(0xFF9B6BFF),
          Color(0xFFFF4D8D),
        ],
      ),
    ),
    child: const Center(
      child: Text('★', style: TextStyle(fontSize: 15, color: Colors.white)),
    ),
  );

  Widget _glossyBubble(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [Colors.white.withValues(alpha: 0.8), color],
        stops: const [0, 0.45],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
  );

  // ---------- overlays ----------
  Widget _scrim({required Widget child}) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x803C2846),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            builder: (_, v, c) =>
                Transform.scale(scale: v.clamp(0, 1.1), child: c),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    width: MediaQuery.sizeOf(context).width * 0.8,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
      ],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );

  Widget _pauseOverlay() => _scrim(
    child: _card(
      children: [
        const Text(
          'Paused',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 14),
        CandyButton(
          gradient: const [AppColors.mintLight, AppColors.mint],
          shadow: AppColors.mintShadow,
          expand: true,
          onTap: _resume,
          child: _btnText('Resume'),
        ),
        const SizedBox(height: 12),
        CandyButton(
          gradient: const [AppColors.pinkLight, AppColors.pink],
          shadow: AppColors.pinkShadow,
          expand: true,
          onTap: _restart,
          child: _btnText('Restart'),
        ),
        const SizedBox(height: 12),
        CandyButton(
          color: AppColors.softPink,
          shadow: AppColors.softPinkShadow,
          expand: true,
          onTap: () => Navigator.of(context).pop(),
          child: _btnText('Levels', color: AppColors.accent),
        ),
      ],
    ),
  );

  Widget _winOverlay() {
    final hasNext = _level + 1 < kLevels.length;
    return _scrim(
      child: _card(
        children: [
          const Text(
            'Level Clear!',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var k = 1; k <= 3; k++)
                Transform.translate(
                  offset: Offset(0, k == 2 ? -8 : 0),
                  child: Transform.scale(
                    scale: k == 2 ? 1.12 : 1,
                    child: Text(
                      '★',
                      style: TextStyle(
                        fontSize: 46,
                        color: k <= _winStars
                            ? const Color(0xFFFFCE3D)
                            : const Color(0xFFE3D6EC),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Score',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          Text(
            '${_engine.score}',
            style: const TextStyle(
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 14),
          if (hasNext) ...[
            CandyButton(
              gradient: const [AppColors.pinkLight, AppColors.pink],
              shadow: AppColors.pinkShadow,
              expand: true,
              onTap: _nextLevel,
              child: _btnText('Next Level'),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: CandyButton(
                  color: AppColors.softPink,
                  shadow: AppColors.softPinkShadow,
                  onTap: _restart,
                  child: _btnText('Replay', color: AppColors.accent, size: 17),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CandyButton(
                  color: AppColors.lavender,
                  shadow: AppColors.lavenderShadow,
                  onTap: () => Navigator.of(context).pop(),
                  child: _btnText('Levels', color: AppColors.body, size: 17),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loseOverlay() => _scrim(
    child: _card(
      children: [
        const Text('😣', style: TextStyle(fontSize: 46)),
        Text(
          _loseReason == 'reach' ? 'Bubbles broke through!' : 'Out of moves!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Score',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        Text(
          '${_engine.score}',
          style: const TextStyle(
            fontSize: 42,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 14),
        CandyButton(
          gradient: const [AppColors.pinkLight, AppColors.pink],
          shadow: AppColors.pinkShadow,
          expand: true,
          onTap: _restart,
          child: _btnText('Retry'),
        ),
        const SizedBox(height: 12),
        CandyButton(
          color: AppColors.lavender,
          shadow: AppColors.lavenderShadow,
          expand: true,
          onTap: () => Navigator.of(context).pop(),
          child: _btnText('Levels', color: AppColors.body),
        ),
      ],
    ),
  );

  Widget _btnText(String t, {Color color = Colors.white, double size = 20}) =>
      Text(
        t,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.label,
    required this.count,
    required this.armed,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool armed;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.barButton,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: armed ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(color: AppColors.pillShadow, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.body,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 2,
            right: 4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16),
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
