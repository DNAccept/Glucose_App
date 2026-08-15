import 'dart:typed_data';

import '../core/glucose_class.dart';
import '../models/glucose_reading.dart';
import 'ble_contract.dart';

/// Encodes/decodes [GlucoseReading]s to/from the wire format documented in
/// [BleContract]. Shared by [RealBleManager] (decoding real notifications)
/// and [SimulatedBleManager] (round-tripping through the same format keeps
/// the simulator honest about what the real protocol can represent).
///
/// Supports both:
/// - Standard 4-byte payload (class, confidence, mg/dL estimate)
/// - Extended 8-byte payload (+ sensor flags, model origin, sequence counter)
class GlucoseReadingCodec {
  GlucoseReadingCodec._();

  /// Decodes raw BLE notification bytes into a [GlucoseReading].
  /// Returns null if the byte array is null, empty, or shorter than
  /// [BleContract.expectedReadingPayloadLength].
  static GlucoseReading? decode(List<int>? bytes, {required DateTime timestamp}) {
    if (bytes == null || bytes.length < BleContract.expectedReadingPayloadLength) {
      return null;
    }

    try {
      final data = Uint8List.fromList(bytes);
      final classByte = data[0];
      final confidence = data[1];
      final tenthsMgDl = data[2] | (data[3] << 8);

      SensorHealthFlags flags = SensorHealthFlags.none;
      ModelOrigin modelOrigin = ModelOrigin.onDevice;
      int? sequenceNumber;

      if (data.length >= BleContract.extendedReadingPayloadLength) {
        flags = SensorHealthFlags.fromBitmask(data[4]);
        modelOrigin = ModelOrigin.fromWireValue(data[5]);
        sequenceNumber = data[6] | (data[7] << 8);
      }

      return GlucoseReading(
        timestamp: timestamp,
        mgDl: tenthsMgDl / 10.0,
        glucoseClass: GlucoseClass.fromWireValue(classByte),
        confidence: confidence.clamp(0, 100),
        flags: flags,
        modelOrigin: modelOrigin,
        sequenceNumber: sequenceNumber,
      );
    } catch (_) {
      // Gracefully handle any corrupt or unexpected byte sequence
      return null;
    }
  }

  /// Encodes reading into the standard 4-byte payload format.
  static List<int> encode(GlucoseReading reading) {
    final tenths = (reading.mgDl * 10).round().clamp(0, 0xFFFF);
    return [
      reading.glucoseClass.wireValue,
      reading.confidence.clamp(0, 100),
      tenths & 0xFF,
      (tenths >> 8) & 0xFF,
    ];
  }

  /// Encodes reading into the extended 8-byte payload format.
  static List<int> encodeExtended(GlucoseReading reading) {
    final tenths = (reading.mgDl * 10).round().clamp(0, 0xFFFF);
    final seq = (reading.sequenceNumber ?? 0) & 0xFFFF;
    return [
      reading.glucoseClass.wireValue,
      reading.confidence.clamp(0, 100),
      tenths & 0xFF,
      (tenths >> 8) & 0xFF,
      reading.flags.toBitmask(),
      reading.modelOrigin.wireValue,
      seq & 0xFF,
      (seq >> 8) & 0xFF,
    ];
  }

  /// Automatically picks the 8-byte format if flags, modelOrigin or sequenceNumber
  /// are customized, otherwise uses 4-byte format.
  static List<int> encodeAuto(GlucoseReading reading) {
    if (reading.flags.hasAnyIssue ||
        reading.modelOrigin != ModelOrigin.onDevice ||
        reading.sequenceNumber != null) {
      return encodeExtended(reading);
    }
    return encode(reading);
  }
}
