import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_manager.dart';
import '../ble/simulated_ble_manager.dart';
import '../ble/real_ble_manager.dart';
import '../core/glucose_class.dart';

/// Whether the app is talking to the bundled simulator instead of real
/// hardware. Defaults to the simulator in debug builds (no firmware exists
/// yet) and to the real BLE manager in release builds.
final useSimulatorProvider = StateProvider<bool>((ref) => kDebugMode);

final bleManagerProvider = Provider<BleManager>((ref) {
  final useSimulator = ref.watch(useSimulatorProvider);
  final manager = useSimulator ? SimulatedBleManager() : RealBleManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final connectionStateProvider = StreamProvider<BleConnectionState>((ref) {
  return ref.watch(bleManagerProvider).connectionState;
});

final batteryLevelProvider = StreamProvider<int>((ref) {
  return ref.watch(bleManagerProvider).batteryLevel;
});

final discoveredDevicesProvider = StreamProvider<List<DiscoveredDevice>>((ref) {
  return ref.watch(bleManagerProvider).discoveredDevices;
});

/// Demo-only control (see [SimulatedBleManager.forceClass]) surfaced behind
/// a debug-build toggle in Settings.
final forcedClassProvider = StateProvider<GlucoseClass?>((ref) => null);

/// Applies [forcedClassProvider] to the active manager when it's the
/// simulator. Kept alive by being watched once from [RootShell].
final forceClassEffectProvider = Provider<void>((ref) {
  final manager = ref.watch(bleManagerProvider);
  final forced = ref.watch(forcedClassProvider);
  if (manager is SimulatedBleManager) {
    manager.forceClass(forced);
  }
});
