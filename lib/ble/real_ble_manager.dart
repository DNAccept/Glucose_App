import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/glucose_reading.dart';
import 'ble_contract.dart';
import 'ble_manager.dart';
import 'glucose_reading_codec.dart';

/// Talks to the real wearable over BLE using the contract in [BleContract].
class RealBleManager implements BleManager {
  RealBleManager() {
    _listenAdapterState();
  }

  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _readingsController = StreamController<GlucoseReading>.broadcast();
  final _batteryController = StreamController<int>.broadcast();
  final _discoveredController = StreamController<List<DiscoveredDevice>>.broadcast();
  final _connectedDeviceController = StreamController<DiscoveredDevice?>.broadcast();
  final _isBluetoothOnController = StreamController<bool>.broadcast();

  BleConnectionState _connectionState = BleConnectionState.disconnected;
  bool _isBluetoothOn = true;
  BluetoothDevice? _device;
  DiscoveredDevice? _currentDevice;
  int? _currentBatteryLevel;
  int? _activeSessionId;
  DateTime? _lastPacketAt;
  BluetoothCharacteristic? _activeReadingChar;
  List<DiscoveredDevice> _discoveredDevices = [];
  DateTime? _scanStartedAt;

  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<OnConnectionStateChangedEvent>? _globalConnSub;
  StreamSubscription<List<int>>? _readingSub;
  StreamSubscription<List<int>>? _sessionSub;
  StreamSubscription<List<int>>? _batterySub;
  Timer? _sessionWatchdogTimer;
  Timer? _scanPruneTimer;

  void _listenAdapterState() {
    _adapterStateSub = FlutterBluePlus.adapterState.listen((adapterState) {
      final isOn = adapterState == BluetoothAdapterState.on;
      if (_isBluetoothOn != isOn) {
        _isBluetoothOn = isOn;
        if (!_isBluetoothOnController.isClosed) {
          _isBluetoothOnController.add(isOn);
        }
      }

      if (!isOn) {
        _stopScanningAndClearDiscovered();
        _handleDisconnect();
      }
    });
  }

  void _stopScanningAndClearDiscovered() {
    _scanPruneTimer?.cancel();
    _scanPruneTimer = null;
    _scanSub?.cancel();
    _scanSub = null;
    _isScanningSub?.cancel();
    _isScanningSub = null;
    FlutterBluePlus.stopScan().catchError((_) {});

    _discoveredDevices = [];
    if (!_discoveredController.isClosed) {
      _discoveredController.add([]);
    }
  }

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

  @override
  Stream<bool> get isBluetoothOn => _isBluetoothOnController.stream;
  @override
  bool get currentIsBluetoothOn => _isBluetoothOn;

  void _setConnectionState(BleConnectionState state) {
    _connectionState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  void _handleDisconnect() {
    _sessionWatchdogTimer?.cancel();
    _sessionWatchdogTimer = null;
    _scanPruneTimer?.cancel();
    _scanPruneTimer = null;
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
    _scanSub?.cancel();
    _scanSub = null;
    _isScanningSub?.cancel();
    _isScanningSub = null;

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
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _stopScanningAndClearDiscovered();
      _handleDisconnect();
      return;
    }

    _scanStartedAt = DateTime.now();
    _setConnectionState(BleConnectionState.scanning);
    _discoveredDevices = [];
    if (!_discoveredController.isClosed) {
      _discoveredController.add([]);
    }

    await _scanSub?.cancel();
    await _isScanningSub?.cancel();
    _scanPruneTimer?.cancel();

    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    final seen = <String, DiscoveredDevice>{};
    final lastSeen = <String, DateTime>{};

    _isScanningSub = FlutterBluePlus.isScanning.listen((isScanning) async {
      if (!isScanning && _device == null && _currentDevice == null && _connectionState == BleConnectionState.scanning) {
        final started = _scanStartedAt;
        if (started != null) {
          final elapsed = DateTime.now().difference(started);
          const minScanDuration = Duration(seconds: 3);
          if (elapsed < minScanDuration) {
            await Future.delayed(minScanDuration - elapsed);
          }
        }
        if (_scanStartedAt != null && _connectionState == BleConnectionState.scanning && _device == null && _currentDevice == null) {
          _setConnectionState(BleConnectionState.disconnected);
          _scanPruneTimer?.cancel();
        }
      }
    });

    // Prune devices whose active broadcast advertisement signal stopped (no packet in last 4 seconds)
    _scanPruneTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectionState != BleConnectionState.scanning) return;
      final now = DateTime.now();
      bool changed = false;

      seen.removeWhere((id, device) {
        final lastTime = lastSeen[id];
        if (lastTime == null || now.difference(lastTime) > const Duration(seconds: 6)) {
          lastSeen.remove(id);
          changed = true;
          return true;
        }
        return false;
      });

      if (changed) {
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
      }
    });

    // Listen to live over-the-air BLE advertisement broadcasts
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final now = DateTime.now();
      for (final r in results) {
        // Only accept devices actively emitting broadcast signals
        if (r.rssi < -90) continue;

        final rawName = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName;
        final rawNameLower = rawName.trim().toLowerCase();

        // Exact Glucose Service UUID validation:
        // Must match contract UUID (0000a000-0000-1000-8000-00805f9b34fb or 0000a000-...),
        // or standard Bluetooth SIG Glucose service (00001808-...) or CGM service (0000181f-...).
        final hasGlucoseService = r.advertisementData.serviceUuids.any((u) {
          final s = u.str128.toLowerCase();
          return s == BleContract.serviceUuid.toLowerCase() ||
              s.startsWith('0000a000-') ||
              s.startsWith('00001808-') ||
              s.startsWith('0000181f-');
        });

        // Filter out generic, empty, or fallback OS Bluetooth names (e.g. "BLE Device (__:__)", "Unknown", "N/A", "Device")
        final isGenericName = rawName.isEmpty ||
            rawNameLower.startsWith('ble device') ||
            rawNameLower.startsWith('unknown') ||
            rawNameLower.startsWith('n/a') ||
            rawNameLower == 'device' ||
            rawNameLower.contains('(__:__)');

        if (!hasGlucoseService) {
          // If it does NOT advertise an explicit Glucose Service UUID, and the name is generic or does NOT contain explicit glucose keywords, SKIP IT.
          final isGlucoseDeviceName = !isGenericName && (
              rawNameLower.contains('glucose') ||
              rawNameLower.contains('wearable') ||
              rawNameLower.contains('cgm') ||
              rawNameLower.contains('dna') ||
              rawNameLower.contains('monitor') ||
              rawNameLower.contains('dexcom') ||
              rawNameLower.contains('freestyle') ||
              rawNameLower.contains('libre')
          );

          if (!isGlucoseDeviceName) {
            continue; // Skip non-glucose device completely
          }
        }

        String displayName;
        if (hasGlucoseService) {
          displayName = (!isGenericName && rawName.isNotEmpty)
              ? '⭐ Glucose Wearable ($rawName)'
              : '⭐ Glucose Wearable';
        } else {
          displayName = '⭐ $rawName';
        }

        final deviceId = r.device.remoteId.str;
        seen[deviceId] = DiscoveredDevice(
          id: deviceId,
          name: displayName,
          rssi: r.rssi,
        );
        lastSeen[deviceId] = now;
      }

      // Sort matching/starred devices to the top by signal strength
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
        timeout: const Duration(seconds: 30),
      );
    } catch (_) {}
  }

  @override
  Future<void> stopScan() async {
    _scanStartedAt = null;
    _stopScanningAndClearDiscovered();
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
            sUuidStr.startsWith('0000a000-') ||
            service.uuid == Guid(BleContract.serviceUuid) ||
            service.uuid == Guid('a000');

        if (isGlucoseService) {
          for (final char in service.characteristics) {
            final cUuidStr = char.uuid.str128.toLowerCase();
            final isReadingChar = cUuidStr == BleContract.readingCharacteristicUuid.toLowerCase() ||
                cUuidStr.startsWith('0000a001-') ||
                char.uuid == Guid(BleContract.readingCharacteristicUuid) ||
                char.uuid == Guid('a001');

            final isSessionChar = cUuidStr == BleContract.sessionCharacteristicUuid.toLowerCase() ||
                cUuidStr.startsWith('0000a002-') ||
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
            sUuidStr.startsWith('0000180f-') ||
            service.uuid == Guid(BleContract.batteryServiceUuid) ||
            service.uuid == Guid('180f');

        if (isBatteryService) {
          for (final char in service.characteristics) {
            final cUuidStr = char.uuid.str128.toLowerCase();
            final isBatteryChar = cUuidStr == BleContract.batteryLevelCharacteristicUuid.toLowerCase() ||
                cUuidStr.startsWith('00002a19-') ||
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
    _stopScanningAndClearDiscovered();
    _handleDisconnect();
    await _connectionStateController.close();
    await _readingsController.close();
    await _batteryController.close();
    await _discoveredController.close();
    await _connectedDeviceController.close();
    await _isBluetoothOnController.close();
  }
}
