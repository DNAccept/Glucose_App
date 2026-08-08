import 'package:flutter/material.dart';

import '../../core/glucose_class.dart';
import '../../core/theme.dart';
import '../../models/glucose_reading.dart';

/// Numeric mg/dL trend line with shaded low/normal/high bands at the
/// classification thresholds. This is new relative to the mockup — the
/// mockup only ever showed discrete class segments because its prototype
/// data had no regression output; the real wearable does, so the trend is
/// worth showing as an actual line.
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.readings,
    required this.window,
    required this.now,
    this.height = 160,
  });

  final List<GlucoseReading> readings; // ascending by timestamp
  final Duration window;
  final DateTime now;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (readings.length < 2) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Not enough data yet', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ),
      );
    }
    final start = now.subtract(window);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(readings: readings, start: start, span: window),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.readings, required this.start, required this.span});

  final List<GlucoseReading> readings;
  final DateTime start;
  final Duration span;

  static const double _axisMin = 40;
  static const double _axisMax = 260;

  double _yFor(double mgDl, double height) {
    final t = ((mgDl - _axisMin) / (_axisMax - _axisMin)).clamp(0.0, 1.0);
    return height - t * height;
  }

  double _xFor(DateTime t, double width) {
    final frac = (t.difference(start).inMilliseconds / span.inMilliseconds).clamp(0.0, 1.0);
    return frac * width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final lowY = _yFor(GlucoseClass.lowCutMgDl.toDouble(), size.height);
    final highY = _yFor(GlucoseClass.highCutMgDl.toDouble(), size.height);

    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, highY), Paint()..color = AppColors.high.withValues(alpha: 0.08));
    canvas.drawRect(Rect.fromLTRB(0, highY, size.width, lowY), Paint()..color = AppColors.normal.withValues(alpha: 0.06));
    canvas.drawRect(Rect.fromLTRB(0, lowY, size.width, size.height), Paint()..color = AppColors.low.withValues(alpha: 0.08));

    final dashPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    _drawDashedLine(canvas, Offset(0, lowY), Offset(size.width, lowY), dashPaint);
    _drawDashedLine(canvas, Offset(0, highY), Offset(size.width, highY), dashPaint);

    final path = Path();
    for (var i = 0; i < readings.length; i++) {
      final x = _xFor(readings[i].timestamp, size.width);
      final y = _yFor(readings[i].mgDl, size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final last = readings.last;
    canvas.drawCircle(
      Offset(_xFor(last.timestamp, size.width), _yFor(last.mgDl, size.height)),
      4,
      Paint()..color = AppColors.forClass(last.glucoseClass),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashWidth = 5.0, gapWidth = 4.0;
    final total = (b - a).distance;
    final direction = (b - a) / total;
    var covered = 0.0;
    while (covered < total) {
      final start = a + direction * covered;
      final end = a + direction * (covered + dashWidth).clamp(0, total);
      canvas.drawLine(start, end, paint);
      covered += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.readings != readings || oldDelegate.start != start || oldDelegate.span != span;
  }
}
