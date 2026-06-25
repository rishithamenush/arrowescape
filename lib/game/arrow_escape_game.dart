import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../logic/board_controller.dart';
import '../models/arrow.dart';
import 'arrow_component.dart';

/// Flame game that renders the puzzle board and drives the tap → escape /
/// shake flow. Logic stays in [BoardController]; this layer is pure
/// presentation + input. Win / stuck results are reported via [onResolved]
/// (fired after the escape animation so dialogs appear at the right moment).
class ArrowEscapeGame extends FlameGame {
  ArrowEscapeGame({
    required this.controller,
    required this.onChanged,
    required this.onResolved,
  });

  final BoardController controller;

  /// Called on every state change so the Flutter HUD can refresh.
  final VoidCallback onChanged;

  /// Called when the board is won or becomes stuck.
  final void Function(BoardStatus) onResolved;

  final Map<String, ArrowComponent> _components = {};
  final math.Random _rng = math.Random();

  static const double _gap = 7;
  double _cell = 0;
  double _boardSize = 0;
  Vector2 _origin = Vector2.zero();

  bool _inputLocked = false;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    _layout();
    add(_BoardBackground(this));
    _buildArrows();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _layout();
      _repositionArrows();
    }
  }

  void _layout() {
    _boardSize = math.min(size.x, size.y);
    _cell =
        (_boardSize - _gap * (controller.level.cols + 1)) /
        controller.level.cols;
    _origin = Vector2((size.x - _boardSize) / 2, (size.y - _boardSize) / 2);
  }

  Vector2 _centerFor(int row, int col) =>
      _origin +
      Vector2(
        _gap + col * (_cell + _gap) + _cell / 2,
        _gap + row * (_cell + _gap) + _cell / 2,
      );

  void _buildArrows() {
    for (final c in _components.values) {
      c.removeFromParent();
    }
    _components.clear();
    for (final a in controller.arrows) {
      final comp = ArrowComponent(
        arrow: a,
        onTapArrow: _onArrowTapped,
        cell: _cell,
        center: _centerFor(a.row, a.col),
      );
      _components[a.id] = comp;
      add(comp);
    }
  }

  void _repositionArrows() {
    for (final comp in _components.values) {
      comp
        ..size = Vector2.all(_cell)
        ..position = _centerFor(comp.arrow.row, comp.arrow.col);
    }
  }

  void _onArrowTapped(ArrowComponent comp) {
    if (_inputLocked || controller.status != BoardStatus.playing) return;

    final escaped = controller.tapArrow(comp.arrow);
    onChanged();

    if (escaped) {
      _inputLocked = true;
      _components.remove(comp.arrow.id);
      _spawnBurst(comp.position, comp.arrow.color);
      comp.playEscape(_escapeOffset(comp.arrow), () {
        _inputLocked = false;
        _reportResult();
      });
    } else {
      comp.playShake(controller.clearBlocked);
    }
  }

  Vector2 _escapeOffset(ArrowModel a) {
    final step = a.dir.vector;
    return Vector2(step.col.toDouble(), step.row.toDouble()) * _boardSize;
  }

  void _reportResult() {
    if (controller.status == BoardStatus.won) {
      onResolved(BoardStatus.won);
    } else if (controller.status == BoardStatus.stuck) {
      onResolved(BoardStatus.stuck);
    }
  }

  void _spawnBurst(Vector2 center, int colorIndex) {
    final color = AppColors.arrowColor(colorIndex);
    add(
      ParticleSystemComponent(
        position: center,
        particle: Particle.generate(
          count: 16,
          generator: (i) {
            final angle = _rng.nextDouble() * math.pi * 2;
            final speed = 80 + _rng.nextDouble() * 160;
            return AcceleratedParticle(
              acceleration: Vector2(0, 240),
              speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
              lifespan: 0.5 + _rng.nextDouble() * 0.3,
              child: CircleParticle(
                radius: _cell * 0.05 + _rng.nextDouble() * 2,
                paint: Paint()..color = color.withValues(alpha: 0.9),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Public API used by the Flutter screen --------------------------------

  /// Rebuilds all arrow components from the controller (after undo / restart).
  void syncFromController() {
    _inputLocked = false;
    _buildArrows();
  }

  /// Pulses the hint glow on the given arrow.
  void highlight(String arrowId) => _components[arrowId]?.pulseHint();
}

/// Rounded board surface with faint per-cell guides, drawn behind the arrows.
class _BoardBackground extends PositionComponent {
  _BoardBackground(this.game) {
    priority = -10;
  }

  final ArrowEscapeGame game;

  @override
  void render(Canvas canvas) {
    final origin = game._origin;
    final boardSize = game._boardSize;
    final cell = game._cell;
    const gap = ArrowEscapeGame._gap;
    final cols = game.controller.level.cols;
    final rows = game.controller.level.rows;

    final boardRect = Rect.fromLTWH(origin.x, origin.y, boardSize, boardSize);
    final boardRRect = RRect.fromRectAndRadius(
      boardRect,
      const Radius.circular(AppSpacing.radiusLg),
    );

    canvas.drawRRect(boardRRect, Paint()..color = AppColors.surfaceAlt);

    final cellPaint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(
          origin.x + gap + c * (cell + gap),
          origin.y + gap + r * (cell + gap),
          cell,
          cell,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.22)),
          cellPaint,
        );
      }
    }
  }
}
