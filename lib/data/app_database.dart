import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

import '../core/uuid.dart';

part 'app_database.g.dart';

/// Sync status constants for database records.
class SyncStatus {
  static const int synced = 0;
  static const int pendingSync = 1;
  static const int syncFailed = 2;
}

@DataClassName('ReadingRow')
class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => generateUuid())();
  IntColumn get userId => integer().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get mgDl => real()();

  /// 0 = low, 1 = normal, 2 = high — matches [GlucoseClass.wireValue].
  IntColumn get glucoseClass => integer()();
  IntColumn get confidence => integer()();
  IntColumn get syncStatus => integer().withDefault(const Constant(SyncStatus.pendingSync))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('ReferenceRow')
class ReferenceReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => generateUuid())();
  IntColumn get userId => integer().nullable()();
  IntColumn get referenceValueMgDl => integer()();
  IntColumn get referenceClass => integer()();
  RealColumn get deviceMgDl => real().nullable()();
  IntColumn get deviceClass => integer().nullable()();
  IntColumn get deviceConfidence => integer().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(SyncStatus.pendingSync))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

/// Local-only & cached online user accounts.
@DataClassName('UserRow')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get passwordSalt => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(SyncStatus.pendingSync))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [Readings, ReferenceReadings, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(users);
          }
          if (from < 3) {
            await customStatement('ALTER TABLE readings ADD COLUMN uuid TEXT;');
            await customStatement('ALTER TABLE readings ADD COLUMN user_id INTEGER;');
            await customStatement('ALTER TABLE readings ADD COLUMN sync_status INTEGER NOT NULL DEFAULT 1;');
            await customStatement('ALTER TABLE readings ADD COLUMN last_modified INTEGER;');
            await customStatement('ALTER TABLE readings ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0;');

            await customStatement('ALTER TABLE reference_readings ADD COLUMN uuid TEXT;');
            await customStatement('ALTER TABLE reference_readings ADD COLUMN user_id INTEGER;');
            await customStatement('ALTER TABLE reference_readings ADD COLUMN sync_status INTEGER NOT NULL DEFAULT 1;');
            await customStatement('ALTER TABLE reference_readings ADD COLUMN last_modified INTEGER;');
            await customStatement('ALTER TABLE reference_readings ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0;');

            await customStatement('ALTER TABLE users ADD COLUMN remote_id INTEGER;');
            await customStatement('ALTER TABLE users ADD COLUMN sync_status INTEGER NOT NULL DEFAULT 1;');
            await customStatement('ALTER TABLE users ADD COLUMN last_synced_at INTEGER;');
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'glucose_monitor.sqlite'));
    final cacheBase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cacheBase;
    return NativeDatabase.createInBackground(file);
  });
}

