/// Placeholder BLE GATT contract for the glucose wearable.
///
/// No firmware/hardware spec exists yet, so these UUIDs and the byte layout
/// below are provisional. When the real firmware contract is available,
/// this is the only file that should need to change — [RealBleManager]
/// reads exclusively through these constants and [GlucoseReadingCodec].
library;

class BleContract {
  BleContract._();

  /// Custom service advertised by the wearable.
  static const String serviceUuid = '0000a000-0000-1000-8000-00805f9b34fb';

  /// Notify characteristic carrying one reading per notification.
  /// Payload (4 bytes, little-endian):
  ///   byte 0     : class      (0 = low, 1 = normal, 2 = high)
  ///   byte 1     : confidence (0-100)
  ///   bytes 2..3 : mgDl estimate, uint16 LE (tenths of mg/dL, so 1325 = 132.5 mg/dL)
  static const String readingCharacteristicUuid =
      '0000a001-0000-1000-8000-00805f9b34fb';

  /// Standard BLE Battery Service / Level characteristic — used as-is if the
  /// wearable implements it, since it's a well-known GATT profile rather
  /// than something we need to invent.
  static const String batteryServiceUuid = '0000180f-0000-1000-8000-00805f9b34fb';
  static const String batteryLevelCharacteristicUuid =
      '00002a19-0000-1000-8000-00805f9b34fb';

  static const int expectedReadingPayloadLength = 4;
}
