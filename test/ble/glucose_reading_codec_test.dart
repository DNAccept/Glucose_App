import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_monitor/ble/glucose_reading_codec.dart';
import 'package:glucose_monitor/core/glucose_class.dart';
import 'package:glucose_monitor/models/glucose_reading.dart';

void main() {
  test('encode/decode round-trips a reading through the BLE wire format', () {
    final original = GlucoseReading(
      timestamp: DateTime(2026, 1, 1),
      mgDl: 132.5,
      glucoseClass: GlucoseClass.normal,
      confidence: 87,
    );

    final bytes = GlucoseReadingCodec.encode(original);
    expect(bytes.length, 4);

    final decoded = GlucoseReadingCodec.decode(bytes, timestamp: original.timestamp);

    expect(decoded, isNotNull);
    expect(decoded!.mgDl, closeTo(132.5, 0.01));
    expect(decoded.glucoseClass, GlucoseClass.normal);
    expect(decoded.confidence, 87);
  });

  test('decode returns null for a truncated payload', () {
    expect(GlucoseReadingCodec.decode([1, 2], timestamp: DateTime.now()), isNull);
  });

  test('decode clamps out-of-range confidence bytes', () {
    // class=2 (high), confidence byte=255 clamped to 100, mgDl bytes -> 2000/10=200.0
    final decoded = GlucoseReadingCodec.decode([2, 255, 0xD0, 0x07], timestamp: DateTime.now());
    expect(decoded!.confidence, 100);
    expect(decoded.glucoseClass, GlucoseClass.high);
    expect(decoded.mgDl, closeTo(200.0, 0.01));
  });
}
