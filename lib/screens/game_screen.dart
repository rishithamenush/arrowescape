import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

// Flame re-exports vector_math's Matrix4, which collides with Flutter's
// (vector_math_64) Matrix4 used by GradientTransform — hide it to disambiguate.
import 'package:flame/game.dart' hide Matrix4;
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
import '../widgets/liquid_glass.dart';

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

  /// Bubbles on the board when the level began — drives the progress bar.
  int? _initialFilled;

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
    _initialFilled = null;
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
      if (!mounted) return;
      // Capture the starting bubble count once the board has booted, so the
      // HUD progress bar knows what "100% cleared" means.
      if (_initialFilled == null && _engine.grid.isNotEmpty) {
        final n = _engine.filledCount();
        if (n > 0) _initialFilled = n;
      }
      setState(() {});
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
      // Play a little star chime for each star earned, timed with the popup.
      for (var i = 0; i < stars; i++) {
        Future.delayed(
          Duration(milliseconds: 450 + i * 350),
          () => AudioService.instance.play('star'),
        );
      }
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

  void _toggleMusic() {
    GameScope.read(context).toggleMusic();
    setState(() {});
  }

  /// 0 → untouched board, 1 → fully cleared.
  double get _progress {
    final start = _initialFilled;
    if (start == null || start == 0) return 0;
    return (1 - _engine.filledCount() / start).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    _engine.soundOn = state.soundOn;
    final s = _section;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _background(s)),
          SafeArea(
            child: Column(
              children: [
                _hud(s),
                Expanded(child: _board()),
                _dock(),
              ],
            ),
          ),
          // Floating combo banner just under the HUD.
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 108),
                child: IgnorePointer(child: _comboBanner()),
              ),
            ),
          ),
          // Reward popups ("Sweet!", "Combo!").
          if (_praises.isNotEmpty)
            Positioned.fill(
              key: const ValueKey('praises'),
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
          if (_phase == _Phase.pause) _pauseOverlay(state),
          if (_phase == _Phase.win) _winOverlay(s),
          if (_phase == _Phase.lose) _loseOverlay(),
        ],
      ),
    );
  }

  // ---------- background ----------

  /// Plain, clean full-screen backdrop — the world illustration lives inside
  /// the board panel only (see [_board]), so the chrome around it stays calm.
  Widget _background(GameSection s) {
    return const ColoredBox(color: Color(0xFFFDF3FA));
  }

  // ---------- HUD ----------

  /// One frosted command strip: pause · level/score/progress · moves ring.
  Widget _hud(GameSection s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: LiquidGlass(
        radius: 26,
        blur: 16,
        opacity: 0.52,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          children: [
            _GlassIconButton(icon: Icons.pause_rounded, onTap: _pause),
            const SizedBox(width: 10),
            Expanded(child: _scorePanel(s)),
            const SizedBox(width: 10),
            _MovesRing(
              shots: _engine.shots,
              maxShots: _engine.maxShots,
            ),
          ],
        ),
      ),
    );
  }

  Widget _scorePanel(GameSection s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(s.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'LEVEL ${_level + 1} · ${s.name.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.label,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Score counts up smoothly instead of snapping.
            TweenAnimationBuilder<double>(
              tween: Tween(end: _engine.score.toDouble()),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                '${v.round()}',
                style: const TextStyle(
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.heading,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _progressBar(s)),
          ],
        ),
      ],
    );
  }

  /// Live "board cleared" bar in the world's colours.
  Widget _progressBar(GameSection s) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: Colors.white.withValues(alpha: 0.55)),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              widthFactor: _progress,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: s.gradient),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comboBanner() {
    final combo = _engine.combo;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: combo < 2
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(combo),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD23F), Color(0xFFFF7A3D)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A3D).withValues(alpha: 0.5),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'COMBO ×$combo',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ---------- board ----------

  /// The Flame board sits in a softly framed glass panel so the play area
  /// reads as "the stage" of the screen. The world illustration is shown
  /// inside this panel only, at low opacity, so bubbles stay readable while
  /// the board still feels like part of the world.
  Widget _board() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // World artwork, clipped to the board and faded right down.
            Opacity(
              opacity: 0.95,
              child: Image.asset(
                'assets/worlds/world${_section.index + 1}.png',
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // Light frost + glass rim over the artwork.
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.4,
                ),
              ),
            ),
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => _engine.onAim(e.localPosition),
              onPointerMove: (e) => _engine.onAim(e.localPosition),
              onPointerUp: (e) => _engine.onShoot(e.localPosition),
              child: GameWidget(game: _game),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- bottom dock ----------

  /// A single frosted dock: power-ups on the left, swap + next-bubble
  /// chamber on the right.
  Widget _dock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: LiquidGlass(
        radius: 28,
        blur: 16,
        opacity: 0.52,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            _PowerOrb(
              label: 'BOMB',
              count: _engine.bomb,
              armed: _engine.active == 'bomb',
              icon: _bombIcon(),
              onTap: _engine.selectBomb,
            ),
            const SizedBox(width: 14),
            _PowerOrb(
              label: 'CLEAR',
              count: _engine.clear,
              armed: _engine.active == 'clear',
              icon: const _ClearGem(),
              onTap: _engine.selectClear,
            ),
            const Spacer(),
            _GlassIconButton(
              icon: Icons.swap_horiz_rounded,
              size: 46,
              onTap: _engine.swap,
            ),
            const SizedBox(width: 12),
            // Next-bubble chamber — also tappable to swap.
            GestureDetector(
              onTap: _engine.swap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'NEXT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: _glossyBubble(
                      BubblePalette.base[_engine.next],
                      40,
                      key: ValueKey(_engine.next),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _glossyBubble(Color color, double size, {Key? key}) => Container(
    key: key,
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [Colors.white.withValues(alpha: 0.8), color],
        stops: const [0, 0.45],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.45),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
  );

  // ---------- overlays ----------

  /// Blurred + tinted scrim with a springy card entrance.
  Widget _scrim({Key? key, required Widget child, Widget? behind}) {
    return Positioned.fill(
      key: key,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ColoredBox(
            color: const Color(0x8C3C2846),
            child: Stack(
              children: [
                if (behind != null) Positioned.fill(child: behind),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.3, end: 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    builder: (_, v, c) =>
                        Transform.scale(scale: v.clamp(0, 1.1), child: c),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => SizedBox(
    width: math.min(MediaQuery.sizeOf(context).width * 0.84, 380),
    child: LiquidGlass(
      radius: 30,
      blur: 24,
      opacity: 0.86,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    ),
  );

  /// Big gradient headline used across the overlays.
  Widget _headline(String text, List<Color> colors, {double size = 30}) {
    return ShaderMask(
      shaderCallback: (r) => LinearGradient(colors: colors).createShader(r),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _scoreBlock(int score) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        'SCORE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: AppColors.muted,
        ),
      ),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score.toDouble()),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text(
          '${v.round()}',
          style: const TextStyle(
            fontSize: 44,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: AppColors.heading,
          ),
        ),
      ),
    ],
  );

  Widget _pauseOverlay(GameState state) => _scrim(
    key: const ValueKey('pause'),
    child: _card(
      children: [
        Text(_section.emoji, style: const TextStyle(fontSize: 34)),
        const SizedBox(height: 4),
        const Text(
          'Paused',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.heading,
          ),
        ),
        Text(
          'LEVEL ${_level + 1} · ${_section.name.toUpperCase()}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.label,
          ),
        ),
        const SizedBox(height: 18),
        CandyButton(
          gradient: const [AppColors.mintLight, AppColors.mint],
          shadow: AppColors.mintShadow,
          expand: true,
          onTap: _resume,
          child: _btnText('Resume'),
        ),
        const SizedBox(height: 12),
        CandyButton(
          gradient: const [AppColors.amberLight, AppColors.amber],
          shadow: AppColors.amberShadow,
          expand: true,
          onTap: _restart,
          child: _btnText('Restart'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CandyButton(
                color: AppColors.softPink,
                shadow: AppColors.softPinkShadow,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                onTap: _toggleSound,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.soundOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    _btnText('Sound', color: AppColors.accent, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CandyButton(
                color: AppColors.softPink,
                shadow: AppColors.softPinkShadow,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                onTap: _toggleMusic,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.musicOn
                          ? Icons.music_note_rounded
                          : Icons.music_off_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    _btnText('Music', color: AppColors.accent, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CandyButton(
          color: AppColors.lavender,
          shadow: AppColors.lavenderShadow,
          expand: true,
          onTap: () => Navigator.of(context).pop(),
          child: _btnText('Levels', color: AppColors.body, size: 16),
        ),
      ],
    ),
  );

  Widget _winOverlay(GameSection s) {
    final hasNext = _level + 1 < kLevels.length;
    return _scrim(
      key: const ValueKey('win'),
      behind: const IgnorePointer(child: _Confetti()),
      child: _card(
        children: [
          Text(s.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 2),
          _headline('Level Complete!', const [
            AppColors.accent,
            Color(0xFFFF9A3D),
          ]),
          Text(
            'LEVEL ${_level + 1} · ${s.name.toUpperCase()}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 10),
          _WinStars(stars: _winStars),
          const SizedBox(height: 10),
          _scoreBlock(_engine.score),
          const SizedBox(height: 18),
          if (hasNext) ...[
            CandyButton(
              gradient: const [AppColors.pinkLight, AppColors.pink],
              shadow: AppColors.pinkShadow,
              expand: true,
              onTap: _nextLevel,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _btnText('Next Level'),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
    key: const ValueKey('lose'),
    child: _card(
      children: [
        const Text('😅', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 4),
        _headline('So Close!', const [Color(0xFF9B6BFF), Color(0xFF2FB6D6)]),
        const SizedBox(height: 4),
        Text(
          _loseReason == 'reach'
              ? 'The bubbles broke through the line.'
              : 'You ran out of moves.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.body,
          ),
        ),
        const SizedBox(height: 12),
        _scoreBlock(_engine.score),
        const SizedBox(height: 18),
        CandyButton(
          gradient: const [AppColors.pinkLight, AppColors.pink],
          shadow: AppColors.pinkShadow,
          expand: true,
          onTap: _restart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.replay_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 6),
              _btnText('Try Again'),
            ],
          ),
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

// ============================ HUD widgets ============================

/// Round frosted icon button used in the HUD and dock.
class _GlassIconButton extends StatefulWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _down = false;
  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? 0.88 : 1,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: LiquidGlass(
          radius: widget.size / 2,
          blur: 0,
          opacity: 0.6,
          shadow: false,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Icon(widget.icon, color: AppColors.accent, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Circular moves meter: a gradient ring that drains as shots are spent and
/// pulses red when the player is nearly out of moves.
class _MovesRing extends StatefulWidget {
  const _MovesRing({required this.shots, required this.maxShots});

  final int shots;
  final int maxShots;

  @override
  State<_MovesRing> createState() => _MovesRingState();
}

class _MovesRingState extends State<_MovesRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  bool get _low => widget.shots <= 3;

  @override
  void initState() {
    super.initState();
    if (_low) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MovesRing old) {
    super.didUpdateWidget(old);
    if (_low && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_low && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frac = widget.maxShots == 0
        ? 0.0
        : (widget.shots / widget.maxShots).clamp(0.0, 1.0);
    // Mint when plenty of moves left, amber mid-way, hot pink when low.
    final color = frac > 0.55
        ? Color.lerp(AppColors.amber, AppColors.mint, (frac - 0.55) / 0.45)!
        : Color.lerp(AppColors.accent, AppColors.amber, frac / 0.55)!;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: 1 + 0.07 * _pulse.value,
        child: child,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: frac),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (_, f, __) => CustomPaint(
          painter: _RingPainter(fraction: f, color: color),
          child: SizedBox(
            width: 58,
            height: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.shots}',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: _low ? AppColors.accent : AppColors.heading,
                  ),
                ),
                const Text(
                  'MOVES',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.label,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white.withValues(alpha: 0.65);
    canvas.drawCircle(center, radius, track);

    if (fraction <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    // Soft glow under the arc, then the crisp arc itself.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = color.withValues(alpha: 0.55);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    final sweep = fraction * 2 * math.pi;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

// ============================ dock widgets ============================

/// Power-up orb: frosted circle with a glowing accent ring while armed and a
/// candy count badge.
class _PowerOrb extends StatefulWidget {
  const _PowerOrb({
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
  State<_PowerOrb> createState() => _PowerOrbState();
}

class _PowerOrbState extends State<_PowerOrb> {
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: armed ? 0.9 : 0.6),
                      border: Border.all(
                        color: armed
                            ? AppColors.accent
                            : Colors.white.withValues(alpha: 0.7),
                        width: armed ? 2.4 : 1.3,
                      ),
                      boxShadow: armed
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Center(child: widget.icon),
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.pinkLight, AppColors.pink],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1.8),
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
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: armed ? AppColors.accent : AppColors.label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================ overlay widgets ============================

/// Three big stars that pop in one after another on the win screen.
class _WinStars extends StatefulWidget {
  const _WinStars({required this.stars});

  final int stars;

  @override
  State<_WinStars> createState() => _WinStarsState();
}

class _WinStarsState extends State<_WinStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var k = 0; k < 3; k++) _star(k),
          ],
        );
      },
    );
  }

  Widget _star(int k) {
    final earned = k < widget.stars;
    // Stagger: star k pops between 0.25k and 0.25k + 0.35 of the timeline.
    final t = ((_c.value - k * 0.25) / 0.35).clamp(0.0, 1.0);
    final scale = earned ? Curves.elasticOut.transform(t) : 1.0;
    final mid = k == 1;
    return Transform.translate(
      offset: Offset(0, mid ? -10 : 0),
      child: Transform.scale(
        scale: (mid ? 1.18 : 1.0) * scale.clamp(0.0, 1.3),
        child: Icon(
          Icons.star_rounded,
          size: 52,
          color: earned ? const Color(0xFFFFCE3D) : const Color(0xFFE3D6EC),
          shadows: earned
              ? [
                  Shadow(
                    color: const Color(0xFFFF9A3D).withValues(alpha: 0.6),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// Lightweight looping confetti drawn behind the win card.
class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  late final List<_ConfettiPiece> _pieces = List.generate(38, (i) {
    final rng = math.Random(i * 7 + 3);
    return _ConfettiPiece(
      x: rng.nextDouble(),
      phase: rng.nextDouble(),
      speed: 0.6 + rng.nextDouble() * 0.8,
      size: 6 + rng.nextDouble() * 6,
      spin: (rng.nextDouble() - 0.5) * 10,
      color: BubblePalette.base[rng.nextInt(BubblePalette.base.length)],
    );
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        painter: _ConfettiPainter(_c.value, _pieces),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.spin,
    required this.color,
  });

  final double x, phase, speed, size, spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.t, this.pieces);

  final double t;
  final List<_ConfettiPiece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final y = progress * (size.height + 40) - 20;
      final sway = math.sin((t * 3 + p.phase) * 2 * math.pi) * 22;
      final x = p.x * size.width + sway;
      paint.color = p.color.withValues(alpha: 0.9);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ============================ praise pops ============================

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

// ============================ power icons ============================

/// Slides a gradient horizontally by a fraction of its bounds — paired with
/// [TileMode.mirror] this makes the holographic sheen flow seamlessly.
class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.t);
  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * t, 0, 0);
}

/// The "Clear" power gem: a glossy holographic orb whose iridescent sheen flows
/// across it, with a glassy radial sheen, a breathing glow and a glowing star at
/// its heart — a premium, eye-catching power icon.
class _ClearGem extends StatefulWidget {
  const _ClearGem();

  @override
  State<_ClearGem> createState() => _ClearGemState();
}

class _ClearGemState extends State<_ClearGem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  // Iridescent holographic palette — soft, blended candy tones that loop
  // seamlessly (first == last) for a continuous flowing sheen.
  static const List<Color> _holo = [
    Color(0xFFFF8FD0),
    Color(0xFFB18CFF),
    Color(0xFF6FE0FF),
    Color(0xFF7BF6C2),
    Color(0xFFFFE08A),
    Color(0xFFFF8FD0),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const d = 32.0;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi); // breathing glow
        return SizedBox(
          width: d,
          height: d,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Holographic orb: a soft iridescent gradient that slides across
              // for a flowing sheen, with a crisp white rim + soft glow.
              Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    tileMode: TileMode.mirror,
                    transform: _SlideTransform(t),
                    colors: _holo,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF9B6BFF,
                      ).withValues(alpha: 0.35 + 0.25 * pulse),
                      blurRadius: 8 + 4 * pulse,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
              // Radial inner light for a glassy, 3-D sheen.
              Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.5),
                    radius: 0.95,
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
              // Specular highlight skimming the top-left.
              Positioned(
                top: d * 0.16,
                left: d * 0.2,
                child: Container(
                  width: d * 0.34,
                  height: d * 0.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(d),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              // Glowing star at the centre.
              Icon(
                Icons.star_rounded,
                size: d * 0.5,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: const Color(0xFF9B6BFF).withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
