import 'package:flutter/material.dart';

/// The three buckets the wearable's on-device classifier reports.
/// Numeric values are stable — they are the wire format on BLE and the
/// storage format in the database, so do not reorder them.
enum GlucoseClass {
  low(0),
  normal(1),
  high(2);

  const GlucoseClass(this.wireValue);

  final int wireValue;

  static GlucoseClass fromWireValue(int value) {
    return GlucoseClass.values.firstWhere(
      (c) => c.wireValue == value,
      orElse: () => GlucoseClass.normal,
    );
  }

  /// mg/dL classification thresholds used both to interpret the wearable's
  /// class byte sanity-check and to bucket manually entered finger-prick
  /// reference values.
  static const int lowCutMgDl = 70;
  static const int highCutMgDl = 180;

  static GlucoseClass fromMgDl(num mgDl) {
    if (mgDl < lowCutMgDl) return GlucoseClass.low;
    if (mgDl > highCutMgDl) return GlucoseClass.high;
    return GlucoseClass.normal;
  }

  String get label => switch (this) {
        GlucoseClass.low => 'Low',
        GlucoseClass.normal => 'Normal',
        GlucoseClass.high => 'High',
      };

  String get clinicalName => switch (this) {
        GlucoseClass.low => 'Hypoglycaemia',
        GlucoseClass.normal => 'In range',
        GlucoseClass.high => 'Hyperglycaemia',
      };

  IconData get icon => switch (this) {
        GlucoseClass.low => Icons.arrow_downward_rounded,
        GlucoseClass.normal => Icons.check_rounded,
        GlucoseClass.high => Icons.arrow_upward_rounded,
      };
}
