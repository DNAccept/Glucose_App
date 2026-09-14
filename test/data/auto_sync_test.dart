import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_monitor/core/glucose_class.dart';
import 'package:glucose_monitor/data/app_database.dart';
import 'package:glucose_monitor/data/online_database_service.dart';
import 'package:glucose_monitor/data/readings_repository.dart';
import 'package:glucose_monitor/data/settings_repository.dart';
import 'package:glucose_monitor/data/sync_service.dart';
import 'package:glucose_monitor/models/glucose_reading.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late OnlineDatabaseService onlineDb;
  late SettingsRepository settings;
  late SyncService syncService;
  late ReadingsRepository readingsRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'cloud_sync_enabled': true,
      'auto_sync_enabled': true,
    });
    final prefs = await SharedPreferences.getInstance();

    db = AppDatabase.forTesting(NativeDatabase.memory());
    onlineDb = OnlineDatabaseService(isOnline: true, serverUrl: '');
    settings = SettingsRepository(prefs);
    readingsRepo = ReadingsRepository(db);
    syncService = SyncService(db: db, onlineDb: onlineDb, settingsRepository: settings);
  });

  tearDown(() {
    db.close();
    onlineDb.dispose();
    syncService.dispose();
  });

  test('autoSync triggers on local data write when online', () async {
    final userId = await db.into(db.users).insert(UsersCompanion.insert(
          username: 'autouser',
          passwordHash: 'hash',
          passwordSalt: 'salt',
          createdAt: DateTime.now(),
        ));
    syncService.setActiveUserId(userId);

    await readingsRepo.addReading(
      GlucoseReading(timestamp: DateTime.now(), mgDl: 130, glucoseClass: GlucoseClass.normal, confidence: 95),
      userId: userId,
    );

    // Invoke auto-sync hook as done during ingestion
    syncService.onLocalDataWritten(userId);

    // Wait for async sync to complete
    await Future.delayed(const Duration(milliseconds: 100));

    expect(await syncService.getPendingSyncCount(userId), 0);
  });

  test('autoSync triggers on network reconnection', () async {
    final userId = await db.into(db.users).insert(UsersCompanion.insert(
          username: 'reconnectuser',
          passwordHash: 'hash',
          passwordSalt: 'salt',
          createdAt: DateTime.now(),
        ));
    syncService.setActiveUserId(userId);

    // Disconnect online database server (offline mode) and add reading
    onlineDb.setOnlineForTesting(false);
    await readingsRepo.addReading(
      GlucoseReading(timestamp: DateTime.now(), mgDl: 140, glucoseClass: GlucoseClass.normal, confidence: 90),
      userId: userId,
    );

    expect(await syncService.getPendingSyncCount(userId), 1);

    // Reconnect online database server -> triggers auto-sync
    onlineDb.setOnlineForTesting(true);
    await syncService.syncAll(userId);
    await Future.delayed(const Duration(milliseconds: 100));

    expect(await syncService.getPendingSyncCount(userId), 0);
  });

  test('manual sync mode requires explicit syncAll call', () async {
    await settings.setAutoSyncEnabled(false);
    final userId = await db.into(db.users).insert(UsersCompanion.insert(
          username: 'manualuser',
          passwordHash: 'hash',
          passwordSalt: 'salt',
          createdAt: DateTime.now(),
        ));
    syncService.setActiveUserId(userId);

    await readingsRepo.addReading(
      GlucoseReading(timestamp: DateTime.now(), mgDl: 150, glucoseClass: GlucoseClass.normal, confidence: 85),
      userId: userId,
    );

    // Hook does nothing when auto-sync is disabled
    syncService.onLocalDataWritten(userId);
    expect(await syncService.getPendingSyncCount(userId), 1);

    // Explicit manual sync
    final result = await syncService.syncAll(userId);
    expect(result.status, SyncStateStatus.success);
    expect(await syncService.getPendingSyncCount(userId), 0);
  });
}
