import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/simulated_ble_manager.dart';
import '../ble/simulation_fixtures.dart';

/// Controls whether the app is running in BLE Simulation mode or Real Hardware mode.
final isSimulationModeProvider = StateProvider<bool>((ref) => false);

/// Singleton instance of [SimulatedBleManager].
final simulatedBleManagerProvider = Provider<SimulatedBleManager>((ref) {
  final sim = SimulatedBleManager();
  ref.onDispose(() => sim.dispose());
  return sim;
});

/// Active simulation scenario state.
class SimulationStudioState {
  const SimulationStudioState({
    this.activeScenario,
    this.isPlaying = false,
    this.playbackMode = SimulationPlaybackMode.timed,
    this.speedMultiplier = 1.0,
    this.logs = const [],
  });

  final SimulationScenario? activeScenario;
  final bool isPlaying;
  final SimulationPlaybackMode playbackMode;
  final double speedMultiplier;
  final List<String> logs;

  SimulationStudioState copyWith({
    SimulationScenario? activeScenario,
    bool? isPlaying,
    SimulationPlaybackMode? playbackMode,
    double? speedMultiplier,
    List<String>? logs,
  }) {
    return SimulationStudioState(
      activeScenario: activeScenario ?? this.activeScenario,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackMode: playbackMode ?? this.playbackMode,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      logs: logs ?? this.logs,
    );
  }
}

class SimulationStudioNotifier extends StateNotifier<SimulationStudioState> {
  SimulationStudioNotifier(this._ref) : super(const SimulationStudioState()) {
    final manager = _ref.read(simulatedBleManagerProvider);
    manager.eventLogStream.listen((log) {
      state = state.copyWith(logs: [...state.logs, log]);
    });
    manager.playbackStateStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
  }

  final Ref _ref;

  void selectScenario(SimulationScenario scenario) {
    state = state.copyWith(activeScenario: scenario, logs: []);
  }

  void setPlaybackMode(SimulationPlaybackMode mode) {
    state = state.copyWith(playbackMode: mode);
  }

  void setSpeedMultiplier(double speed) {
    state = state.copyWith(speedMultiplier: speed);
  }

  Future<void> play() async {
    if (state.activeScenario == null) return;
    final sim = _ref.read(simulatedBleManagerProvider);
    await sim.playScenario(
      state.activeScenario!,
      mode: state.playbackMode,
      speedMultiplier: state.speedMultiplier,
    );
  }

  void pause() {
    _ref.read(simulatedBleManagerProvider).pauseScenario();
  }

  void resume() {
    _ref.read(simulatedBleManagerProvider).resumeScenario();
  }

  void step() {
    _ref.read(simulatedBleManagerProvider).stepNextEvent();
  }

  void stop() {
    _ref.read(simulatedBleManagerProvider).stopScenario();
  }

  void clearLogs() {
    state = state.copyWith(logs: []);
  }
}

final simulationStudioProvider =
    StateNotifierProvider<SimulationStudioNotifier, SimulationStudioState>((ref) {
  return SimulationStudioNotifier(ref);
});
