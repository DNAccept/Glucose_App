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
    SharedPreferences.setMockInitialValues({'cloud_sync_enabled': true});
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

  test('syncAll pushes pending local readings to cloud database and updates syncStatus', () async {
    // 1. Create local user
    final localUserId = await db.into(db.users).insert(UsersCompanion.insert(
          username: 'syncuser',
          passwordHash: 'hash',
          passwordSalt: 'salt',
          createdAt: DateTime.now(),
        ));

    // 2. Add local reading while offline
    onlineDb.setOnlineForTesting(false);
    await readingsRepo.addReading(
      GlucoseReading(timestamp: DateTime.now(), mgDl: 125, glucoseClass: GlucoseClass.normal, confidence: 90),
      userId: localUserId,
    );

    expect(await syncService.getPendingSyncCount(localUserId), 1);

    // 3. Connect online server and run sync
    onlineDb.setOnlineForTesting(true);
    final result = await syncService.syncAll(localUserId);

    expect(result.status, SyncStateStatus.success);
    expect(await syncService.getPendingSyncCount(localUserId), 0);

    // 4. Verify record was stored in cloud
    final userRow = await (db.select(db.users)..where((t) => t.id.equals(localUserId))).getSingle();
    final cloudReadings = await onlineDb.pullReadings(userRow.remoteId!);
    expect(cloudReadings.length, 1);
    expect(cloudReadings.first.mgDl, 125.0);
  });

  test('syncAll returns offline status when network connection is disabled', () async {
    final localUserId = await db.into(db.users).insert(UsersCompanion.insert(
          username: 'offlineuser',
          passwordHash: 'hash',
          passwordSalt: 'salt',
          createdAt: DateTime.now(),
        ));

    onlineDb.setOnlineForTesting(false);
    final result = await syncService.syncAll(localUserId);

    expect(result.status, SyncStateStatus.offline);
    expect(result.isOnline, false);
  });
}
