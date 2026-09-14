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
    this.isUrgent = false,
  });

  final int id;
  final String title;
  final String body;
  final DateTime timestamp;
  final GlucoseClass glucoseClass;
  final bool isUrgent;
}

/// Clinical notification engine supporting emergency sound overrides,
/// alert snoozing, custom thresholds, and stale data warnings.
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
  int get urgentAlertsCount => _history.where((n) => n.isUrgent).length;

  static const _androidUrgentChannel = AndroidNotificationDetails(
    'urgent_hypo_alerts',
    'Urgent Hypo & Emergency Alerts',
    channelDescription: 'Max priority sound and vibration alerts for severe hypoglycemia',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
  );

  static const _androidStandardChannel = AndroidNotificationDetails(
    'glucose_alerts',
    'Glucose Alerts',
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
        requestCriticalPermission: true,
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
          ?.requestPermissions(alert: true, badge: true, sound: true, critical: true);
    } catch (_) {}
  }

  /// Call on every new reading; respects alert toggles, snooze state, edge-triggered transitions, and thresholds.
  Future<void> onReading(
    GlucoseReading reading, {
    required bool alertsEnabled,
    DateTime? snoozedUntil,
    int lowThresholdMgDl = 70,
    int highThresholdMgDl = 180,
    int urgentLowThresholdMgDl = 55,
  }) async {
    final previous = _lastClass;
    _lastClass = reading.glucoseClass;

    if (!alertsEnabled) return;

    // Check if snooze timer is currently active
    if (snoozedUntil != null && DateTime.now().isBefore(snoozedUntil)) {
      return; // Suppress alert during active snooze
    }

    final isUrgentLow = reading.mgDl <= urgentLowThresholdMgDl;
    final isLow = reading.mgDl <= lowThresholdMgDl;
    final isHigh = reading.mgDl >= highThresholdMgDl;

    if (!isLow && !isHigh && !isUrgentLow) return;
    if (previous == reading.glucoseClass && !isUrgentLow) return; // Edge-triggered

    final isUrgent = isUrgentLow;
    final title = isUrgent ? '🚨 URGENT LOW GLUCOSE ALARM' : '${reading.glucoseClass.label} glucose alert';
    final body = isUrgent
        ? 'CRITICAL: Glucose at ${reading.mgDl.round()} mg/dL! Take fast-acting carbs immediately.'
        : '${reading.glucoseClass.clinicalName} — ${reading.mgDl.round()} mg/dL (${reading.confidence}% confidence)';

    _history.add(NotificationRecord(
      id: reading.glucoseClass.wireValue,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      glucoseClass: reading.glucoseClass,
      isUrgent: isUrgent,
    ));

    try {
      final channel = isUrgent ? _androidUrgentChannel : _androidStandardChannel;
      await _plugin.show(
        reading.glucoseClass.wireValue,
        title,
        body,
        NotificationDetails(
          android: channel,
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
            interruptionLevel: isUrgent ? InterruptionLevel.critical : InterruptionLevel.active,
          ),
        ),
      );
    } catch (_) {
      // Ignored in headless/test environments
    }
  }

  /// Sends a notification alerting that no reading has arrived for > 15 minutes.
  Future<void> notifyStaleData() async {
    const id = 998;
    const title = '⚠️ Glucose Data Stale';
    const body = 'No reading received for over 15 minutes. Check wearable connection.';

    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: _androidStandardChannel,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  /// Sends a local notification alerting that the wearable connection was lost.
  Future<void> notifyDisconnection({String? deviceName}) async {
    const id = 999;
    const title = 'Wearable Disconnected';
    final body = deviceName != null
        ? '$deviceName connection was lost.'
        : 'Glucose Wearable connection lost.';

    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: _androidStandardChannel,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  void reset() {
    _lastClass = null;
    _history.clear();
  }
}
