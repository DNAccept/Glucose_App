import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import 'data_providers.dart';
import 'readings_providers.dart';

/// Manages active alert snooze timer state.
class AlertSnoozeNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    return ref.watch(settingsRepositoryProvider).snoozedUntil;
  }

  bool get isSnoozed {
    if (state == null) return false;
    return DateTime.now().isBefore(state!);
  }

  Future<void> snooze(Duration duration) async {
    final until = DateTime.now().add(duration);
    await ref.read(settingsRepositoryProvider).setSnoozedUntil(until);
    state = until;
  }

  Future<void> clearSnooze() async {
    await ref.read(settingsRepositoryProvider).setSnoozedUntil(null);
    state = null;
  }
}

final alertSnoozeProvider = NotifierProvider<AlertSnoozeNotifier, DateTime?>(
  AlertSnoozeNotifier.new,
);

/// Monitors whether glucose data is stale (> 15 minutes old).
final staleDataProvider = StreamProvider<bool>((ref) async* {
  final timer = Stream<void>.periodic(const Duration(seconds: 10));

  await for (final _ in timer) {
    final latest = ref.read(latestReadingProvider).valueOrNull;
    if (latest == null) {
      yield true;
    } else {
      final diff = DateTime.now().difference(latest.timestamp);
      yield diff > const Duration(minutes: 15);
    }
  }
});
