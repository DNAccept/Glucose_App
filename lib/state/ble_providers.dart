import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_manager.dart';
import '../ble/real_ble_manager.dart';

/// Active BLE Manager wired directly to physical Bluetooth hardware.
final bleManagerProvider = Provider<BleManager>((ref) {
  final real = RealBleManager();
  ref.onDispose(() => real.dispose());
  return real;
});

class ConnectionStateNotifier extends StateNotifier<BleConnectionState> {
  ConnectionStateNotifier(this._manager) : super(_manager.currentConnectionState) {
    _sub = _manager.connectionState.listen((s) => state = s);
  }

  final BleManager _manager;
  late final StreamSubscription<BleConnectionState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final connectionStateProvider = StateNotifierProvider<ConnectionStateNotifier, BleConnectionState>((ref) {
  return ConnectionStateNotifier(ref.watch(bleManagerProvider));
});

class BatteryLevelNotifier extends StateNotifier<int?> {
  BatteryLevelNotifier(this._manager) : super(_manager.currentBatteryLevel) {
    _sub = _manager.batteryLevel.listen((b) => state = b);
  }

  final BleManager _manager;
  late final StreamSubscription<int> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final batteryLevelProvider = StateNotifierProvider<BatteryLevelNotifier, int?>((ref) {
  return BatteryLevelNotifier(ref.watch(bleManagerProvider));
});

class DiscoveredDevicesNotifier extends StateNotifier<List<DiscoveredDevice>> {
  DiscoveredDevicesNotifier(this._manager) : super(_manager.currentDiscoveredDevices) {
    _sub = _manager.discoveredDevices.listen((d) => state = d);
  }

  final BleManager _manager;
  late final StreamSubscription<List<DiscoveredDevice>> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final discoveredDevicesProvider = StateNotifierProvider<DiscoveredDevicesNotifier, List<DiscoveredDevice>>((ref) {
  return DiscoveredDevicesNotifier(ref.watch(bleManagerProvider));
});

class ConnectedDeviceNotifier extends StateNotifier<DiscoveredDevice?> {
  ConnectedDeviceNotifier(this._manager) : super(_manager.currentDevice) {
    _sub = _manager.connectedDevice.listen((d) => state = d);
  }

  final BleManager _manager;
  late final StreamSubscription<DiscoveredDevice?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final connectedDeviceProvider = StateNotifierProvider<ConnectedDeviceNotifier, DiscoveredDevice?>((ref) {
  return ConnectedDeviceNotifier(ref.watch(bleManagerProvider));
});


