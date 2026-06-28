import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/audio_service.dart';
import '../core/theme.dart';
import '../game/bubble_engine.dart';
import '../game/bubble_pop_game.dart';
import '../game/levels.dart';
import '../game/sections.dart';
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

  final List<_PraiseData> _praises = [];
  int _praiseId = 0;
  final math.Random _rng = math.Random();

  GameSection get _section => GameSection(_level ~/ kSectionSize);

  @override
  void initState() {
    super.initState();
    _start(widget.level);
  }

  void _start(int level) {
    _level = level;
    _winStars = 0;
    _phase = _Phase.playing;
    _praises.clear();
    _engine = BubbleEngine()
      ..soundOn = GameScope.read(context).soundOn
      ..onSync = _scheduleSync
      ..onSfx = AudioService.instance.play
      ..onWin = _handleWin
      ..onLose = _handleLose
      ..onPraise = _handlePraise;
    _game = BubblePopGame(engine: _engine, levelIndex: level);
  }

  // Lots of fun, kid-friendly words. Each combo level picks randomly from its
  // tier so the same word rarely repeats.
  static const List<List<String>> _praiseTiers = [
    ['Pop!', 'Nice!', 'Yay!', 'Cool!', 'Good!', 'Nice One!', 'Woohoo!'],
    ['Sweet!', 'Yummy!', 'Tasty!', 'Great!', 'Lovely!', 'Sugar Pop!'],
    ['Super!', 'Wow!', 'Awesome!', 'Boom!', 'Sugar Rush!', 'Splendid!'],
    [
      'Amazing!',
      'Fantastic!',
      'Bravo!',
      'Magic!',
      'Sweet Combo!',
      'Brilliant!',
    ],
    ['Incredible!', 'Spectacular!', 'Candylicious!', 'Mega Pop!', 'Wonderful!'],
    [
      'Unstoppable!',
      'Legendary!',
      'Champion!',
      'Bubble Master!',
      'Sugar Star!',
    ],
  ];
  static const List<Color> _praiseColors = [
    AppColors.accent,
    Color(0xFFFF9A3D),
    Color(0xFF9B6BFF),
    Color(0xFF2FB6D6),
    Color(0xFF3DDC84),
  ];

  void _handlePraise(int combo, int popped) {
    final tier = (combo - 1).clamp(0, _praiseTiers.length - 1);
    final options = _praiseTiers[tier];
    final text = (popped >= 7 && combo <= 1)
        ? 'Big Pop!'
        : options[_rng.nextInt(options.length)];
    final color = _praiseColors[(combo - 1).clamp(0, _praiseColors.length - 1)];
    final id = _praiseId++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Tactile feedback works even without audio files bundled.
      if (GameScope.read(context).soundOn) {
        if (combo >= 3) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      }
      setState(() => _praises.add(_PraiseData(id, text, color)));
    });
  }

  void _removePraise(int id) {
    if (!mounted) return;
    setState(() => _praises.removeWhere((p) => p.id == id));
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
    final s = _section;
    return Scaffold(
      body: DecoratedBox(
        // Each world tints the play area with its own colour (kept light so
        // the bubbles stay readable).
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              s.gradient.first.withValues(alpha: 0.30),
              const Color(0xFFFBF1F8),
              s.gradient.last.withValues(alpha: 0.22),
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
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
              // Reward popups ("Sweet!", "Combo!").
              if (_praises.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: const Alignment(0, -0.32),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (final pr in _praises)
                            _PraisePop(
                              key: ValueKey(pr.id),
                              text: pr.text,
                              color: pr.color,
                              onDone: () => _removePraise(pr.id),
                            ),
                        ],
                      ),
                    ),
                  ),
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
    Color bg = Colors.white,
  }) {
    return CandyButton(
      color: bg,
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
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PowerButton(
            label: 'Bomb',
            count: _engine.bomb,
            armed: _engine.active == 'bomb',
            icon: _bombIcon(),
            onTap: _engine.selectBomb,
          ),
          const SizedBox(width: 16),
          _PowerButton(
            label: 'Clear',
            count: _engine.clear,
            armed: _engine.active == 'clear',
            icon: _clearIcon(),
            onTap: _engine.selectClear,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _circleButton(
              onTap: _engine.swap,
              icon: Icons.swap_horiz_rounded,
              color: AppColors.body,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'NEXT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.label,
                ),
              ),
              const SizedBox(height: 5),
              _glossyBubble(BubblePalette.base[_engine.next], 40),
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

class _PowerButton extends StatefulWidget {
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
  State<_PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<_PowerButton> {
  bool _down = false;
  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) {
    final armed = widget.armed;
    final empty = widget.count <= 0;
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: empty ? 0.45 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon tile.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: armed
                            ? AppColors.accent
                            : const Color(0x14000000),
                        width: armed ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: armed
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : AppColors.heading.withValues(alpha: 0.14),
                          blurRadius: armed ? 16 : 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(child: widget.icon),
                  ),
                  // Count badge.
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 21,
                        minHeight: 21,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.pinkLight, AppColors.pink],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.count}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: armed ? AppColors.accent : AppColors.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PraiseData {
  const _PraiseData(this.id, this.text, this.color);
  final int id;
  final String text;
  final Color color;
}

/// A bouncy, white-outlined "sticker" reward word that pops in, floats up and
/// fades — the juicy feedback shown when bubbles are cleared.
class _PraisePop extends StatefulWidget {
  const _PraisePop({
    super.key,
    required this.text,
    required this.color,
    required this.onDone,
  });

  final String text;
  final Color color;
  final VoidCallback onDone;

  @override
  State<_PraisePop> createState() => _PraisePopState();
}

class _PraisePopState extends State<_PraisePop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final pop = t < 0.4
            ? Curves.elasticOut.transform((t / 0.4).clamp(0.0, 1.0))
            : 1.0;
        final rise =
            -56.0 * Curves.easeOut.transform(((t - 0.3) / 0.7).clamp(0.0, 1.0));
        final fade = t < 0.65 ? 1.0 : (1 - (t - 0.65) / 0.35).clamp(0.0, 1.0);
        final tilt = (1 - pop) * 0.12;
        return Transform.translate(
          offset: Offset(0, rise),
          child: Opacity(
            opacity: fade,
            child: Transform.rotate(
              angle: -tilt,
              child: Transform.scale(
                scale: pop.clamp(0.0, 1.15),
                child: _sticker(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sticker() {
    const style = TextStyle(
      fontSize: 40,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    );
    return Stack(
      children: [
        // White outline.
        Text(
          widget.text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 9
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
          ),
        ),
        // Coloured fill.
        Text(
          widget.text,
          style: style.copyWith(
            color: widget.color,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.18),
                offset: const Offset(0, 3),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
