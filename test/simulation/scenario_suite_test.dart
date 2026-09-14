import 'package:flutter_test/flutter_test.dart';

import 'package:glucose_monitor/ble/ble_manager.dart';
import 'package:glucose_monitor/ble/simulated_ble_manager.dart';
import 'package:glucose_monitor/ble/simulation_fixtures.dart';
import 'package:glucose_monitor/core/glucose_class.dart';
import 'package:glucose_monitor/models/glucose_reading.dart';

void main() {
  group('BLE Device-Simulation Suite (All 9 Data Fixtures)', () {
    late SimulatedBleManager manager;

    setUp(() {
      manager = SimulatedBleManager();
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('1. Regular Use (Normal Range) scenario streams 10 normal readings', () async {
      final scenario = SimulationFixturesRegistry.allScenarios.firstWhere((s) => s.id == 'regular_use_normal_range');
      final receivedReadings = <GlucoseReading>[];
      final logs = <String>[];

      manager.readings.listen(receivedReadings.add);
      manager.eventLogStream.listen(logs.add);

      await manager.playScenario(scenario, mode: SimulationPlaybackMode.instant);

      expect(receivedReadings.length, equals(10));
      for (final r in receivedReadings) {
        expect(r.glucoseClass, equals(GlucoseClass.normal));
        expect(r.mgDl, greaterThanOrEqualTo(90.0));
        expect(r.mgDl, lessThanOrEqualTo(120.0));
      }
      expect(logs.length, greaterThan(0));
    });

    test('2. Hypoglycemia Event triggers low glucose state', () async {
      final scenario = SimulationFixturesRegistry.allScenarios.firstWhere((s) => s.id == 'hypoglycemia_event');
      final receivedReadings = <GlucoseReading>[];

      manager.readings.listen(receivedReadings.add);
      await manager.playScenario(scenario, mode: SimulationPlaybackMode.instant);

      expect(receivedReadings.length, equals(3));
      expect(receivedReadings[0].glucoseClass, equals(GlucoseClass.normal));
      expect(receivedReadings[1].glucoseClass, equals(GlucoseClass.low));
      expect(receivedReadings[2].glucoseClass, equals(GlucoseClass.low));
    });

    test('3. Hyperglycemia Event triggers high glucose state', () async {
      final scenario = SimulationFixturesRegistry.allScenarios.firstWhere((s) => s.id == 'hyperglycemia_event');
      final receivedReadings = <GlucoseReading>[];

      manager.readings.listen(receivedReadings.add);
      await manager.playScenario(scenario, mode: SimulationPlaybackMode.instant);

      expect(receivedReadings.length, equals(3));
      expect(receivedReadings[0].glucoseClass, equals(GlucoseClass.normal));
      expect(receivedReadings[1].glucoseClass, equals(GlucoseClass.high));
      expect(receivedReadings[2].glucoseClass, equals(GlucoseClass.high));
    });

    test('4. Rapid Swings transitions low -> normal -> high', () async {
      final scenario = SimulationFixturesRegistry.allScenarios.firstWhere((s) => s.id == 'rapid_swings');
      final receivedReadings = <GlucoseReading>[];

      manager.readings.listen(receivedReadings.add);
      await manager.playScenario(scenario, mode: SimulationPlaybackMode.instant);

      expect(receivedReadings.length, equals(3));
      expect(receivedReadings[0].glucoseClass, equals(GlucoseClass.low));
      expect(receivedReadings[1].glucoseClass, equals(GlucoseClass.normal));
      expect(receivedReadings[2].glucoseClass, equals(GlucoseClass.high));
    });

    test('5. Low Confidence & Model Origin handles on-device vs phone models', () async {
      final scenario = SimulationFixturesRegistry.allScenarios.firstWhere((s) => s.id == 'low_confidence_disagreement');
      final receivedReadings = <GlucoseReading>[];

      manager.readings.listen(receivedReadings.add);
      await manager.playScenario(scenario, mode: SimulationPlaybackMode.instant);

      expect(receivedReadings.length, equals(2));
      expect(receivedReadings[0].isLowConfidence, isTrue);
      expect(receivedReadings[0].modelOrigin, equals(ModelOrigin.onDevice));
      expect(receivedReadings[1].modelOrigin, equals(ModelOrigin.phoneBackground));
    });

    test('6. Corrupted Packets handles malformed bytes without crashing', () async {
      final scenario = SimulationFixturesRegistry.allScenarios.firstWhere((s) => s.id == 'corrupted_missing_packets');
      final receivedReadings = <GlucoseReading>[];

      manager.readings.listen(receivedReadings.add);
      await manager.playScenario(scenario, mode: SimulationPlaybackMode.instant);

      expect(receivedReadings.length, equals(1));
      expect(receivedReadings.first.mgDl, equals(100.0));
    });

    test('7. Mid-Stream Disconnect & Reconnect state transitions', () async {
      final scenario = SimulationFixturesRegistry.allScenarios.firstWhere((s) => s.id == 'disconnect_reconnect');
      final states = <BleConnectionState>[];

      manager.connectionState.listen(states.add);
      await manager.playScenario(scenario, mode: SimulationPlaybackMode.instant);

      expect(states, contains(BleConnectionState.disconnected));
      expect(states, contains(BleConnectionState.connected));
    });

    test('8. Sensor Health Flags parses motion, skin contact, and battery warnings', () async {
      final scenario = SimulationFixturesRegistry.allScenarios.firstWhere((s) => s.id == 'signal_integrity_flags');
      final receivedReadings = <GlucoseReading>[];

      manager.readings.listen(receivedReadings.add);
      await manager.playScenario(scenario, mode: SimulationPlaybackMode.instant);

      expect(receivedReadings.length, equals(2));
      expect(receivedReadings[0].hasMotionArtifact, isTrue);
      expect(receivedReadings[1].hasPoorContact, isTrue);
      expect(receivedReadings[1].hasLowBatteryWarning, isTrue);
    });

    test('9. Timing Burst & Jitter processes rapid packets', () async {
      final scenario = SimulationFixturesRegistry.allScenarios.firstWhere((s) => s.id == 'timing_burst_and_jitter');
      final receivedReadings = <GlucoseReading>[];

      manager.readings.listen(receivedReadings.add);
      await manager.playScenario(scenario, mode: SimulationPlaybackMode.instant);

      expect(receivedReadings.length, equals(5));
    });
  });
}
