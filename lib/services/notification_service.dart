import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/glucose_class.dart';
import '../models/glucose_reading.dart';

/// Fires a local alert only when the reported class transitions into
/// low/high (edge-triggered), not on every reading — a stream of
/// "still low" notifications would be noise rather than a warning.
class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  GlucoseClass? _lastClass;
  bool _initialized = false;

  static const _androidChannel = AndroidNotificationDetails(
    'glucose_alerts',
    'Glucose alerts',
    channelDescription: 'Low and high glucose state alerts',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (_initialized) return;
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
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Call on every new reading; only notifies on a low/high transition.
  Future<void> onReading(GlucoseReading reading, {required bool alertsEnabled}) async {
    final previous = _lastClass;
    _lastClass = reading.glucoseClass;
    if (!alertsEnabled) return;
    if (reading.glucoseClass == GlucoseClass.normal) return;
    if (previous == reading.glucoseClass) return; // already alerted for this episode

    await _plugin.show(
      reading.glucoseClass.wireValue,
      '${reading.glucoseClass.label} glucose',
      '${reading.glucoseClass.clinicalName} — ${reading.mgDl.round()} mg/dL '
          '(${reading.confidence}% confidence)',
      const NotificationDetails(
        android: _androidChannel,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void reset() => _lastClass = null;
}
