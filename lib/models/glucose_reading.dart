import '../core/glucose_class.dart';

/// A single reading received from the wearable: it already carries both the
/// regression estimate (mgDl) and the classification (glucoseClass) plus the
/// classifier's confidence — the phone does not run any inference itself.
class GlucoseReading {
  const GlucoseReading({
    this.id,
    required this.timestamp,
    required this.mgDl,
    required this.glucoseClass,
    required this.confidence,
  });

  final int? id;
  final DateTime timestamp;
  final double mgDl;
  final GlucoseClass glucoseClass;

  /// Classifier confidence, 0-100.
  final int confidence;

  bool get isLowConfidence => confidence < 50;
}
