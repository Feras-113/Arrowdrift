import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../game/board.dart';
import '../theme/palette.dart';

/// Maps between board cells and canvas pixels for a given widget size.
class BoardGeometry {
  BoardGeometry(Size size, this.cols, this.rows)
      : cell = math.min(size.width / cols, size.height / rows) {
    ox = (size.width - cell * cols) / 2;
    oy = (size.height - cell * rows) / 2;
  }

  final int cols;
  final int rows;
  final double cell;
  late final double ox;
  late final double oy;

  Offset center(int index) {
    final x = index % cols;
    final y = index ~/ cols;
    return Offset(ox + (x + 0.5) * cell, oy + (y + 0.5) * cell);
  }

  /// Grid coordinates under [p], or null when outside the board.
  ({int x, int y})? cellAt(Offset p) {
    final x = ((p.dx - ox) / cell).floor();
    final y = ((p.dy - oy) / cell).floor();
    if (x < 0 || y < 0 || x >= cols || y >= rows) return null;
    return (x: x, y: y);
  }
}

/// Transient visual state: sliding arrows, "blocked" shakes and the hint glow.
class BoardAnimations {
  static const int exitMs = 340;
  static const int flashMs = 480;

  final Stopwatch _watch = clock.stopwatch()..start();
  final Map<int, int> exiting = <int, int>{};
  final Map<int, int> flashing = <int, int>{};
  final Map<int, int> blockers = <int, int>{};
  int? hintId;
  int hintStart = 0;

  int get now => _watch.elapsedMilliseconds;

  bool get busy =>
      exiting.isNotEmpty ||
      flashing.isNotEmpty ||
      blockers.isNotEmpty ||
      hintId != null;

  void startExit(int id) => exiting[id] = now;

  void startFlash(int id, int? blocker) {
    flashing[id] = now;
    if (blocker != null) blockers[blocker] = now;
  }

  void showHint(int id) {
    hintId = id;
    hintStart = now;
  }

  void clearHint() => hintId = null;

  void cancel(int id) {
    exiting.remove(id);
    flashing.remove(id);
    blockers.remove(id);
    if (hintId == id) hintId = null;
  }

  void clear() {
    exiting.clear();
    flashing.clear();
    blockers.clear();
    hintId = null;
  }

  /// Drops finished animations.
  void prune() {
    final t = now;
    exiting.removeWhere((_, s) => t - s >= exitMs);
    flashing.removeWhere((_, s) => t - s >= flashMs);
    blockers.removeWhere((_, s) => t - s >= flashMs);
    if (hintId != null && t - hintStart > 4000) hintId = null;
  }
}

class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.board,
    required this.anim,
    required this.pal,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final Board board;
  final BoardAnimations anim;
  final AppPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final g = BoardGeometry(size, board.width, board.height);
    final now = anim.now;

    // Grid dots.
    final dot = Paint()..color = pal.dot.withValues(alpha: 0.55);
    for (var y = 0; y < board.height; y++) {
      for (var x = 0; x < board.width; x++) {
        canvas.drawCircle(
          Offset(g.ox + (x + 0.5) * g.cell, g.oy + (y + 0.5) * g.cell),
          g.cell * 0.055,
          dot,
        );
      }
    }

    // Live arrows (with flash / hint / blocker effects).
    for (final a in board.arrows) {
      if (!board.isAlive(a.id)) continue;
      var shift = Offset.zero;
      var color = pal.arrowColor(a.id);
      double glow = 0;
      Color glowColor = pal.accent;

      final fs = anim.flashing[a.id];
      if (fs != null) {
        final t = ((now - fs) / BoardAnimations.flashMs).clamp(0.0, 1.0);
        shift = Offset(math.sin(t * math.pi * 7) * g.cell * 0.14 * (1 - t), 0);
        color = Color.lerp(color, pal.danger, 1 - t)!;
      }
      final bs = anim.blockers[a.id];
      if (bs != null) {
        final t = ((now - bs) / BoardAnimations.flashMs).clamp(0.0, 1.0);
        glow = 1 - t;
        glowColor = pal.danger;
      }
      if (anim.hintId == a.id) {
        final pulse = 0.5 + 0.5 * math.sin((now - anim.hintStart) / 160);
        glow = 0.45 + 0.55 * pulse;
        glowColor = pal.accent;
      }
      _drawArrow(canvas, g, a, color, shift: shift, glow: glow, glowColor: glowColor);
    }

    // Arrows sliding off the board.
    anim.exiting.forEach((id, start) {
      final a = board.arrows[id];
      final t = ((now - start) / BoardAnimations.exitMs).clamp(0.0, 1.0);
      final eased = Curves.easeInCubic.transform(t);
      final travel = (board.cellsToEdge(a) + a.length + 1) * g.cell * eased;
      final shift = Offset(a.dir.dx * travel, a.dir.dy * travel);
      _drawArrow(
        canvas,
        g,
        a,
        pal.arrowColor(a.id),
        shift: shift,
        alpha: 1 - 0.6 * t,
      );
    });
  }

  void _drawArrow(
    Canvas canvas,
    BoardGeometry g,
    Arrow a,
    Color color, {
    Offset shift = Offset.zero,
    double alpha = 1,
    double glow = 0,
    Color glowColor = Colors.white,
  }) {
    final pts = <Offset>[for (final c in a.cells) g.center(c) + shift];
    final w = g.cell * 0.34;

    Paint stroke(Color c, double width, {MaskFilter? blur}) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = blur;

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) {
      path.lineTo(pts.first.dx + 0.01, pts.first.dy);
    }
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final dir = Offset(a.dir.dx.toDouble(), a.dir.dy.toDouble());
    final perp = Offset(-dir.dy, dir.dx);
    final hc = pts.last;
    final headPath = Path()
      ..moveTo(hc.dx + dir.dx * g.cell * 0.47, hc.dy + dir.dy * g.cell * 0.47)
      ..lineTo(hc.dx + perp.dx * g.cell * 0.34, hc.dy + perp.dy * g.cell * 0.34)
      ..lineTo(hc.dx - perp.dx * g.cell * 0.34, hc.dy - perp.dy * g.cell * 0.34)
      ..close();

    if (glow > 0) {
      final blur = MaskFilter.blur(BlurStyle.normal, g.cell * 0.22);
      canvas.drawPath(
        path,
        stroke(glowColor.withValues(alpha: 0.75 * glow), w * 2.1, blur: blur),
      );
      canvas.drawPath(
        headPath,
        Paint()
          ..color = glowColor.withValues(alpha: 0.75 * glow)
          ..maskFilter = blur,
      );
    }

    // Soft drop shadow.
    canvas.save();
    canvas.translate(0, g.cell * 0.06);
    final shadow = Colors.black.withValues(alpha: 0.28 * alpha);
    canvas.drawPath(path, stroke(shadow, w));
    canvas.drawPath(headPath, Paint()..color = shadow);
    canvas.restore();

    // Body, head and a thin highlight for a "tube" look.
    final body = color.withValues(alpha: alpha);
    canvas.drawPath(path, stroke(body, w));
    canvas.drawPath(headPath, Paint()..color = body);
    canvas.drawPath(
      path,
      stroke(
        Color.lerp(color, Colors.white, 0.5)!.withValues(alpha: 0.55 * alpha),
        w * 0.28,
      ),
    );
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => true;
}
