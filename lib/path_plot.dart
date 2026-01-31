 import 'dart:math';
import 'package:flutter/material.dart';

/// نقطة رسم (x,y)
class PlotPoint {
  final double x;
  final double y;
  const PlotPoint(this.x, this.y);
}

/// ===============================
/// PATH RECONSTRUCTION (DATA-based)
/// ===============================
class PathReconstructor {
  static List<PlotPoint> reconstructFromData({
    required List<Map<String, dynamic>> pathPoints,
    int threshold = 2000,
    double speedScale = 0.0028,
    double kTurn = 1.3,
    double maxTurnRate = 3.2,
  }) {
    double x = 0, y = 0;
    double heading = -pi / 2; // للأعلى
    final out = <PlotPoint>[const PlotPoint(0, 0)];

    DateTime? lastTime;

    for (final p in pathPoints) {
      // ===== Read fields safely =====
      final String action =
          (p['action'] ?? 'STOP').toString().toUpperCase();

      final int speed = (p['speed'] is int)
          ? p['speed']
          : int.tryParse('${p['speed']}') ?? 0;

      final String tsStr = (p['timestamp'] ?? '').toString();
      DateTime? t;
      try {
        if (tsStr.isNotEmpty) t = DateTime.parse(tsStr);
      } catch (_) {}

      double dt = 0.1;
      if (t != null && lastTime != null) {
        dt = (t.difference(lastTime!).inMilliseconds / 1000.0);
        if (dt <= 0 || dt > 0.8) dt = 0.1;
      }
      if (t != null) lastTime = t;

      final List sensors =
          (p['sensors'] is List) ? List.from(p['sensors']) : [0, 0, 0, 0, 0];
      if (sensors.length < 5) continue;

      // ===== Sensor interpretation =====
      final b1 = ((sensors[0] as num).toInt() < threshold) ? 1 : 0;
      final b2 = ((sensors[1] as num).toInt() < threshold) ? 1 : 0;
      final b3 = ((sensors[2] as num).toInt() < threshold) ? 1 : 0;
      final b4 = ((sensors[3] as num).toInt() < threshold) ? 1 : 0;
      final b5 = ((sensors[4] as num).toInt() < threshold) ? 1 : 0;

      final sum = b1 + b2 + b3 + b4 + b5;

      double error = 0;

      // ===== Lost line handling =====
      if (sum == 0) {
        if (action.contains('LEFT')) {
          error = -2.0;
        } else if (action.contains('RIGHT')) {
          error = 2.0;
        } else {
          error = 0.0;
        }
      } else {
        // weighted center of line
        error = (b1 * -2 +
                b2 * -1 +
                b3 * 0 +
                b4 * 1 +
                b5 * 2) /
            sum;
      }

      // ===== Turning =====
      double turnRate = kTurn * error;
      turnRate = turnRate.clamp(-maxTurnRate, maxTurnRate);

      heading += turnRate * dt;

      // ===== Forward movement =====
      final step = speed * speedScale * dt * 10;

      if (!action.contains('STOP')) {
        x += cos(heading) * step;
        y += sin(heading) * step;
        out.add(PlotPoint(x, y));
      }
    }

    return out;
  }
}

/// ===============================
/// PATH PAINTER
/// ===============================
class PathPlot extends StatelessWidget {
  final List<PlotPoint> points;
  final Color lineColor;
  final double strokeWidth;

  const PathPlot({
    super.key,
    required this.points,
    this.lineColor = Colors.cyanAccent,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PathPainter(points, lineColor, strokeWidth),
      child: Container(),
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<PlotPoint> pts;
  final Color color;
  final double w;

  _PathPainter(this.pts, this.color, this.w);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;

    final paintLine = Paint()
      ..color = color
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double minX = pts.first.x, maxX = pts.first.x;
    double minY = pts.first.y, maxY = pts.first.y;

    for (final p in pts) {
      minX = min(minX, p.x);
      maxX = max(maxX, p.x);
      minY = min(minY, p.y);
      maxY = max(maxY, p.y);
    }

    final rangeX = (maxX - minX).abs();
    final rangeY = (maxY - minY).abs();
    const pad = 24.0;

    final scaleX = (size.width - pad * 2) / (rangeX == 0 ? 1 : rangeX);
    final scaleY = (size.height - pad * 2) / (rangeY == 0 ? 1 : rangeY);
    final scale = min(scaleX, scaleY);

    final offsetX = pad + (size.width - pad * 2 - rangeX * scale) / 2;
    final offsetY = pad + (size.height - pad * 2 - rangeY * scale) / 2;

    Offset map(PlotPoint p) {
      final dx = offsetX + (p.x - minX) * scale;
      final dy = offsetY + (p.y - minY) * scale;
      return Offset(dx, size.height - dy);
    }

    // Grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    const gridStep = 30.0;
    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()..moveTo(map(pts.first).dx, map(pts.first).dy);
    for (int i = 1; i < pts.length; i++) {
      final o = map(pts[i]);
      path.lineTo(o.dx, o.dy);
    }

    canvas.drawPath(path, paintLine);

    // Start & End points
    canvas.drawCircle(map(pts.first), 6, Paint()..color = Colors.greenAccent);
    canvas.drawCircle(map(pts.last), 6, Paint()..color = Colors.redAccent);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => true;
}