import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data_providers.dart';

class AlertsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).alertsEnabled;

  Future<void> set(bool value) async {
    await ref.read(settingsRepositoryProvider).setAlertsEnabled(value);
    state = value;
  }
}

final alertsEnabledProvider = NotifierProvider<AlertsEnabledNotifier, bool>(
  AlertsEnabledNotifier.new,
);

class CloudSyncEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).cloudSyncEnabled;

  Future<void> set(bool value) async {
    await ref.read(settingsRepositoryProvider).setCloudSyncEnabled(value);
    state = value;
  }
}

final cloudSyncEnabledProvider = NotifierProvider<CloudSyncEnabledNotifier, bool>(
  CloudSyncEnabledNotifier.new,
);

class AutoSyncEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).autoSyncEnabled;

  Future<void> set(bool value) async {
    await ref.read(settingsRepositoryProvider).setAutoSyncEnabled(value);
    state = value;
  }
}

final autoSyncEnabledProvider = NotifierProvider<AutoSyncEnabledNotifier, bool>(
  AutoSyncEnabledNotifier.new,
);

// Thresholds & Snooze preferences
class LowThresholdNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(settingsRepositoryProvider).lowThresholdMgDl;

  Future<void> set(int value) async {
    await ref.read(settingsRepositoryProvider).setLowThresholdMgDl(value);
    state = value;
  }
}

final lowThresholdProvider = NotifierProvider<LowThresholdNotifier, int>(LowThresholdNotifier.new);

class HighThresholdNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(settingsRepositoryProvider).highThresholdMgDl;

  Future<void> set(int value) async {
    await ref.read(settingsRepositoryProvider).setHighThresholdMgDl(value);
    state = value;
  }
}

final highThresholdProvider = NotifierProvider<HighThresholdNotifier, int>(HighThresholdNotifier.new);

class UrgentLowThresholdNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(settingsRepositoryProvider).urgentLowThresholdMgDl;

  Future<void> set(int value) async {
    await ref.read(settingsRepositoryProvider).setUrgentLowThresholdMgDl(value);
    state = value;
  }
}

final urgentLowThresholdProvider = NotifierProvider<UrgentLowThresholdNotifier, int>(UrgentLowThresholdNotifier.new);

class DefaultSnoozeDurationNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(settingsRepositoryProvider).defaultSnoozeMinutes;

  Future<void> set(int value) async {
    await ref.read(settingsRepositoryProvider).setDefaultSnoozeMinutes(value);
    state = value;
  }
}

final defaultSnoozeDurationProvider = NotifierProvider<DefaultSnoozeDurationNotifier, int>(DefaultSnoozeDurationNotifier.new);
