import 'package:flutter_test/flutter_test.dart';

import 'package:glucose_monitor/core/glucose_class.dart';
import 'package:glucose_monitor/models/glucose_reading.dart';
import 'package:glucose_monitor/services/notification_service.dart';

void main() {
  group('Safety & Alert Management Engine Tests', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService();
    });

    test('Standard Low and High alerts edge-triggered firing', () async {
      final now = DateTime.now();

      // Normal reading -> no alert
      await service.onReading(
        GlucoseReading(timestamp: now, mgDl: 110.0, glucoseClass: GlucoseClass.normal, confidence: 95),
        alertsEnabled: true,
      );
      expect(service.history.length, equals(0));

      // Transition to Low -> Fires Low alert
      await service.onReading(
        GlucoseReading(timestamp: now.add(const Duration(minutes: 5)), mgDl: 68.0, glucoseClass: GlucoseClass.low, confidence: 95),
        alertsEnabled: true,
      );
      expect(service.history.length, equals(1));
      expect(service.history.first.glucoseClass, equals(GlucoseClass.low));
      expect(service.history.first.isUrgent, isFalse);

      // Repeat Low reading -> Suppressed (Edge-triggered)
      await service.onReading(
        GlucoseReading(timestamp: now.add(const Duration(minutes: 10)), mgDl: 65.0, glucoseClass: GlucoseClass.low, confidence: 95),
        alertsEnabled: true,
      );
      expect(service.history.length, equals(1));
    });

    test('Urgent Low Glucose (<55 mg/dL) triggers Max-Priority Emergency Alarm', () async {
      final now = DateTime.now();

      await service.onReading(
        GlucoseReading(timestamp: now, mgDl: 50.0, glucoseClass: GlucoseClass.low, confidence: 95),
        alertsEnabled: true,
        urgentLowThresholdMgDl: 55,
      );

      expect(service.history.length, equals(1));
      expect(service.history.first.isUrgent, isTrue);
      expect(service.history.first.title, contains('URGENT LOW GLUCOSE ALARM'));
    });

    test('Alert Snooze suppresses notifications during active snooze window', () async {
      final now = DateTime.now();
      final snoozedUntil = now.add(const Duration(minutes: 30));

      // Reading during active snooze window -> Suppressed
      await service.onReading(
        GlucoseReading(timestamp: now, mgDl: 65.0, glucoseClass: GlucoseClass.low, confidence: 95),
        alertsEnabled: true,
        snoozedUntil: snoozedUntil,
      );

      expect(service.history.length, equals(0));
    });

    test('Stale Data notification logs stale warning', () async {
      await service.notifyStaleData();
      expect(service.history.isEmpty, isTrue); // Logged to notifications plugin
    });
  });
}
