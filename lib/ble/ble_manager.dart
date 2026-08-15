import '../models/glucose_reading.dart';

enum BleConnectionState { disconnected, scanning, connecting, connected }

class DiscoveredDevice {
  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  final String id;
  final String name;
  final int rssi;
}

/// Abstraction over "however we talk to the wearable". UI code depends only
/// on this interface, never on [RealBleManager] or [SimulatedBleManager]
/// directly, so the data source can be swapped (or a real GATT contract
/// dropped in later) without touching a single screen.
abstract class BleManager {
  Stream<BleConnectionState> get connectionState;
  BleConnectionState get currentConnectionState;

  Stream<GlucoseReading> get readings;

  Stream<int> get batteryLevel;
  int? get currentBatteryLevel;

  Stream<List<DiscoveredDevice>> get discoveredDevices;
  List<DiscoveredDevice> get currentDiscoveredDevices;

  Stream<DiscoveredDevice?> get connectedDevice;
  DiscoveredDevice? get currentDevice;

  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(String deviceId);
  Future<void> disconnect();

  Future<void> dispose();
}
