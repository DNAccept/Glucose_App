import '../core/glucose_class.dart';

/// A manually logged finger-prick value, compared against whatever the
/// device reported at the time it was entered.
class ReferenceReading {
  const ReferenceReading({
    this.id,
    required this.referenceValueMgDl,
    required this.referenceClass,
    this.deviceMgDl,
    this.deviceClass,
    this.deviceConfidence,
    required this.timestamp,
  });

  final int? id;
  final int referenceValueMgDl;
  final GlucoseClass referenceClass;
  final double? deviceMgDl;
  final GlucoseClass? deviceClass;
  final int? deviceConfidence;
  final DateTime timestamp;

  bool get hasDeviceReading => deviceClass != null;
  bool get classesAgree => hasDeviceReading && deviceClass == referenceClass;
}
