import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/online_database_service.dart';
import '../data/sync_service.dart';
import 'auth_providers.dart';
import 'data_providers.dart';

final onlineDatabaseServiceProvider = Provider<OnlineDatabaseService>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  final savedUrl = settings.serverUrl;
  final savedToken = settings.authToken;
  final service = OnlineDatabaseService(
    serverUrl: (savedUrl != null && savedUrl.isNotEmpty) ? savedUrl : 'http://127.0.0.1:8080',
    authToken: savedToken,
  );
  ref.onDispose(service.dispose);
  return service;
});

class NetworkModeNotifier extends StateNotifier<bool> {
  NetworkModeNotifier(this._ref) : super(true) {
    final onlineDb = _ref.read(onlineDatabaseServiceProvider);
    state = onlineDb.isOnline;
    _sub = onlineDb.connectivityStream.listen((isOnline) {
      state = isOnline;
    });
  }

  final Ref _ref;
  StreamSubscription<bool>? _sub;

  Future<bool> recheck() async {
    final onlineDb = _ref.read(onlineDatabaseServiceProvider);
    final reachable = await onlineDb.verifyConnection();
    state = reachable;
    return reachable;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final networkModeProvider = StateNotifierProvider<NetworkModeNotifier, bool>((ref) {
  return NetworkModeNotifier(ref);
});

final networkConnectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(onlineDatabaseServiceProvider);
  return service.connectivityStream;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final onlineDb = ref.watch(onlineDatabaseServiceProvider);
  final settings = ref.watch(settingsRepositoryProvider);

  final syncService = SyncService(
    db: db,
    onlineDb: onlineDb,
    settingsRepository: settings,
  );
  ref.onDispose(syncService.dispose);
  return syncService;
});

final syncStatusProvider = StreamProvider<SyncResult>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStateStream;
});

class SyncController extends StateNotifier<SyncResult> {
  SyncController(this._ref) : super(const SyncResult(status: SyncStateStatus.idle)) {
    _ref.listen<AsyncValue<SyncResult>>(syncStatusProvider, (prev, next) {
      if (next.hasValue) {
        state = next.value!;
      }
    });
  }

  final Ref _ref;

  Future<SyncResult> triggerSync() async {
    final currentUser = _ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) {
      final res = state.copyWith(
        status: SyncStateStatus.error,
        errorMessage: 'Must be logged in to sync.',
      );
      state = res;
      return res;
    }
    final syncService = _ref.read(syncServiceProvider);
    return syncService.syncAll(currentUser.id);
  }
}

final syncControllerProvider = StateNotifierProvider<SyncController, SyncResult>((ref) {
  return SyncController(ref);
});
