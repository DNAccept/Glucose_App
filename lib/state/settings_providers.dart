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
