import '../core/glucose_class.dart';

/// Indicates which model produced the glucose reading.
enum ModelOrigin {
  onDevice(0, 'On-Device Wearable'),
  phoneBackground(1, 'Phone Background');

  const ModelOrigin(this.wireValue, this.label);
  final int wireValue;
  final String label;

  static ModelOrigin fromWireValue(int val) {
    return val == 1 ? ModelOrigin.phoneBackground : ModelOrigin.onDevice;
  }
}

/// Bitmask-backed sensor-health status flags received from the wearable.
class SensorHealthFlags {
  const SensorHealthFlags({
    this.motionArtifact = false,
    this.poorSkinContact = false,
    this.lowBattery = false,
    this.sensorFault = false,
  });

  final bool motionArtifact;
  final bool poorSkinContact;
  final bool lowBattery;
  final bool sensorFault;

  static const none = SensorHealthFlags();

  bool get hasAnyIssue => motionArtifact || poorSkinContact || lowBattery || sensorFault;

  int toBitmask() {
    var mask = 0;
    if (motionArtifact) mask |= 0x01;
    if (poorSkinContact) mask |= 0x02;
    if (lowBattery) mask |= 0x04;
    if (sensorFault) mask |= 0x08;
    return mask;
  }

  factory SensorHealthFlags.fromBitmask(int mask) {
    return SensorHealthFlags(
      motionArtifact: (mask & 0x01) != 0,
      poorSkinContact: (mask & 0x02) != 0,
      lowBattery: (mask & 0x04) != 0,
      sensorFault: (mask & 0x08) != 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorHealthFlags &&
          runtimeType == other.runtimeType &&
          motionArtifact == other.motionArtifact &&
          poorSkinContact == other.poorSkinContact &&
          lowBattery == other.lowBattery &&
          sensorFault == other.sensorFault;

  @override
  int get hashCode => Object.hash(motionArtifact, poorSkinContact, lowBattery, sensorFault);

  @override
  String toString() {
    final issues = <String>[];
    if (motionArtifact) issues.add('Motion Artifact');
    if (poorSkinContact) issues.add('Poor Contact');
    if (lowBattery) issues.add('Low Battery');
    if (sensorFault) issues.add('Sensor Fault');
    return issues.isEmpty ? 'OK' : issues.join(', ');
  }
}

/// A single reading received from the wearable: it already carries both the
/// regression estimate (mgDl) and the classification (glucoseClass) plus the
/// classifier's confidence, model origin, and sensor-health flags.
class GlucoseReading {
  const GlucoseReading({
    this.id,
    required this.timestamp,
    required this.mgDl,
    required this.glucoseClass,
    required this.confidence,
    this.flags = SensorHealthFlags.none,
    this.modelOrigin = ModelOrigin.onDevice,
    this.sequenceNumber,
  });

  final int? id;
  final DateTime timestamp;
  final double mgDl;
  final GlucoseClass glucoseClass;

  /// Classifier confidence, 0-100.
  final int confidence;

  /// Sensor health flags (motion artifact, skin contact, low battery, fault).
  final SensorHealthFlags flags;

  /// Model origin (on-device vs. phone background model).
  final ModelOrigin modelOrigin;

  /// Optional packet sequence counter for out-of-order/drop tracking.
  final int? sequenceNumber;

  bool get isLowConfidence => confidence < 50;
  bool get hasMotionArtifact => flags.motionArtifact;
  bool get hasPoorContact => flags.poorSkinContact;
  bool get hasLowBatteryWarning => flags.lowBattery;
  bool get hasSensorFault => flags.sensorFault;

  GlucoseReading copyWith({
    int? id,
    DateTime? timestamp,
    double? mgDl,
    GlucoseClass? glucoseClass,
    int? confidence,
    SensorHealthFlags? flags,
    ModelOrigin? modelOrigin,
    int? sequenceNumber,
  }) {
    return GlucoseReading(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      mgDl: mgDl ?? this.mgDl,
      glucoseClass: glucoseClass ?? this.glucoseClass,
      confidence: confidence ?? this.confidence,
      flags: flags ?? this.flags,
      modelOrigin: modelOrigin ?? this.modelOrigin,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    );
  }
}
