import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/glucose_class.dart';
import '../models/glucose_reading.dart';

/// Represents an alert notification that was fired by the service.
class NotificationRecord {
  const NotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.glucoseClass,
  });

  final int id;
  final String title;
  final String body;
  final DateTime timestamp;
  final GlucoseClass glucoseClass;
}

/// Fires a local alert only when the reported class transitions into
/// low/high (edge-triggered), not on every reading — a stream of
/// "still low" notifications would be noise rather than a warning.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final List<NotificationRecord> _history = [];
  GlucoseClass? _lastClass;
  bool _initialized = false;

  /// Audit log of all alerts fired in this session (used by UI & test runner).
  List<NotificationRecord> get history => List.unmodifiable(_history);
  int get lowAlertsCount =>
      _history.where((n) => n.glucoseClass == GlucoseClass.low).length;
  int get highAlertsCount =>
      _history.where((n) => n.glucoseClass == GlucoseClass.high).length;

  static const _androidChannel = AndroidNotificationDetails(
    'glucose_alerts',
    'Glucose alerts',
    channelDescription: 'Low and high glucose state alerts',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
      _initialized = true;
    } catch (_) {
      // Ignored in test/headless environments
    }
  }

  Future<void> requestPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  /// Call on every new reading; only notifies on a low/high transition.
  Future<void> onReading(GlucoseReading reading, {required bool alertsEnabled}) async {
    final previous = _lastClass;
    _lastClass = reading.glucoseClass;
    if (!alertsEnabled) return;
    if (reading.glucoseClass == GlucoseClass.normal) return;
    if (previous == reading.glucoseClass) return; // already alerted for this episode

    final title = '${reading.glucoseClass.label} glucose';
    final body = '${reading.glucoseClass.clinicalName} — ${reading.mgDl.round()} mg/dL '
        '(${reading.confidence}% confidence)';

    _history.add(NotificationRecord(
      id: reading.glucoseClass.wireValue,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      glucoseClass: reading.glucoseClass,
    ));

    try {
      await _plugin.show(
        reading.glucoseClass.wireValue,
        title,
        body,
        const NotificationDetails(
          android: _androidChannel,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Ignored in headless/test environments
    }
  }

  /// Sends a local notification alerting that the wearable connection was lost.
  Future<void> notifyDisconnection({String? deviceName}) async {
    const id = 999;
    final title = 'Wearable Disconnected';
    final body = deviceName != null
        ? '$deviceName connection was lost.'
        : 'Glucose Wearable connection lost.';

    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: _androidChannel,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Ignored in headless/test environments
    }
  }

  void reset() {
    _lastClass = null;
    _history.clear();
  }
}

