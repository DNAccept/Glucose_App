import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

part 'app_database.g.dart';

@DataClassName('ReadingRow')
class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get mgDl => real()();

  /// 0 = low, 1 = normal, 2 = high — matches [GlucoseClass.wireValue].
  IntColumn get glucoseClass => integer()();
  IntColumn get confidence => integer()();
}

@DataClassName('ReferenceRow')
class ReferenceReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get referenceValueMgDl => integer()();
  IntColumn get referenceClass => integer()();
  RealColumn get deviceMgDl => real().nullable()();
  IntColumn get deviceClass => integer().nullable()();
  IntColumn get deviceConfidence => integer().nullable()();
  DateTimeColumn get timestamp => dateTime()();
}

/// Local-only accounts: no backend exists, so registration/login just
/// checks against rows in this table. Password is never stored in the
/// clear — only a salted SHA-256 hash.
@DataClassName('UserRow')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get passwordSalt => text()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Readings, ReferenceReadings, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(users);
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
