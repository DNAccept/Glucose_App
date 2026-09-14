import 'dart:async';

import 'package:drift/drift.dart';

import 'app_database.dart';
import 'online_database_service.dart';
import 'settings_repository.dart';

enum SyncStateStatus { idle, syncing, success, error, offline }

class SyncResult {
  const SyncResult({
    required this.status,
    this.lastSyncedAt,
    this.pendingCount = 0,
    this.errorMessage,
    this.isOnline = true,
  });

  final SyncStateStatus status;
  final DateTime? lastSyncedAt;
  final int pendingCount;
  final String? errorMessage;
  final bool isOnline;

  SyncResult copyWith({
    SyncStateStatus? status,
    DateTime? lastSyncedAt,
    int? pendingCount,
    String? errorMessage,
    bool? isOnline,
  }) {
    return SyncResult(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingCount: pendingCount ?? this.pendingCount,
      errorMessage: errorMessage ?? this.errorMessage,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class SyncService {
  SyncService({
    required AppDatabase db,
    required OnlineDatabaseService onlineDb,
    required SettingsRepository settingsRepository,
  })  : _db = db,
        _onlineDb = onlineDb,
        _settings = settingsRepository {
    _initConnectivityListener();
    _startPeriodicAutoSyncTimer();
  }

  final AppDatabase _db;
  final OnlineDatabaseService _onlineDb;
  final SettingsRepository _settings;

  int? _activeUserId;
  Timer? _periodicTimer;

  void setActiveUserId(int? userId) {
    _activeUserId = userId;
    if (userId != null && _settings.autoSyncEnabled && _onlineDb.isOnline && _settings.cloudSyncEnabled) {
      syncAll(userId);
    }
  }

  void _startPeriodicAutoSyncTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_activeUserId != null && _settings.autoSyncEnabled && _onlineDb.isOnline && _settings.cloudSyncEnabled) {
        final pending = await getPendingSyncCount(_activeUserId!);
        if (pending > 0) {
          syncAll(_activeUserId!);
        }
      }
    });
  }

  final _syncStateController = StreamController<SyncResult>.broadcast();
  Stream<SyncResult> get syncStateStream => _syncStateController.stream;

  SyncResult _currentResult = const SyncResult(status: SyncStateStatus.idle);
  SyncResult get currentResult => _currentResult;

  void _updateState(SyncResult result) {
    _currentResult = result;
    _syncStateController.add(result);
  }

  void _initConnectivityListener() {
    _onlineDb.connectivityStream.listen((isOnline) {
      if (!isOnline) {
        _updateState(_currentResult.copyWith(
          status: SyncStateStatus.offline,
          isOnline: false,
        ));
      } else {
        _updateState(_currentResult.copyWith(
          status: SyncStateStatus.idle,
          isOnline: true,
        ));
        // Trigger auto-sync on network reconnection
        if (_activeUserId != null && _settings.autoSyncEnabled && _settings.cloudSyncEnabled) {
          syncAll(_activeUserId!);
        }
      }
    });
  }

  /// Auto-sync hook invoked whenever new local readings/references are saved.
  void onLocalDataWritten([int? userId]) {
    final uid = userId ?? _activeUserId;
    if (uid != null && _settings.autoSyncEnabled && _onlineDb.isOnline && _settings.cloudSyncEnabled) {
      syncAll(uid);
    }
  }

  Future<int> getPendingSyncCount(int localUserId) async {
    final pendingReadings = await (_db.select(_db.readings)
          ..where((t) => t.syncStatus.equals(SyncStatus.pendingSync)))
        .get();
    final pendingReferences = await (_db.select(_db.referenceReadings)
          ..where((t) => t.syncStatus.equals(SyncStatus.pendingSync)))
        .get();
    return pendingReadings.length + pendingReferences.length;
  }

  /// Synchronizes local SQLite database with Online cloud database.
  Future<SyncResult> syncAll(int localUserId) async {
    if (!_settings.cloudSyncEnabled) {
      final res = _currentResult.copyWith(
        status: SyncStateStatus.idle,
        errorMessage: 'Cloud sync is disabled in settings.',
      );
      _updateState(res);
      return res;
    }

    if (!_onlineDb.isOnline) {
      final pendingCount = await getPendingSyncCount(localUserId);
      final res = SyncResult(
        status: SyncStateStatus.offline,
        pendingCount: pendingCount,
        isOnline: false,
        lastSyncedAt: _currentResult.lastSyncedAt,
      );
      _updateState(res);
      return res;
    }

    _updateState(_currentResult.copyWith(status: SyncStateStatus.syncing));

    try {
      // 1. Get or create remote user identity
      final userRow = await (_db.select(_db.users)..where((t) => t.id.equals(localUserId))).getSingleOrNull();
      if (userRow == null) {
        throw Exception('Local user record not found for id: $localUserId');
      }

      int remoteUserId = userRow.remoteId ?? 0;
      if (remoteUserId == 0) {
        // Attempt to register or login user on online database
        try {
          final remoteUser = await _onlineDb.register(userRow.username, userRow.passwordHash, userRow.passwordSalt);
          remoteUserId = remoteUser.id;
        } on OnlineDatabaseException {
          final remoteUser = await _onlineDb.login(userRow.username, userRow.passwordHash);
          remoteUserId = remoteUser.id;
        }
        await (_db.update(_db.users)..where((t) => t.id.equals(localUserId))).write(
          UsersCompanion(
            remoteId: Value(remoteUserId),
            syncStatus: const Value(SyncStatus.synced),
            lastSyncedAt: Value(DateTime.now()),
          ),
        );
      }

      // 2. Push unsynced Readings
      final unsyncedReadings = await (_db.select(_db.readings)
            ..where((t) => t.syncStatus.equals(SyncStatus.pendingSync)))
          .get();

      if (unsyncedReadings.isNotEmpty) {
        final remoteReadings = unsyncedReadings.map((r) => RemoteReading(
              uuid: r.uuid,
              userId: remoteUserId,
              timestamp: r.timestamp,
              mgDl: r.mgDl,
              glucoseClass: r.glucoseClass,
              confidence: r.confidence,
              lastModified: r.lastModified,
              isDeleted: r.isDeleted,
            )).toList();

        await _onlineDb.pushReadings(remoteUserId, remoteReadings);

        for (final r in unsyncedReadings) {
          await (_db.update(_db.readings)..where((t) => t.id.equals(r.id))).write(
            ReadingsCompanion(
              userId: Value(localUserId),
              syncStatus: const Value(SyncStatus.synced),
            ),
          );
        }
      }

      // 3. Pull remote Readings
      final remoteReadingsList = await _onlineDb.pullReadings(remoteUserId);
      for (final rr in remoteReadingsList) {
        final local = await (_db.select(_db.readings)..where((t) => t.uuid.equals(rr.uuid))).getSingleOrNull();
        if (local == null) {
          await _db.into(_db.readings).insert(ReadingsCompanion.insert(
                uuid: Value(rr.uuid),
                userId: Value(localUserId),
                timestamp: rr.timestamp,
                mgDl: rr.mgDl,
                glucoseClass: rr.glucoseClass,
                confidence: rr.confidence,
                syncStatus: const Value(SyncStatus.synced),
                lastModified: Value(rr.lastModified),
                isDeleted: Value(rr.isDeleted),
              ));
        } else if (rr.lastModified.isAfter(local.lastModified)) {
          await (_db.update(_db.readings)..where((t) => t.id.equals(local.id))).write(
            ReadingsCompanion(
              mgDl: Value(rr.mgDl),
              glucoseClass: Value(rr.glucoseClass),
              confidence: Value(rr.confidence),
              syncStatus: const Value(SyncStatus.synced),
              lastModified: Value(rr.lastModified),
              isDeleted: Value(rr.isDeleted),
            ),
          );
        }
      }

      // 4. Push unsynced Reference Readings
      final unsyncedReferences = await (_db.select(_db.referenceReadings)
            ..where((t) => t.syncStatus.equals(SyncStatus.pendingSync)))
          .get();

      if (unsyncedReferences.isNotEmpty) {
        final remoteRefs = unsyncedReferences.map((r) => RemoteReferenceReading(
              uuid: r.uuid,
              userId: remoteUserId,
              referenceValueMgDl: r.referenceValueMgDl,
              referenceClass: r.referenceClass,
              deviceMgDl: r.deviceMgDl,
              deviceClass: r.deviceClass,
              deviceConfidence: r.deviceConfidence,
              timestamp: r.timestamp,
              lastModified: r.lastModified,
              isDeleted: r.isDeleted,
            )).toList();

        await _onlineDb.pushReferences(remoteUserId, remoteRefs);

        for (final r in unsyncedReferences) {
          await (_db.update(_db.referenceReadings)..where((t) => t.id.equals(r.id))).write(
            ReferenceReadingsCompanion(
              userId: Value(localUserId),
              syncStatus: const Value(SyncStatus.synced),
            ),
          );
        }
      }

      // 5. Pull remote Reference Readings
      final remoteRefsList = await _onlineDb.pullReferences(remoteUserId);
      for (final rr in remoteRefsList) {
        final local = await (_db.select(_db.referenceReadings)..where((t) => t.uuid.equals(rr.uuid))).getSingleOrNull();
        if (local == null) {
          await _db.into(_db.referenceReadings).insert(ReferenceReadingsCompanion.insert(
                uuid: Value(rr.uuid),
                userId: Value(localUserId),
                referenceValueMgDl: rr.referenceValueMgDl,
                referenceClass: rr.referenceClass,
                deviceMgDl: Value(rr.deviceMgDl),
                deviceClass: Value(rr.deviceClass),
                deviceConfidence: Value(rr.deviceConfidence),
                timestamp: rr.timestamp,
                syncStatus: const Value(SyncStatus.synced),
                lastModified: Value(rr.lastModified),
                isDeleted: Value(rr.isDeleted),
              ));
        } else if (rr.lastModified.isAfter(local.lastModified)) {
          await (_db.update(_db.referenceReadings)..where((t) => t.id.equals(local.id))).write(
            ReferenceReadingsCompanion(
              referenceValueMgDl: Value(rr.referenceValueMgDl),
              referenceClass: Value(rr.referenceClass),
              deviceMgDl: Value(rr.deviceMgDl),
              deviceClass: Value(rr.deviceClass),
              deviceConfidence: Value(rr.deviceConfidence),
              syncStatus: const Value(SyncStatus.synced),
              lastModified: Value(rr.lastModified),
              isDeleted: Value(rr.isDeleted),
            ),
          );
        }
      }

      // 6. Push & Pull Settings
      final localSettings = RemoteUserSettings(
        userId: remoteUserId,
        alertsEnabled: _settings.alertsEnabled,
        cloudSyncEnabled: _settings.cloudSyncEnabled,
        lastModified: DateTime.now(),
      );
      await _onlineDb.pushSettings(remoteUserId, localSettings);

      final now = DateTime.now();
      final res = SyncResult(
        status: SyncStateStatus.success,
        lastSyncedAt: now,
        pendingCount: 0,
        isOnline: true,
      );
      _updateState(res);
      return res;
    } catch (e) {
      final pendingCount = await getPendingSyncCount(localUserId);
      final res = SyncResult(
        status: SyncStateStatus.error,
        errorMessage: e.toString(),
        pendingCount: pendingCount,
        isOnline: _onlineDb.isOnline,
        lastSyncedAt: _currentResult.lastSyncedAt,
      );
      _updateState(res);
      return res;
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
    _syncStateController.close();
  }
}
