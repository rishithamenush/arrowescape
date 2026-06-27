import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'levels.dart';

/// Bubble palette (base / light highlight / dark rim), from the prototype.
class BubblePalette {
  BubblePalette._();
  static const List<Color> base = [
    Color(0xFFFF4D8D), // pink
    Color(0xFFFFD23F), // yellow
    Color(0xFF3EC8E0), // cyan
    Color(0xFF3DDC84), // green
    Color(0xFF9B6BFF), // purple
    Color(0xFFFF8A3D), // orange
  ];
  static const List<Color> light = [
    Color(0xFFFF9EC1),
    Color(0xFFFFE58A),
    Color(0xFF9BE8F5),
    Color(0xFF9BEDBB),
    Color(0xFFCDAEFF),
    Color(0xFFFFC093),
  ];
  static const List<Color> dark = [
    Color(0xFFC42B66),
    Color(0xFFD79F1E),
    Color(0xFF1F96AC),
    Color(0xFF1EA65C),
    Color(0xFF6E3FC4),
    Color(0xFFCC5E1C),
  ];
}

class Projectile {
  Projectile(this.x, this.y, this.vx, this.vy, this.ci, this.special);
  double x, y, vx, vy;
  final int ci;
  final String? special; // 'bomb' | 'clear' | null
}

class _Particle {
  _Particle(
    this.x,
    this.y,
    this.vx,
    this.vy,
    this.life,
    this.max,
    this.r,
    this.color,
  );
  double x, y, vx, vy, life;
  final double max, r;
  final Color color;
}

class _Ring {
  _Ring(this.x, this.y, this.r, this.max, this.life, this.color);
  final double x, y;
  double r, life;
  final double max;
  final Color color;
}

/// Difficulty move multiplier.
double difficultyMult(String d) =>
    d == 'Chill' ? 1.4 : (d == 'Hard' ? 0.78 : 1.0);

/// Pure-Dart port of the Bubble Pop game engine (hex grid math, aiming,
/// collision, snapping, flood-fill matching, drop-floating, power-ups, win/
/// lose). Rendering lives in [render]; everything else is framework-free and
/// unit-testable.
class BubbleEngine {
  BubbleEngine({this.difficulty = 'Normal', this.aimGuide = true});

  static const int cols = 9;

  final String difficulty;
  final bool aimGuide;

  // Callbacks to the Flutter layer.
  VoidCallback? onSync;
  void Function(int stars)? onWin;
  void Function(String reason)? onLose;
  void Function(String sfx)? onSfx;

  // Geometry (set from the view size).
  double w = 0, h = 0, r = 0, rowH = 0, top = 0, sx = 0, sy = 0, dangerY = 0;
  int maxRow = 0;

  // State.
  int levelIndex = 0;
  List<int> palette = [];
  List<List<int?>> grid = [];
  int cur = 0, next = 1;
  int score = 0, combo = 0, shots = 18, maxShots = 18;
  int bomb = 2, clear = 1;
  String? active;
  Offset aim = Offset.zero;
  Projectile? proj;
  double shake = 0;
  bool running = false;
  bool finished = false;
  bool soundOn = true;

  final List<_Particle> _parts = [];
  final List<_Ring> _rings = [];
  final math.Random _rng = math.Random();

  bool _booted = false;

  // ---------- geometry ----------
  int rowLen(int row) => row % 2 == 0 ? cols : cols - 1;
  double cellX(int row, int c) => r + c * 2 * r + (row % 2) * r;
  double cellY(int row) => top + r + row * rowH;
  bool valid(int row, int c) =>
      row >= 0 && row <= maxRow && c >= 0 && c < rowLen(row);

  List<List<int>> neighbors(int row, int c) {
    final res = <List<int>>[
      [row, c - 1],
      [row, c + 1],
    ];
    if (row % 2 == 0) {
      res.addAll([
        [row - 1, c - 1],
        [row - 1, c],
        [row + 1, c - 1],
        [row + 1, c],
      ]);
    } else {
      res.addAll([
        [row - 1, c],
        [row - 1, c + 1],
        [row + 1, c],
        [row + 1, c + 1],
      ]);
    }
    return res.where((p) => valid(p[0], p[1])).toList();
  }

  void eachFilled(void Function(int r, int c, int v) cb) {
    for (var row = 0; row < grid.length; row++) {
      for (var c = 0; c < grid[row].length; c++) {
        final v = grid[row][c];
        if (v != null) cb(row, c, v);
      }
    }
  }

  int filledCount() {
    var n = 0;
    eachFilled((_, __, ___) => n++);
    return n;
  }

  // ---------- setup ----------
  void setSize(double width, double height) {
    w = width;
    h = height;
    r = w / (2 * cols);
    rowH = r * math.sqrt(3);
    top = r * 0.4;
    sx = w / 2;
    sy = h - r - 6;
    maxRow = math.max(8, ((sy - top - r * 3) / rowH).floor());
    dangerY = sy - r * 2.2;
  }

  void boot(int levelIdx) {
    levelIndex = levelIdx;
    finished = false;
    running = true;
    final cfg = kLevels[levelIdx];
    final shotsN = math.max(
      8,
      (cfg.shots * difficultyMult(difficulty)).round(),
    );
    score = 0;
    combo = 0;
    shots = shotsN;
    maxShots = shotsN;
    bomb = 2;
    clear = 1;
    active = null;
    proj = null;
    shake = 0;
    _parts.clear();
    _rings.clear();

    palette = [for (var i = 0; i < cfg.colors; i++) i];
    grid = [];
    for (var row = 0; row <= maxRow; row++) {
      final len = rowLen(row);
      final list = List<int?>.filled(len, null);
      if (row < cfg.rows) {
        for (var c = 0; c < len; c++) {
          if (row == 0 || _rng.nextDouble() < 0.88) {
            list[c] = palette[(_rng.nextDouble() * palette.length).toInt()];
          }
        }
      }
      grid.add(list);
    }
    cur = _pick();
    next = _pick();
    aim = Offset(sx, top);
    _booted = true;
    onSync?.call();
  }

  int _pick() {
    final present = <int>{};
    eachFilled((r, c, v) {
      if (palette.contains(v)) present.add(v);
    });
    final arr = present.isNotEmpty ? present.toList() : palette;
    return arr[(_rng.nextDouble() * arr.length).toInt()];
  }

  // ---------- input ----------
  void onAim(Offset p) {
    if (!running) return;
    aim = p;
  }

  void onShoot(Offset p) {
    if (!running || proj != null) return;
    aim = p;
    _shoot();
  }

  ({double dx, double dy}) aimDir() {
    var ax = aim.dx - sx, ay = aim.dy - sy;
    if (ay > -12) ay = -12; // never shoot down / flat
    final len = math.sqrt(ax * ax + ay * ay);
    final l = len == 0 ? 1 : len;
    return (dx: ax / l, dy: ay / l);
  }

  void _shoot() {
    final special = active;
    final d = aimDir();
    const speed = 1150.0;
    proj = Projectile(sx, sy, d.dx * speed, d.dy * speed, cur, special);
    shots -= 1;
    if (special == 'bomb') {
      bomb -= 1;
    } else if (special == 'clear') {
      clear -= 1;
    } else {
      cur = next;
      next = _pick();
    }
    active = null;
    onSfx?.call('shoot');
    onSync?.call();
  }

  void selectBomb() {
    if (bomb > 0 && proj == null) {
      active = active == 'bomb' ? null : 'bomb';
      onSync?.call();
    }
  }

  void selectClear() {
    if (clear > 0 && proj == null) {
      active = active == 'clear' ? null : 'clear';
      onSync?.call();
    }
  }

  void swap() {
    if (proj != null) return;
    final t = cur;
    cur = next;
    next = t;
    onSfx?.call('tap');
    onSync?.call();
  }

  // ---------- snapping / matching ----------
  List<int> _snapCell(double x, double y) {
    List<int>? best;
    var bd = double.infinity;
    for (var row = 0; row <= maxRow; row++) {
      for (var c = 0; c < rowLen(row); c++) {
        if (grid[row][c] != null) continue;
        var connected = row == 0;
        if (!connected) {
          for (final n in neighbors(row, c)) {
            if (grid[n[0]][n[1]] != null) {
              connected = true;
              break;
            }
          }
        }
        if (!connected) continue;
        final dx = x - cellX(row, c), dy = y - cellY(row);
        final d = dx * dx + dy * dy;
        if (d < bd) {
          bd = d;
          best = [row, c];
        }
      }
    }
    if (best != null) return best;
    final row = math.max(0, math.min(maxRow, ((y - top - r) / rowH).round()));
    final c = math.max(
      0,
      math.min(rowLen(row) - 1, ((x - r - (row % 2) * r) / (2 * r)).round()),
    );
    return [row, c];
  }

  List<List<int>> _floodSame(int row, int c, int color) {
    final seen = <String>{'$row,$c'};
    final stack = [
      [row, c],
    ];
    final out = [
      [row, c],
    ];
    while (stack.isNotEmpty) {
      final cell = stack.removeLast();
      for (final n in neighbors(cell[0], cell[1])) {
        final k = '${n[0]},${n[1]}';
        if (!seen.contains(k) && grid[n[0]][n[1]] == color) {
          seen.add(k);
          stack.add(n);
          out.add(n);
        }
      }
    }
    return out;
  }

  int _dropFloating() {
    final seen = <String>{};
    final stack = <List<int>>[];
    for (var c = 0; c < rowLen(0); c++) {
      if (grid[0][c] != null) {
        seen.add('0,$c');
        stack.add([0, c]);
      }
    }
    while (stack.isNotEmpty) {
      final cell = stack.removeLast();
      for (final n in neighbors(cell[0], cell[1])) {
        final k = '${n[0]},${n[1]}';
        if (!seen.contains(k) && grid[n[0]][n[1]] != null) {
          seen.add(k);
          stack.add(n);
        }
      }
    }
    var dropped = 0;
    eachFilled((row, c, v) {
      if (!seen.contains('$row,$c')) {
        dropped++;
        _pop(cellX(row, c), cellY(row), v, false);
        grid[row][c] = null;
      }
    });
    if (dropped > 0) score += dropped * 20;
    return dropped;
  }

  // ---------- effects ----------
  void _pop(double x, double y, int ci, bool big) {
    final color = ci >= 0 && ci < BubblePalette.base.length
        ? BubblePalette.base[ci]
        : Colors.white;
    final n = soundOn ? (big ? 10 : 7) : (big ? 6 : 4);
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final sp = 60 + _rng.nextDouble() * 180;
      _parts.add(
        _Particle(
          x,
          y,
          math.cos(a) * sp,
          math.sin(a) * sp - 40,
          0.6 + _rng.nextDouble() * 0.3,
          0.9,
          r * (0.18 + _rng.nextDouble() * 0.22),
          color,
        ),
      );
    }
    _rings.add(_Ring(x, y, r * 0.6, r * (big ? 3 : 2), 0.35, color));
  }

  // ---------- resolve ----------
  void _resolve(double ix, double iy) {
    final p = proj!;
    if (p.special == 'bomb') {
      shake = 12;
      final rad = r * 3.2;
      var hit = 0;
      eachFilled((row, c, v) {
        final dx = cellX(row, c) - ix, dy = cellY(row) - iy;
        if (dx * dx + dy * dy <= rad * rad) {
          hit++;
          _pop(cellX(row, c), cellY(row), v, true);
          grid[row][c] = null;
        }
      });
      score += hit * 15;
      combo = hit > 0 ? combo + 1 : 0;
      if (hit > 0) onSfx?.call('bomb');
      _dropFloating();
    } else if (p.special == 'clear') {
      int? target;
      var bd = double.infinity;
      eachFilled((row, c, v) {
        final dx = cellX(row, c) - ix, dy = cellY(row) - iy;
        final d = dx * dx + dy * dy;
        if (d < bd) {
          bd = d;
          target = v;
        }
      });
      var hit = 0;
      if (target != null) {
        eachFilled((row, c, v) {
          if (v == target) {
            hit++;
            _pop(cellX(row, c), cellY(row), v, true);
            grid[row][c] = null;
          }
        });
      }
      score += hit * 15;
      combo = hit > 0 ? combo + 1 : 0;
      if (hit > 0) onSfx?.call('pop');
      _dropFloating();
    } else {
      final cell = _snapCell(ix, iy);
      final row = cell[0], c = cell[1];
      grid[row][c] = p.ci;
      final group = _floodSame(row, c, p.ci);
      if (group.length >= 3) {
        final mult = math.max(1, combo);
        score += group.length * 10 * mult;
        combo += 1;
        for (final g in group) {
          _pop(cellX(g[0], g[1]), cellY(g[0]), p.ci, true);
          grid[g[0]][g[1]] = null;
        }
        onSfx?.call(combo >= 2 ? 'combo' : 'pop');
        _dropFloating();
      } else {
        combo = 0;
        onSfx?.call('snap');
      }
      if (cellY(row) + r > dangerY && filledCount() > 0) {
        _endLose('reach');
      }
    }
    proj = null;
    onSync?.call();
    _checkEnd();
  }

  void _checkEnd() {
    if (finished) return;
    if (filledCount() == 0) {
      _endWin();
      return;
    }
    if (shots <= 0 && proj == null) _endLose('moves');
  }

  void _endWin() {
    if (finished) return;
    finished = true;
    running = false;
    final ratio = shots / maxShots;
    final stars = ratio >= 0.45 ? 3 : (ratio >= 0.18 ? 2 : 1);
    onSfx?.call('win');
    onWin?.call(stars);
  }

  void _endLose(String reason) {
    if (finished) return;
    finished = true;
    running = false;
    onSfx?.call('lose');
    onLose?.call(reason);
  }

  // ---------- loop ----------
  void update(double dt) {
    if (running && proj != null) {
      final p = proj!;
      final dist = math.sqrt(p.vx * p.vx + p.vy * p.vy) * dt;
      final steps = math.max(1, (dist / (r * 0.5)).ceil());
      for (var s = 0; s < steps && proj != null; s++) {
        p.x += (p.vx / steps) * dt;
        p.y += (p.vy / steps) * dt;
        if (p.x < r) {
          p.x = r;
          p.vx = -p.vx;
        } else if (p.x > w - r) {
          p.x = w - r;
          p.vx = -p.vx;
        }
        if (p.y - r <= top) {
          _resolve(p.x, top + r);
          break;
        }
        var hit = false;
        eachFilled((row, c, v) {
          if (hit) return;
          final dx = cellX(row, c) - p.x, dy = cellY(row) - p.y;
          if (dx * dx + dy * dy <= (r * 1.9) * (r * 1.9)) hit = true;
        });
        if (hit) {
          _resolve(p.x, p.y);
          break;
        }
      }
    }
    for (final pt in _parts) {
      pt.life -= dt;
      pt.vy += 520 * dt;
      pt.x += pt.vx * dt;
      pt.y += pt.vy * dt;
    }
    _parts.removeWhere((p) => p.life <= 0);
    for (final ring in _rings) {
      ring.life -= dt;
      ring.r += (ring.max - ring.r) * math.min(1, dt * 10);
    }
    _rings.removeWhere((r) => r.life <= 0);
    if (shake > 0) shake = math.max(0, shake - dt * 50);
  }

  // ---------- rendering ----------
  void render(Canvas canvas) {
    if (!_booted) return;
    canvas.save();
    if (shake > 0) {
      canvas.translate(
        (_rng.nextDouble() - 0.5) * shake,
        (_rng.nextDouble() - 0.5) * shake,
      );
    }

    // Danger line.
    final dash = Paint()
      ..color = const Color(0x59FF5078)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    _dashedLine(canvas, Offset(0, dangerY), Offset(w, dangerY), dash, 6, 8);

    // Grid bubbles.
    eachFilled(
      (row, c, v) => _drawBubble(canvas, cellX(row, c), cellY(row), v, null),
    );

    // Aim guide.
    _drawGuide(canvas);

    // Projectile.
    final p = proj;
    if (p != null) _drawBubble(canvas, p.x, p.y, p.ci, p.special);

    // Shooter base.
    final basePaint = Paint()..color = const Color(0x99FFFFFF);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sx, sy + r * 0.3),
        width: r * 3,
        height: r * 1.9,
      ),
      basePaint,
    );
    if (p == null) {
      if (active == 'bomb') {
        _drawBubble(canvas, sx, sy, 0, 'bomb');
      } else if (active == 'clear') {
        _drawBubble(canvas, sx, sy, 0, 'clear');
      } else {
        _drawBubble(canvas, sx, sy, cur, null);
      }
    }

    // Particles.
    for (final pt in _parts) {
      final paint = Paint()
        ..color = pt.color.withValues(alpha: math.max(0, pt.life / pt.max));
      canvas.drawCircle(Offset(pt.x, pt.y), pt.r, paint);
    }
    // Rings.
    for (final ring in _rings) {
      final paint = Paint()
        ..color = ring.color.withValues(
          alpha: math.max(0, ring.life / 0.35) * 0.6,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(ring.x, ring.y), ring.r, paint);
    }
    canvas.restore();
  }

  void _drawBubble(Canvas canvas, double x, double y, int ci, String? special) {
    if (special == 'bomb') {
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(x, y),
          r,
          [
            const Color(0xFF7A7A8C),
            const Color(0xFF33333F),
            const Color(0xFF1C1C24),
          ],
          [0, 0.6, 1],
          TileMode.clamp,
          null,
          Offset(x - r * 0.35, y - r * 0.4),
          r * 0.1,
        );
      canvas.drawCircle(Offset(x, y), r, paint);
      canvas.drawCircle(
        Offset(x + r * 0.5, y - r * 0.55),
        r * 0.18,
        Paint()..color = const Color(0xFFFFCE3D),
      );
      return;
    }
    if (special == 'clear') {
      final paint = Paint()
        ..shader = ui.Gradient.sweep(
          Offset(x, y),
          const [
            Color(0xFFFF4D8D),
            Color(0xFFFFD23F),
            Color(0xFF3EC8E0),
            Color(0xFF3DDC84),
            Color(0xFF9B6BFF),
            Color(0xFFFF4D8D),
          ],
          [0, 0.2, 0.4, 0.6, 0.8, 1.0],
        );
      canvas.drawCircle(Offset(x, y), r, paint);
      final tp = TextPainter(
        text: TextSpan(
          text: '★',
          style: TextStyle(fontSize: r * 1.3, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
      return;
    }
    final base = BubblePalette.base[ci];
    final lo = BubblePalette.light[ci];
    final dk = BubblePalette.dark[ci];
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(x, y),
        r,
        [lo, base, dk],
        [0, 0.5, 1],
        TileMode.clamp,
        null,
        Offset(x - r * 0.35, y - r * 0.4),
        r * 0.1,
      );
    canvas.drawCircle(Offset(x, y), r - 0.5, paint);
    // Highlight ellipse.
    canvas.save();
    canvas.translate(x - r * 0.32, y - r * 0.36);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.52, height: r * 0.36),
      Paint()..color = const Color(0x8CFFFFFF),
    );
    canvas.restore();
  }

  void _drawGuide(Canvas canvas) {
    if (!aimGuide || proj != null) return;
    final d = aimDir();
    var x = sx, y = sy, dx = d.dx, dy = d.dy;
    final pts = <Offset>[Offset(x, y)];
    var bounces = 0;
    for (var i = 0; i < 600; i++) {
      x += dx * 6;
      y += dy * 6;
      if (x < r) {
        x = r;
        dx = -dx;
        pts.add(Offset(x, y));
        if (++bounces > 3) break;
      } else if (x > w - r) {
        x = w - r;
        dx = -dx;
        pts.add(Offset(x, y));
        if (++bounces > 3) break;
      }
      if (y - r <= top) break;
      var hit = false;
      eachFilled((row, c, v) {
        if (hit) return;
        final ex = cellX(row, c) - x, ey = cellY(row) - y;
        if (ex * ex + ey * ey <= (r * 1.9) * (r * 1.9)) hit = true;
      });
      if (hit) break;
    }
    pts.add(Offset(x, y));

    final line = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < pts.length; i++) {
      _dashedLine(canvas, pts[i - 1], pts[i], line, 2, 12);
    }
    canvas.drawCircle(
      Offset(x, y),
      r * 0.92,
      Paint()
        ..color = BubblePalette.base[cur].withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _dashedLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint,
    double on,
    double off,
  ) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var dist = 0.0;
    while (dist < total) {
      final start = a + dir * dist;
      final end = a + dir * math.min(dist + on, total);
      canvas.drawLine(start, end, paint);
      dist += on + off;
    }
  }
}
