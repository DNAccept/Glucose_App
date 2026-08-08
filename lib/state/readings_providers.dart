import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/readings_repository.dart';
import '../models/glucose_reading.dart';
import '../models/reference_reading.dart';
import 'ble_providers.dart';
import 'data_providers.dart';
import 'settings_providers.dart';

/// Lower/upper bounds for the custom History time-range picker.
const historyWindowMin = Duration(minutes: 30);
const historyWindowMax = Duration(days: 30);

/// Quick-select presets shown as chips in the picker, all within
/// [historyWindowMin]..[historyWindowMax].
const historyWindowPresets = [
  Duration(minutes: 30),
  Duration(hours: 1),
  Duration(hours: 3),
  Duration(hours: 6),
  Duration(hours: 12),
  Duration(hours: 24),
  Duration(days: 3),
  Duration(days: 7),
  Duration(days: 14),
  Duration(days: 30),
];

final historyWindowProvider = StateProvider<Duration>((ref) => const Duration(hours: 24));

final latestReadingProvider = StreamProvider<GlucoseReading?>((ref) {
  return ref.watch(readingsRepositoryProvider).watchLatest();
});

final windowedReadingsProvider = StreamProvider<List<GlucoseReading>>((ref) {
  final window = ref.watch(historyWindowProvider);
  return ref.watch(readingsRepositoryProvider).watchWindow(window);
});

final fractionsProvider = StreamProvider.family<TimeInStateFractions, Duration>((ref, window) {
  return ref.watch(readingsRepositoryProvider).watchFractions(window);
});

final referencesProvider = StreamProvider<List<ReferenceReading>>((ref) {
  return ref.watch(referenceRepositoryProvider).watchAll();
});

final accuracyProvider = StreamProvider<AccuracySummary>((ref) {
  return ref.watch(referenceRepositoryProvider).watchAccuracy();
});

/// Bridges the live BLE reading stream into storage + alerting. Kept alive
/// for the lifetime of the app by being watched once from [RootShell].
final readingsIngestProvider = Provider<void>((ref) {
  final ble = ref.watch(bleManagerProvider);
  final repo = ref.watch(readingsRepositoryProvider);
  final notifications = ref.watch(notificationServiceProvider);

  final sub = ble.readings.listen((reading) async {
    await repo.addReading(reading);
    final alertsEnabled = ref.read(alertsEnabledProvider);
    await notifications.onReading(reading, alertsEnabled: alertsEnabled);
  });
  ref.onDispose(sub.cancel);
});
