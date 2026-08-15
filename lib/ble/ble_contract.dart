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
  /// Standard Payload (4 bytes, little-endian):
  ///   byte 0     : class      (0 = low, 1 = normal, 2 = high)
  ///   byte 1     : confidence (0-100)
  ///   bytes 2..3 : mgDl estimate, uint16 LE (tenths of mg/dL, so 1325 = 132.5 mg/dL)
  ///
  /// Extended Payload (8 bytes, little-endian):
  ///   byte 0     : class      (0 = low, 1 = normal, 2 = high)
  ///   byte 1     : confidence (0-100)
  ///   bytes 2..3 : mgDl estimate, uint16 LE (tenths of mg/dL)
  ///   byte 4     : sensor-health flags (bitmask: 0x01 motion, 0x02 poor contact, 0x04 low batt, 0x08 fault)
  ///   byte 5     : model origin (0 = onDevice, 1 = phoneBackground)
  ///   bytes 6..7 : sequence number / packet counter (uint16 LE)
  static const String readingCharacteristicUuid =
      '0000a001-0000-1000-8000-00805f9b34fb';

  /// Session ID & Heartbeat characteristic (Notify + Read).
  /// Carries a 4-byte unique session identifier and live heartbeat pings.
  static const String sessionCharacteristicUuid =
      '0000a002-0000-1000-8000-00805f9b34fb';

  /// Standard BLE Battery Service / Level characteristic — used as-is if the
  /// wearable implements it, since it's a well-known GATT profile rather
  /// than something we need to invent.
  static const String batteryServiceUuid = '0000180f-0000-1000-8000-00805f9b34fb';
  static const String batteryLevelCharacteristicUuid =
      '00002a19-0000-1000-8000-00805f9b34fb';

  static const int expectedReadingPayloadLength = 4;
  static const int extendedReadingPayloadLength = 8;

  // Sensor health flag bitmasks (byte 4 of extended payload)
  static const int flagMotionArtifact = 0x01;
  static const int flagPoorSkinContact = 0x02;
  static const int flagLowBattery = 0x04;
  static const int flagSensorFault = 0x08;

  // Model origin codes (byte 5 of extended payload)
  static const int modelOnDevice = 0x00;
  static const int modelPhoneBackground = 0x01;
}
