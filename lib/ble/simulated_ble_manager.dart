import 'dart:async';

import '../models/glucose_reading.dart';
import 'ble_manager.dart';
import 'simulation_fixtures.dart';

class SimulatedBleManager implements BleManager {
  SimulatedBleManager() {
    _initDefaults();
  }

  void _initDefaults() {
    _connectionState = BleConnectionState.connected;
    _currentBattery = 95;
    _currentDevice = const DiscoveredDevice(
      id: 'SIM-WEARABLE-001',
      name: 'Simulated Glucose Wearable',
      rssi: -55,
    );
  }

  // BleManager StreamControllers
  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _readingsController = StreamController<GlucoseReading>.broadcast();
  final _batteryLevelController = StreamController<int>.broadcast();
  final _discoveredDevicesController = StreamController<List<DiscoveredDevice>>.broadcast();
  final _connectedDeviceController = StreamController<DiscoveredDevice?>.broadcast();

  // Simulation Control Controllers
  final _eventLogController = StreamController<String>.broadcast();
  final _playbackStateController = StreamController<bool>.broadcast();

  BleConnectionState _connectionState = BleConnectionState.connected;
  int? _currentBattery = 95;
  DiscoveredDevice? _currentDevice = const DiscoveredDevice(
    id: 'SIM-WEARABLE-001',
    name: 'Simulated Glucose Wearable',
    rssi: -55,
  );
  List<DiscoveredDevice> _discoveredList = [];

  // Playback state
  SimulationScenario? _activeScenario;
  int _currentEventIndex = 0;
  bool _isPlaying = false;
  double _speedMultiplier = 1.0;
  SimulationPlaybackMode _playbackMode = SimulationPlaybackMode.timed;
  Timer? _playbackTimer;

  // BleManager implementation
  @override
  Stream<BleConnectionState> get connectionState => _connectionStateController.stream;
  @override
  BleConnectionState get currentConnectionState => _connectionState;

  @override
  Stream<GlucoseReading> get readings => _readingsController.stream;

  @override
  Stream<int> get batteryLevel => _batteryLevelController.stream;
  @override
  int? get currentBatteryLevel => _currentBattery;

  @override
  Stream<List<DiscoveredDevice>> get discoveredDevices => _discoveredDevicesController.stream;
  @override
  List<DiscoveredDevice> get currentDiscoveredDevices => _discoveredList;

  @override
  Stream<DiscoveredDevice?> get connectedDevice => _connectedDeviceController.stream;
  @override
  DiscoveredDevice? get currentDevice => _currentDevice;

  // Simulation API
  Stream<String> get eventLogStream => _eventLogController.stream;
  Stream<bool> get playbackStateStream => _playbackStateController.stream;
  bool get isPlaying => _isPlaying;
  SimulationScenario? get activeScenario => _activeScenario;
  int get currentStepIndex => _currentEventIndex;

  @override
  Future<void> startScan() async {
    _connectionState = BleConnectionState.scanning;
    _connectionStateController.add(_connectionState);
    _discoveredList = [
      const DiscoveredDevice(id: 'SIM-WEARABLE-001', name: 'Simulated Glucose Wearable', rssi: -55),
      const DiscoveredDevice(id: 'SIM-WEARABLE-002', name: 'Test Wearable B', rssi: -72),
    ];
    _discoveredDevicesController.add(_discoveredList);
  }

  @override
  Future<void> stopScan() async {
    if (_connectionState == BleConnectionState.scanning) {
      _connectionState = BleConnectionState.disconnected;
      _connectionStateController.add(_connectionState);
    }
  }

  @override
  Future<void> connect(String deviceId) async {
    _connectionState = BleConnectionState.connecting;
    _connectionStateController.add(_connectionState);
    await Future.delayed(const Duration(milliseconds: 300));

    _connectionState = BleConnectionState.connected;
    _connectionStateController.add(_connectionState);
    _currentDevice = _discoveredList.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => const DiscoveredDevice(id: 'SIM-WEARABLE-001', name: 'Simulated Glucose Wearable', rssi: -55),
    );
    _connectedDeviceController.add(_currentDevice);
  }

  @override
  Future<void> disconnect() async {
    _connectionState = BleConnectionState.disconnected;
    _connectionStateController.add(_connectionState);
    _currentDevice = null;
    _connectedDeviceController.add(null);
  }

  // --- Scenario Playback Controls ---

  Future<void> playScenario(
    SimulationScenario scenario, {
    SimulationPlaybackMode mode = SimulationPlaybackMode.timed,
    double speedMultiplier = 1.0,
  }) async {
    stopScenario();
    _activeScenario = scenario;
    _playbackMode = mode;
    _speedMultiplier = speedMultiplier;
    _currentEventIndex = 0;
    _isPlaying = true;
    _playbackStateController.add(true);

    _log('Starting Scenario: "${scenario.title}" [Mode: ${mode.name}, Speed: ${speedMultiplier}x]');

    if (mode == SimulationPlaybackMode.instant) {
      while (_currentEventIndex < scenario.events.length && _isPlaying) {
        _executeNextEvent();
        await Future.microtask(() {});
      }
    } else if (mode == SimulationPlaybackMode.timed) {
      _scheduleNextEvent();
    }
  }

  void pauseScenario() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _playbackStateController.add(false);
    _log('Scenario Paused at step $_currentEventIndex');
  }

  void resumeScenario() {
    if (_activeScenario == null || _isPlaying) return;
    _isPlaying = true;
    _playbackStateController.add(true);
    _log('Scenario Resumed at step $_currentEventIndex');
    _scheduleNextEvent();
  }

  void stepNextEvent() {
    if (_activeScenario == null) return;
    if (_currentEventIndex < _activeScenario!.events.length) {
      _executeNextEvent();
    } else {
      _log('Reached end of scenario.');
    }
  }

  void stopScenario() {
    _playbackTimer?.cancel();
    _isPlaying = false;
    _currentEventIndex = 0;
    _playbackStateController.add(false);
  }

  void _scheduleNextEvent() {
    if (!_isPlaying || _activeScenario == null || _currentEventIndex >= _activeScenario!.events.length) {
      stopScenario();
      return;
    }

    final event = _activeScenario!.events[_currentEventIndex];
    final actualDelay = (event.delayMs / _speedMultiplier).round();

    _playbackTimer = Timer(Duration(milliseconds: actualDelay), () {
      if (_isPlaying) {
        _executeNextEvent();
        _scheduleNextEvent();
      }
    });
  }

  void _executeNextEvent() {
    if (_activeScenario == null || _currentEventIndex >= _activeScenario!.events.length) return;

    final event = _activeScenario!.events[_currentEventIndex];
    _currentEventIndex++;

    _log('[Step $_currentEventIndex/${_activeScenario!.events.length}] ${event.logMessage}');

    if (event.isDisconnect) {
      _connectionState = BleConnectionState.disconnected;
      _connectionStateController.add(_connectionState);
    } else if (event.isReconnect) {
      _connectionState = BleConnectionState.connected;
      _connectionStateController.add(_connectionState);
    }

    if (event.batteryLevel != null) {
      _currentBattery = event.batteryLevel;
      _batteryLevelController.add(event.batteryLevel!);
    }

    if (event.reading != null && !event.isCorrupt) {
      _readingsController.add(event.reading!);
    }
  }

  void _log(String msg) {
    _eventLogController.add('[${DateTime.now().toString().substring(11, 19)}] $msg');
  }

  @override
  Future<void> dispose() async {
    _playbackTimer?.cancel();
    await _connectionStateController.close();
    await _readingsController.close();
    await _batteryLevelController.close();
    await _discoveredDevicesController.close();
    await _connectedDeviceController.close();
    await _eventLogController.close();
    await _playbackStateController.close();
  }
}
