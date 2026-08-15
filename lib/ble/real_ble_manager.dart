import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/glucose_reading.dart';
import 'ble_contract.dart';
import 'ble_manager.dart';
import 'glucose_reading_codec.dart';

/// Talks to the real wearable over BLE using the contract in [BleContract].
class RealBleManager implements BleManager {
  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _readingsController = StreamController<GlucoseReading>.broadcast();
  final _batteryController = StreamController<int>.broadcast();
  final _discoveredController = StreamController<List<DiscoveredDevice>>.broadcast();
  final _connectedDeviceController = StreamController<DiscoveredDevice?>.broadcast();

  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BluetoothDevice? _device;
  DiscoveredDevice? _currentDevice;
  int? _currentBatteryLevel;
  int? _activeSessionId;
  DateTime? _lastPacketAt;
  BluetoothCharacteristic? _activeReadingChar;
  List<DiscoveredDevice> _discoveredDevices = [];

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<OnConnectionStateChangedEvent>? _globalConnSub;
  StreamSubscription<List<int>>? _readingSub;
  StreamSubscription<List<int>>? _sessionSub;
  StreamSubscription<List<int>>? _batterySub;
  Timer? _sessionWatchdogTimer;

  @override
  Stream<BleConnectionState> get connectionState => _connectionStateController.stream;
  @override
  BleConnectionState get currentConnectionState => _connectionState;

  @override
  Stream<GlucoseReading> get readings => _readingsController.stream;

  @override
  Stream<int> get batteryLevel => _batteryController.stream;
  @override
  int? get currentBatteryLevel => _currentBatteryLevel;

  @override
  Stream<List<DiscoveredDevice>> get discoveredDevices => _discoveredController.stream;
  @override
  List<DiscoveredDevice> get currentDiscoveredDevices => List.unmodifiable(_discoveredDevices);

  @override
  Stream<DiscoveredDevice?> get connectedDevice => _connectedDeviceController.stream;
  @override
  DiscoveredDevice? get currentDevice => _currentDevice;

  void _setConnectionState(BleConnectionState state) {
    _connectionState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  void _handleDisconnect() {
    _sessionWatchdogTimer?.cancel();
    _sessionWatchdogTimer = null;
    _readingSub?.cancel();
    _readingSub = null;
    _sessionSub?.cancel();
    _sessionSub = null;
    _batterySub?.cancel();
    _batterySub = null;
    _connectionSub?.cancel();
    _connectionSub = null;
    _globalConnSub?.cancel();
    _globalConnSub = null;

    final wasConnectedOrConnecting = _connectionState == BleConnectionState.connected ||
        _connectionState == BleConnectionState.connecting;

    _device = null;
    _currentDevice = null;
    _currentBatteryLevel = null;
    _activeSessionId = null;
    _activeReadingChar = null;
    _lastPacketAt = null;
    _discoveredDevices = [];

    if (!_connectedDeviceController.isClosed) {
      _connectedDeviceController.add(null);
    }
    if (!_discoveredController.isClosed) {
      _discoveredController.add([]);
    }

    if (wasConnectedOrConnecting || _connectionState != BleConnectionState.disconnected) {
      _setConnectionState(BleConnectionState.disconnected);
    }
  }

  @override
  Future<void> startScan() async {
    _setConnectionState(BleConnectionState.scanning);
    _discoveredDevices = [];
    if (!_discoveredController.isClosed) {
      _discoveredController.add([]);
    }

    await _scanSub?.cancel();
    await _isScanningSub?.cancel();

    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    final seen = <String, DiscoveredDevice>{};

    _isScanningSub = FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning && _device == null && _currentDevice == null) {
        _setConnectionState(BleConnectionState.disconnected);
      }
    });

    // Listen to active over-the-air BLE advertisement broadcasts
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final rawName = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName;

        final hasGlucoseService = r.advertisementData.serviceUuids.any((u) {
          final s = u.str128.toLowerCase();
          final sStr = u.toString().toLowerCase();
          return s == BleContract.serviceUuid.toLowerCase() ||
              s.contains('a000') ||
              sStr.contains('a000') ||
              u == Guid(BleContract.serviceUuid) ||
              u == Guid('a000');
        });

        String displayName = rawName;
        if (hasGlucoseService) {
          displayName = rawName.isNotEmpty
              ? '⭐ Glucose Wearable ($rawName)'
              : '⭐ Glucose Wearable';
        } else if (rawName.toLowerCase().contains('glucose') ||
            rawName.toLowerCase().contains('wearable') ||
            rawName.toLowerCase().contains('dna')) {
          displayName = '⭐ $rawName';
        } else if (displayName.isEmpty) {
          final idShort = r.device.remoteId.str.length > 5
              ? r.device.remoteId.str.substring(0, 5)
              : r.device.remoteId.str;
          displayName = 'BLE Device ($idShort)';
        }

        seen[r.device.remoteId.str] = DiscoveredDevice(
          id: r.device.remoteId.str,
          name: displayName,
          rssi: r.rssi,
        );
      }

      // Sort matching/starred devices to the top
      final list = seen.values.toList()
        ..sort((a, b) {
          final aMatch = a.name.startsWith('⭐');
          final bMatch = b.name.startsWith('⭐');
          if (aMatch && !bMatch) return -1;
          if (!aMatch && bMatch) return 1;
          return b.rssi.compareTo(a.rssi);
        });

      _discoveredDevices = list;
      if (!_discoveredController.isClosed) {
        _discoveredController.add(list);
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );
    } catch (_) {}
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    await _isScanningSub?.cancel();
    _isScanningSub = null;
    if (_device == null) {
      _setConnectionState(BleConnectionState.disconnected);
    }
  }

  @override
  Future<void> connect(String deviceId) async {
    await stopScan();
    _setConnectionState(BleConnectionState.connecting);

    final device = BluetoothDevice.fromId(deviceId);
    _device = device;
    _currentDevice = DiscoveredDevice(
      id: deviceId,
      name: device.platformName.isNotEmpty ? device.platformName : 'Glucose Wearable',
      rssi: 0,
    );
    if (!_connectedDeviceController.isClosed) {
      _connectedDeviceController.add(_currentDevice);
    }

    await _connectionSub?.cancel();
    await _globalConnSub?.cancel();
    _sessionWatchdogTimer?.cancel();

    _connectionSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.connected) {
        _setConnectionState(BleConnectionState.connected);
      } else if (s == BluetoothConnectionState.disconnected) {
        _handleDisconnect();
      }
    });

    _globalConnSub = FlutterBluePlus.events.onConnectionStateChanged.listen((event) {
      if (event.device.remoteId == device.remoteId &&
          event.connectionState == BluetoothConnectionState.disconnected) {
        _handleDisconnect();
      }
    });

    try {
      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 20),
      );
      _setConnectionState(BleConnectionState.connected);
      _lastPacketAt = DateTime.now();

      // Real-Time Session Inactivity Watchdog:
      // Checks every second if the session has dropped or if no packets arrived within 3s.
      // Triggers instant UI disconnection without needing a hot restart.
      _sessionWatchdogTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (_device == null || _connectionState != BleConnectionState.connected) return;

        final last = _lastPacketAt;
        if (last != null && DateTime.now().difference(last) > const Duration(seconds: 3)) {
          // Terminal session stopped emitting or was killed -> immediate disconnect
          _handleDisconnect();
          return;
        }

        // Active application-level GATT test: reading from the characteristic fails immediately
        // when the Python GATT server is closed (unlike raw RSSI which is handled by PC hardware)
        try {
          if (_activeReadingChar != null) {
            await _activeReadingChar!.read().timeout(const Duration(seconds: 2));
            _lastPacketAt = DateTime.now();
          } else {
            await _device?.readRssi().timeout(const Duration(seconds: 2));
          }
        } catch (_) {
          _handleDisconnect();
        }
      });

      final services = await device.discoverServices();

      for (final service in services) {
        final sUuidStr = service.uuid.str128.toLowerCase();
        final isGlucoseService = sUuidStr == BleContract.serviceUuid.toLowerCase() ||
            sUuidStr.contains('a000') ||
            service.uuid == Guid(BleContract.serviceUuid) ||
            service.uuid == Guid('a000');

        if (isGlucoseService) {
          for (final char in service.characteristics) {
            final cUuidStr = char.uuid.str128.toLowerCase();
            final isReadingChar = cUuidStr == BleContract.readingCharacteristicUuid.toLowerCase() ||
                cUuidStr.contains('a001') ||
                char.uuid == Guid(BleContract.readingCharacteristicUuid) ||
                char.uuid == Guid('a001');

            final isSessionChar = cUuidStr == BleContract.sessionCharacteristicUuid.toLowerCase() ||
                cUuidStr.contains('a002') ||
                char.uuid == Guid(BleContract.sessionCharacteristicUuid) ||
                char.uuid == Guid('a002');

            if (isReadingChar) {
              _activeReadingChar = char;
              await char.setNotifyValue(true);
              await _readingSub?.cancel();
              _readingSub = char.onValueReceived.listen((bytes) {
                _lastPacketAt = DateTime.now();
                final reading = GlucoseReadingCodec.decode(bytes, timestamp: DateTime.now());
                if (reading != null && !_readingsController.isClosed) {
                  _readingsController.add(reading);
                }
              });
              try {
                final initialBytes = await char.read();
                _lastPacketAt = DateTime.now();
                final reading = GlucoseReadingCodec.decode(initialBytes, timestamp: DateTime.now());
                if (reading != null && !_readingsController.isClosed) {
                  _readingsController.add(reading);
                }
              } catch (_) {}
            }

            if (isSessionChar) {
              await char.setNotifyValue(true);
              await _sessionSub?.cancel();
              _sessionSub = char.onValueReceived.listen((bytes) {
                _lastPacketAt = DateTime.now();
                if (bytes.length >= 4) {
                  final sessionId = bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
                  if (sessionId == 0) {
                    // Explicit session termination signal from emulator
                    _handleDisconnect();
                    return;
                  }
                  if (_activeSessionId != null && _activeSessionId != sessionId) {
                    // Session changed on device
                    _activeSessionId = sessionId;
                  } else {
                    _activeSessionId = sessionId;
                  }
                  if (bytes.length >= 5) {
                    _currentBatteryLevel = bytes[4];
                    if (!_batteryController.isClosed) {
                      _batteryController.add(bytes[4]);
                    }
                  }
                }
              });
              try {
                final initialSession = await char.read();
                _lastPacketAt = DateTime.now();
                if (initialSession.length >= 4) {
                  _activeSessionId = initialSession[0] |
                      (initialSession[1] << 8) |
                      (initialSession[2] << 16) |
                      (initialSession[3] << 24);
                  if (initialSession.length >= 5) {
                    _currentBatteryLevel = initialSession[4];
                    if (!_batteryController.isClosed) {
                      _batteryController.add(initialSession[4]);
                    }
                  }
                }
              } catch (_) {}
            }
          }
        }

        final isBatteryService = sUuidStr == BleContract.batteryServiceUuid.toLowerCase() ||
            sUuidStr.contains('180f') ||
            service.uuid == Guid(BleContract.batteryServiceUuid) ||
            service.uuid == Guid('180f');

        if (isBatteryService) {
          for (final char in service.characteristics) {
            final cUuidStr = char.uuid.str128.toLowerCase();
            final isBatteryChar = cUuidStr == BleContract.batteryLevelCharacteristicUuid.toLowerCase() ||
                cUuidStr.contains('2a19') ||
                char.uuid == Guid(BleContract.batteryLevelCharacteristicUuid) ||
                char.uuid == Guid('2a19');

            if (isBatteryChar) {
              await char.setNotifyValue(true);
              await _batterySub?.cancel();
              _batterySub = char.onValueReceived.listen((bytes) {
                _lastPacketAt = DateTime.now();
                if (bytes.isNotEmpty) {
                  _currentBatteryLevel = bytes.first;
                  if (!_batteryController.isClosed) {
                    _batteryController.add(bytes.first);
                  }
                }
              });
              try {
                final initialBattery = await char.read();
                _lastPacketAt = DateTime.now();
                if (initialBattery.isNotEmpty) {
                  _currentBatteryLevel = initialBattery.first;
                  if (!_batteryController.isClosed) {
                    _batteryController.add(initialBattery.first);
                  }
                }
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      _handleDisconnect();
      await device.disconnect().catchError((_) {});
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    final d = _device;
    _handleDisconnect();
    try {
      await d?.disconnect();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    _sessionWatchdogTimer?.cancel();
    _sessionWatchdogTimer = null;
    await _scanSub?.cancel();
    await _isScanningSub?.cancel();
    await _connectionSub?.cancel();
    await _globalConnSub?.cancel();
    await _readingSub?.cancel();
    await _sessionSub?.cancel();
    await _batterySub?.cancel();
    await _connectionStateController.close();
    await _readingsController.close();
    await _batteryController.close();
    await _discoveredController.close();
    await _connectedDeviceController.close();
  }
}
