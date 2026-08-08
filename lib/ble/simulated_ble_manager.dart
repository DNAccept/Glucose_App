import 'dart:async';
import 'dart:math' as math;

import '../core/glucose_class.dart';
import '../models/glucose_reading.dart';
import 'ble_manager.dart';

/// Stand-in data source used until real wearable firmware exists. The daily
/// glucose curve (`_glucoseAt`) and classification thresholds are a direct
/// port of the HTML mockup's `glucoseAt()`/`classify()` functions, so
/// screenshots/behavior captured from the mockup carry over to the app.
class SimulatedBleManager implements BleManager {
  SimulatedBleManager({this._tickInterval = const Duration(seconds: 5)}) {
    _virtualNow = DateTime.now();
  }

  final Duration _tickInterval;
  late DateTime _virtualNow;
  Timer? _timer;
  GlucoseClass? _forcedClass;

  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _readingsController = StreamController<GlucoseReading>.broadcast();
  final _batteryController = StreamController<int>.broadcast();
  final _discoveredController = StreamController<List<DiscoveredDevice>>.broadcast();

  BleConnectionState _state = BleConnectionState.disconnected;
  int _battery = 82;
  final _rand = math.Random();

  @override
  Stream<BleConnectionState> get connectionState => _connectionStateController.stream;
  @override
  Stream<GlucoseReading> get readings => _readingsController.stream;
  @override
  Stream<int> get batteryLevel => _batteryController.stream;
  @override
  Stream<List<DiscoveredDevice>> get discoveredDevices => _discoveredController.stream;

  /// Demo-only hook (surfaced behind a debug-build toggle in Settings) to
  /// pin the simulator to a specific class, mirroring the mockup's "Force
  /// state" panel used for capturing screenshots.
  void forceClass(GlucoseClass? cls) => _forcedClass = cls;

  @override
  Future<void> startScan() async {
    _setState(BleConnectionState.scanning);
    await Future.delayed(const Duration(milliseconds: 900));
    _discoveredController.add(const [
      DiscoveredDevice(id: 'sim-wearable-1', name: 'Glucose Wearable', rssi: -58),
    ]);
  }

  @override
  Future<void> stopScan() async {
    if (_state == BleConnectionState.scanning) _setState(BleConnectionState.disconnected);
  }

  @override
  Future<void> connect(String deviceId) async {
    _setState(BleConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 500));
    _setState(BleConnectionState.connected);
    _battery = 82;
    _batteryController.add(_battery);
    _emitReading();
    _timer?.cancel();
    _timer = Timer.periodic(_tickInterval, (_) => _tick());
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    _setState(BleConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _connectionStateController.close();
    await _readingsController.close();
    await _batteryController.close();
    await _discoveredController.close();
  }

  void _setState(BleConnectionState s) {
    _state = s;
    _connectionStateController.add(s);
  }

  void _tick() {
    _virtualNow = _virtualNow.add(const Duration(minutes: 5));
    if (_battery > 15 && _rand.nextDouble() < 0.04) {
      _battery -= 1;
      _batteryController.add(_battery);
    }
    _emitReading();
  }

  void _emitReading() {
    _readingsController.add(_makeReading(_virtualNow));
  }

  GlucoseReading _makeReading(DateTime at) {
    if (_forcedClass != null) {
      const base = {GlucoseClass.low: 92, GlucoseClass.normal: 94, GlucoseClass.high: 90};
      final wobble = (math.sin(at.millisecondsSinceEpoch / 6e5) * 4).round();
      final mgDl = switch (_forcedClass!) {
        GlucoseClass.low => 55.0,
        GlucoseClass.normal => 105.0,
        GlucoseClass.high => 210.0,
      };
      return GlucoseReading(
        timestamp: at,
        mgDl: mgDl,
        glucoseClass: _forcedClass!,
        confidence: (base[_forcedClass!]! + wobble).clamp(0, 100),
      );
    }
    final g = _glucoseAt(at);
    final (cls, confidence) = _classify(g);
    return GlucoseReading(timestamp: at, mgDl: g, glucoseClass: cls, confidence: confidence);
  }

  /// Synthetic daily curve: baseline + breakfast/lunch/dinner bumps + an
  /// overnight dip, matching the mockup's `glucoseAt()` exactly.
  static double _glucoseAt(DateTime at) {
    final h = at.hour + at.minute / 60.0;
    double g = 110;
    g += 78 * math.exp(-math.pow(h - 7.5, 2) / 1.1); // breakfast
    g += 88 * math.exp(-math.pow(h - 13, 2) / 1.4); // lunch
    g += 82 * math.exp(-math.pow(h - 19.5, 2) / 1.6); // dinner
    if (h < 5.5) {
      g -= 28 * math.exp(-math.pow(h - 3.2, 2) / 2.2); // overnight dip
    }
    g += 7 * math.sin(h * 1.7);
    return g.clamp(52, 255);
  }

  static (GlucoseClass, int) _classify(double g) {
    double conf;
    GlucoseClass cls;
    if (g < GlucoseClass.lowCutMgDl) {
      cls = GlucoseClass.low;
      conf = 75 + (GlucoseClass.lowCutMgDl - g) * 1.2;
    } else if (g > GlucoseClass.highCutMgDl) {
      cls = GlucoseClass.high;
      conf = 76 + (g - GlucoseClass.highCutMgDl) * 0.45;
    } else {
      cls = GlucoseClass.normal;
      conf = 72 +
          math.min(g - GlucoseClass.lowCutMgDl, GlucoseClass.highCutMgDl - g) * 0.42;
    }
    return (cls, conf.clamp(62, 98).round());
  }
}
