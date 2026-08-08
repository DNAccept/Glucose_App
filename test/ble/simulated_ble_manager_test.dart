import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_monitor/ble/ble_manager.dart';
import 'package:glucose_monitor/ble/simulated_ble_manager.dart';
import 'package:glucose_monitor/core/glucose_class.dart';

void main() {
  group('SimulatedBleManager', () {
    test('connect() transitions through connecting to connected and emits a reading', () async {
      final manager = SimulatedBleManager(tickInterval: const Duration(milliseconds: 20));
      addTearDown(manager.dispose);

      final states = <BleConnectionState>[];
      final sub = manager.connectionState.listen(states.add);
      final readingFuture = manager.readings.first;

      await manager.connect('sim-wearable-1');
      await readingFuture;
      await sub.cancel();

      expect(states, containsAllInOrder([BleConnectionState.connecting, BleConnectionState.connected]));
    });

    test('every emitted reading is internally consistent: class matches GlucoseClass.fromMgDl(mgDl)', () async {
      final manager = SimulatedBleManager(tickInterval: const Duration(milliseconds: 10));
      addTearDown(manager.dispose);

      final readings = <void>[];
      final sub = manager.readings.listen((r) {
        expect(r.glucoseClass, GlucoseClass.fromMgDl(r.mgDl));
        expect(r.confidence, inInclusiveRange(0, 100));
        readings.add(null);
      });

      await manager.connect('sim-wearable-1');
      await Future.delayed(const Duration(milliseconds: 120));
      await sub.cancel();

      expect(readings.length, greaterThan(3));
    });

    test('forceClass pins every subsequent reading to the requested class', () async {
      final manager = SimulatedBleManager(tickInterval: const Duration(milliseconds: 10));
      addTearDown(manager.dispose);
      manager.forceClass(GlucoseClass.low);

      final classes = <GlucoseClass>[];
      final sub = manager.readings.listen((r) => classes.add(r.glucoseClass));

      await manager.connect('sim-wearable-1');
      await Future.delayed(const Duration(milliseconds: 80));
      await sub.cancel();

      expect(classes, isNotEmpty);
      expect(classes.every((c) => c == GlucoseClass.low), isTrue);
    });

    test('disconnect() stops emitting readings', () async {
      final manager = SimulatedBleManager(tickInterval: const Duration(milliseconds: 10));
      addTearDown(manager.dispose);

      await manager.connect('sim-wearable-1');
      await Future.delayed(const Duration(milliseconds: 30));
      await manager.disconnect();

      var countAfterDisconnect = 0;
      final sub = manager.readings.listen((_) => countAfterDisconnect++);
      await Future.delayed(const Duration(milliseconds: 60));
      await sub.cancel();

      expect(countAfterDisconnect, 0);
    });
  });
}
