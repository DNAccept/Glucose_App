import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../clinical/glucose_model_engine.dart';
import '../clinical/trend_calculator.dart';
import '../models/glucose_reading.dart';
import 'data_providers.dart';
import 'readings_providers.dart';

/// Provider for loading the 400-tree LightGBM model.
final glucoseModelEngineProvider = Provider<GlucoseModelEngine?>((ref) {
  try {
    final file = File('Model/glucose_model.c');
    if (file.existsSync()) {
      final source = file.readAsStringSync();
      return GlucoseModelEngine.fromCSource(source);
    }
  } catch (_) {}
  return null;
});

/// Manages subject-specific Welford calibration state.
class CalibrationNotifier extends StateNotifier<GlucoseCalibration> {
  CalibrationNotifier(this._ref)
      : super(_ref.read(calibrationRepositoryProvider).getCalibration());

  final Ref _ref;

  Future<void> updateBaselineFromReferences() async {
    final repo = _ref.read(calibrationRepositoryProvider);
    state = await repo.updateBaselineFromReferences();
  }

  Future<void> addRawFeatures(List<double> raw) async {
    final calib = state;
    calib.addRawFeatures(raw);
    calib.finish();
    state = calib;
    await _ref.read(calibrationRepositoryProvider).saveCalibration(calib);
  }
}

final glucoseCalibrationProvider =
    StateNotifierProvider<CalibrationNotifier, GlucoseCalibration>((ref) {
  return CalibrationNotifier(ref);
});

/// Computes glucose Rate of Change (RoC in mg/dL/min) and trend arrow over the last 15 minutes.
class GlucoseTrendState {
  const GlucoseTrendState({
    required this.rateOfChange,
    required this.direction,
  });

  final double? rateOfChange;
  final GlucoseTrendDirection direction;

  static const initial = GlucoseTrendState(
    rateOfChange: null,
    direction: GlucoseTrendDirection.unknown,
  );
}

final glucoseTrendProvider = Provider<GlucoseTrendState>((ref) {
  // Watch readings from the last 15 minutes
  final readingsAsync = ref.watch(windowedReadingsProvider);
  return readingsAsync.maybeWhen(
    data: (readings) {
      if (readings.isEmpty) return GlucoseTrendState.initial;

      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(minutes: 15));
      final recent = readings.where((r) => r.timestamp.isAfter(cutoff)).toList();

      final roc = TrendCalculator.calculateRateOfChange(recent);
      final direction = TrendCalculator.getTrendDirection(roc);

      return GlucoseTrendState(
        rateOfChange: roc,
        direction: direction,
      );
    },
    orElse: () => GlucoseTrendState.initial,
  );
});
