import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/glucose_reading.dart';
import 'ble_contract.dart';
import 'ble_manager.dart';
import 'glucose_reading_codec.dart';

/// Talks to the real wearable over BLE using the contract in
/// [BleContract]. This is the only place that should need to change once
/// real firmware UUIDs/byte layout are finalized.
class RealBleManager implements BleManager {
  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _readingsController = StreamController<GlucoseReading>.broadcast();
  final _batteryController = StreamController<int>.broadcast();
  final _discoveredController = StreamController<List<DiscoveredDevice>>.broadcast();

  BluetoothDevice? _device;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _readingSub;
  StreamSubscription<List<int>>? _batterySub;

  @override
  Stream<BleConnectionState> get connectionState => _connectionStateController.stream;
  @override
  Stream<GlucoseReading> get readings => _readingsController.stream;
  @override
  Stream<int> get batteryLevel => _batteryController.stream;
  @override
  Stream<List<DiscoveredDevice>> get discoveredDevices => _discoveredController.stream;

  @override
  Future<void> startScan() async {
    _connectionStateController.add(BleConnectionState.scanning);
    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      _discoveredController.add(results
          .map((r) => DiscoveredDevice(
                id: r.device.remoteId.str,
                name: r.device.platformName.isNotEmpty ? r.device.platformName : r.advertisementData.advName,
                rssi: r.rssi,
              ))
          .where((d) => d.name.isNotEmpty)
          .toList());
    });
    await FlutterBluePlus.startScan(
      withServices: [Guid(BleContract.serviceUuid)],
      timeout: const Duration(seconds: 12),
    );
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    _connectionStateController.add(BleConnectionState.disconnected);
  }

  @override
  Future<void> connect(String deviceId) async {
    await stopScan();
    _connectionStateController.add(BleConnectionState.connecting);
    final device = BluetoothDevice.fromId(deviceId);
    _device = device;

    await _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((s) {
      _connectionStateController.add(
        s == BluetoothConnectionState.connected
            ? BleConnectionState.connected
            : BleConnectionState.disconnected,
      );
    });

    await device.connect(timeout: const Duration(seconds: 15));
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid.str128 == BleContract.serviceUuid) {
        for (final char in service.characteristics) {
          if (char.uuid.str128 == BleContract.readingCharacteristicUuid) {
            await char.setNotifyValue(true);
            await _readingSub?.cancel();
            _readingSub = char.onValueReceived.listen((bytes) {
              final reading = GlucoseReadingCodec.decode(bytes, timestamp: DateTime.now());
              if (reading != null) _readingsController.add(reading);
            });
          }
        }
      }
      if (service.uuid.str128 == BleContract.batteryServiceUuid) {
        for (final char in service.characteristics) {
          if (char.uuid.str128 == BleContract.batteryLevelCharacteristicUuid) {
            await char.setNotifyValue(true);
            await _batterySub?.cancel();
            _batterySub = char.onValueReceived.listen((bytes) {
              if (bytes.isNotEmpty) _batteryController.add(bytes.first);
            });
          }
        }
      }
    }
  }

  @override
  Future<void> disconnect() async {
    await _device?.disconnect();
    await _readingSub?.cancel();
    await _batterySub?.cancel();
    _connectionStateController.add(BleConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await _scanSub?.cancel();
    await _connectionSub?.cancel();
    await _readingSub?.cancel();
    await _batterySub?.cancel();
    await _connectionStateController.close();
    await _readingsController.close();
    await _batteryController.close();
    await _discoveredController.close();
  }
}
