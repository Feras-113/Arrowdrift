import 'package:flutter/material.dart';

/// The Arrowdrift mark: two interlocking snake-arrows on a night-blue badge.
/// Geometry is in unit coordinates and mirrored 1:1 by tool/make_icons.py so
/// the in-app logo and the store/launcher icons are identical.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 120, this.badge = true});

  final double size;

  /// Draw the rounded gradient badge behind the arrows.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: LogoPainter(badge: badge)),
    );
  }
}

class LogoPainter extends CustomPainter {
  const LogoPainter({this.badge = true});

  final bool badge;

  static const Color mint = Color(0xFF2EF2C9);
  static const Color coral = Color(0xFFFF6B8A);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    Offset p(double x, double y) => Offset(x * s, y * s);

    if (badge) {
      final rect = Offset.zero & Size(s, s);
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22));
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1030), Color(0xFF26379A)],
          ).createShader(rect),
      );
      canvas.drawRRect(
        rr.deflate(s * 0.012),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012
          ..color = Colors.white.withValues(alpha: 0.12),
      );
    }

    _snake(canvas, s, coral, [p(0.42, 0.80), p(0.78, 0.80), p(0.78, 0.60)], 0.44);
    _snake(
      canvas,
      s,
      mint,
      [p(0.24, 0.76), p(0.24, 0.46), p(0.58, 0.46), p(0.58, 0.34)],
      0.18,
    );
  }

  /// Draws a snake polyline whose head points straight up and ends at [tipY].
  void _snake(Canvas canvas, double s, Color color, List<Offset> pts, double tipY) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    final w = s * 0.10;
    Paint stroke(Color c, double width) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(0, s * 0.012);
    canvas.drawPath(path, stroke(Colors.black.withValues(alpha: 0.3), w));
    canvas.restore();
    canvas.drawPath(path, stroke(color, w));
    canvas.drawPath(
      path,
      stroke(Color.lerp(color, Colors.white, 0.5)!.withValues(alpha: 0.7), w * 0.3),
    );

    final end = pts.last;
    final head = Path()
      ..moveTo(end.dx, tipY * s)
      ..lineTo(end.dx + s * 0.12, end.dy)
      ..lineTo(end.dx - s * 0.12, end.dy)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  @override
  bool shouldRepaint(LogoPainter oldDelegate) => oldDelegate.badge != badge;
}
