import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/glucose_reading.dart';

/// Colored segment strip showing class-over-time — a CustomPainter port of
/// the mockup's `timeline()` flex-div strip.
class TimelineStrip extends StatelessWidget {
  const TimelineStrip({
    super.key,
    required this.readings,
    required this.window,
    required this.now,
  });

  final List<GlucoseReading> readings; // ascending by timestamp
  final Duration window;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text('Not enough data yet', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ),
      );
    }
    final start = now.subtract(window);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 46,
            child: CustomPaint(
              painter: _TimelinePainter(readings: readings, start: start, span: window),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (k) {
            final t = start.add(window * (k / 4));
            return Text(_formatTick(t, window), style: const TextStyle(fontSize: 10, color: Color(0xFF9AA2AF)));
          }),
        ),
      ],
    );
  }

  static String _formatTick(DateTime t, Duration window) {
    final hours = window.inHours;
    if (hours <= 12) return DateFormat('HH:mm').format(t);
    if (hours <= 48) return '${DateFormat('E').format(t)} ${t.hour.toString().padLeft(2, '0')}h';
    return DateFormat('d/M').format(t);
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({required this.readings, required this.start, required this.span});

  final List<GlucoseReading> readings;
  final DateTime start;
  final Duration span;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEEF1F6));
    final spanMs = span.inMilliseconds.toDouble();
    for (var i = 0; i < readings.length; i++) {
      final x0 = ((readings[i].timestamp.difference(start).inMilliseconds) / spanMs).clamp(0.0, 1.0);
      final x1 = i < readings.length - 1
          ? ((readings[i + 1].timestamp.difference(start).inMilliseconds) / spanMs).clamp(0.0, 1.0)
          : 1.0;
      final left = x0 * size.width;
      final right = (x1 * size.width).clamp(left + 0.5, size.width);
      canvas.drawRect(
        Rect.fromLTRB(left, 0, right, size.height),
        Paint()..color = AppColors.forClass(readings[i].glucoseClass),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.readings != readings || oldDelegate.start != start || oldDelegate.span != span;
  }
}
