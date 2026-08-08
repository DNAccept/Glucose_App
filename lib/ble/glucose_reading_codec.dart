import 'dart:typed_data';

import '../core/glucose_class.dart';
import '../models/glucose_reading.dart';
import 'ble_contract.dart';

/// Encodes/decodes [GlucoseReading]s to/from the wire format documented in
/// [BleContract]. Shared by [RealBleManager] (decoding real notifications)
/// and [SimulatedBleManager] (round-tripping through the same format keeps
/// the simulator honest about what the real protocol can represent).
class GlucoseReadingCodec {
  GlucoseReadingCodec._();

  static GlucoseReading? decode(List<int> bytes, {required DateTime timestamp}) {
    if (bytes.length < BleContract.expectedReadingPayloadLength) return null;
    final data = Uint8List.fromList(bytes);
    final classByte = data[0];
    final confidence = data[1];
    final tenthsMgDl = data[2] | (data[3] << 8);
    return GlucoseReading(
      timestamp: timestamp,
      mgDl: tenthsMgDl / 10.0,
      glucoseClass: GlucoseClass.fromWireValue(classByte),
      confidence: confidence.clamp(0, 100),
    );
  }

  static List<int> encode(GlucoseReading reading) {
    final tenths = (reading.mgDl * 10).round().clamp(0, 0xFFFF);
    return [
      reading.glucoseClass.wireValue,
      reading.confidence.clamp(0, 100),
      tenths & 0xFF,
      (tenths >> 8) & 0xFF,
    ];
  }
}
