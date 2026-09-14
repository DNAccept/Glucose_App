import 'dart:math' as math;

import '../models/glucose_reading.dart';

/// Clinical trend directions matching continuous glucose monitor (CGM) standard symbols.
enum GlucoseTrendDirection {
  risingFast('⇈', 'Rising Fast (>2.0 mg/dL/min)'),
  rising('↗', 'Rising (1.0 to 2.0 mg/dL/min)'),
  stable('➔', 'Stable (-1.0 to 1.0 mg/dL/min)'),
  falling('↘', 'Falling (-1.0 to -2.0 mg/dL/min)'),
  fallingFast('⇊', 'Falling Fast (<-2.0 mg/dL/min)'),
  unknown('—', 'Calculating Trend');

  const GlucoseTrendDirection(this.symbol, this.description);
  final String symbol;
  final String description;
}

/// Clinical velocity and trend calculator over windowed glucose reading streams.
class TrendCalculator {
  TrendCalculator._();

  /// Calculates Rate of Change (RoC in mg/dL per minute) using linear regression
  /// over the provided window of glucose readings.
  static double? calculateRateOfChange(List<GlucoseReading> readings) {
    if (readings.length < 2) return null;

    // Sort readings by timestamp ascending
    final sorted = List<GlucoseReading>.from(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final t0 = sorted.first.timestamp;
    final n = sorted.length;

    var sumX = 0.0;
    var sumY = 0.0;
    var sumXY = 0.0;
    var sumXX = 0.0;

    for (final r in sorted) {
      // Time x in minutes relative to first reading
      final x = r.timestamp.difference(t0).inMilliseconds / 60000.0;
      final y = r.mgDl;

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    final denominator = (n * sumXX - sumX * sumX);
    if (denominator.abs() < 1e-6) return 0.0;

    // Slope m in mg/dL per minute
    final slope = (n * sumXY - sumX * sumY) / denominator;
    return slope;
  }

  /// Maps a Rate of Change (mg/dL/min) value to a clinical [GlucoseTrendDirection].
  static GlucoseTrendDirection getTrendDirection(double? rateOfChangeMgDlPerMin) {
    if (rateOfChangeMgDlPerMin == null || rateOfChangeMgDlPerMin.isNaN) {
      return GlucoseTrendDirection.unknown;
    }

    if (rateOfChangeMgDlPerMin > 2.0) {
      return GlucoseTrendDirection.risingFast;
    } else if (rateOfChangeMgDlPerMin > 1.0) {
      return GlucoseTrendDirection.rising;
    } else if (rateOfChangeMgDlPerMin >= -1.0) {
      return GlucoseTrendDirection.stable;
    } else if (rateOfChangeMgDlPerMin >= -2.0) {
      return GlucoseTrendDirection.falling;
    } else {
      return GlucoseTrendDirection.fallingFast;
    }
  }

  /// Formats rate of change into a user-friendly string (e.g. "+1.8 mg/dL/min").
  static String formatRateOfChange(double? roc) {
    if (roc == null || roc.isNaN) return '— mg/dL/min';
    final sign = roc > 0 ? '+' : '';
    return '$sign${roc.toStringAsFixed(1)} mg/dL/min';
  }
}
