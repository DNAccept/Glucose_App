import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync_service.dart';
import 'data_providers.dart';
import 'sync_providers.dart';

/// Exposes the active real-time network connectivity status (true = online/reachable, false = offline/local mode).
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final onlineDb = ref.watch(onlineDatabaseServiceProvider);
  return onlineDb.connectivityStream;
});

/// Exposes whether the app is currently connected to the online database server.
final isOnlineProvider = Provider<bool>((ref) {
  final onlineDb = ref.watch(onlineDatabaseServiceProvider);
  final asyncVal = ref.watch(connectivityStatusProvider);
  return asyncVal.value ?? onlineDb.isOnline;
});

/// Exposes current SyncResult state from SyncService.
final syncResultStreamProvider = StreamProvider<SyncResult>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStateStream;
});

/// Current sync state (idle, syncing, success, error, offline).
final syncStatusStateProvider = Provider<SyncStateStatus>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  if (!isOnline) return SyncStateStatus.offline;

  final asyncResult = ref.watch(syncResultStreamProvider);
  final current = ref.watch(syncServiceProvider).currentResult;
  return asyncResult.value?.status ?? current.status;
});
