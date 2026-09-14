import 'package:drift/drift.dart';

import '../core/glucose_class.dart';
import '../models/glucose_reading.dart';
import '../models/reference_reading.dart';
import 'app_database.dart';

class TimeInStateFractions {
  const TimeInStateFractions({
    required this.low,
    required this.normal,
    required this.high,
    required this.count,
  });

  final double low;
  final double normal;
  final double high;
  final int count;

  static const empty = TimeInStateFractions(low: 0, normal: 0, high: 0, count: 0);
}

class AccuracySummary {
  const AccuracySummary({
    required this.confusion,
    required this.total,
    required this.agree,
    required this.meanAbsoluteErrorMgDl,
  });

  /// confusion[referenceClassIndex][deviceClassIndex]
  final List<List<int>> confusion;
  final int total;
  final int agree;

  /// Mean |finger-prick - device mgDl| over entries where the device had a
  /// reading. Null if no comparable entries exist.
  final double? meanAbsoluteErrorMgDl;

  double get agreementRate => total == 0 ? 0 : agree / total;

  static AccuracySummary empty = const AccuracySummary(
    confusion: [
      [0, 0, 0],
      [0, 0, 0],
      [0, 0, 0],
    ],
    total: 0,
    agree: 0,
    meanAbsoluteErrorMgDl: null,
  );
}

/// Persists the BLE reading stream and answers the windowed queries the UI
/// needs (mirrors the mockup's in-memory `fractions()`/`inWindow()`, but
/// backed by SQLite so history survives app restarts).
class ReadingsRepository {
  ReadingsRepository(this._db);

  final AppDatabase _db;

  Future<void> addReading(GlucoseReading reading, {int? userId}) {
    return _db.into(_db.readings).insert(ReadingsCompanion.insert(
          timestamp: reading.timestamp,
          mgDl: reading.mgDl,
          glucoseClass: reading.glucoseClass.wireValue,
          confidence: reading.confidence,
          userId: Value(userId),
          syncStatus: const Value(SyncStatus.pendingSync),
          lastModified: Value(DateTime.now()),
          isDeleted: const Value(false),
        ));
  }

  Stream<GlucoseReading?> watchLatest() {
    final query = _db.select(_db.readings)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(1);
    return query.watch().map((rows) => rows.isEmpty ? null : _toReading(rows.first));
  }

  Stream<List<GlucoseReading>> watchWindow(Duration window, {int? limit}) {
    final cutoff = DateTime.now().subtract(window);
    final query = _db.select(_db.readings)
      ..where((t) => t.timestamp.isBiggerOrEqualValue(cutoff) & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    if (limit != null) query.limit(limit);
    return query.watch().map((rows) => rows.map(_toReading).toList());
  }

  Stream<TimeInStateFractions> watchFractions(Duration window) {
    return watchWindow(window).map((readings) {
      if (readings.isEmpty) return TimeInStateFractions.empty;
      var low = 0, normal = 0, high = 0;
      for (final r in readings) {
        switch (r.glucoseClass) {
          case GlucoseClass.low:
            low++;
          case GlucoseClass.normal:
            normal++;
          case GlucoseClass.high:
            high++;
        }
      }
      final total = readings.length;
      return TimeInStateFractions(
        low: low / total,
        normal: normal / total,
        high: high / total,
        count: total,
      );
    });
  }

  Future<void> pruneOlderThan(Duration retention) {
    final cutoff = DateTime.now().subtract(retention);
    return (_db.delete(_db.readings)..where((t) => t.timestamp.isSmallerThanValue(cutoff))).go();
  }

  GlucoseReading _toReading(ReadingRow row) => GlucoseReading(
        id: row.id,
        timestamp: row.timestamp,
        mgDl: row.mgDl,
        glucoseClass: GlucoseClass.fromWireValue(row.glucoseClass),
        confidence: row.confidence,
      );
}

/// Manages the finger-prick reference log and the resulting accuracy stats.
class ReferenceRepository {
  ReferenceRepository(this._db);

  final AppDatabase _db;

  Future<void> addReference(ReferenceReading reading, {int? userId}) {
    return _db.into(_db.referenceReadings).insert(ReferenceReadingsCompanion.insert(
          referenceValueMgDl: reading.referenceValueMgDl,
          referenceClass: reading.referenceClass.wireValue,
          deviceMgDl: Value(reading.deviceMgDl),
          deviceClass: Value(reading.deviceClass?.wireValue),
          deviceConfidence: Value(reading.deviceConfidence),
          timestamp: reading.timestamp,
          userId: Value(userId),
          syncStatus: const Value(SyncStatus.pendingSync),
          lastModified: Value(DateTime.now()),
          isDeleted: const Value(false),
        ));
  }

  Future<void> deleteReference(int id) {
    return (_db.update(_db.referenceReadings)..where((t) => t.id.equals(id))).write(
      ReferenceReadingsCompanion(
        isDeleted: const Value(true),
        syncStatus: const Value(SyncStatus.pendingSync),
        lastModified: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<ReferenceReading>> watchAll() {
    final query = _db.select(_db.referenceReadings)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    return query.watch().map((rows) => rows.map(_toReference).toList());
  }

  Stream<AccuracySummary> watchAccuracy() {
    return watchAll().map((entries) {
      final confusion = [
        [0, 0, 0],
        [0, 0, 0],
        [0, 0, 0],
      ];
      var total = 0, agree = 0;
      final errors = <double>[];
      for (final e in entries) {
        if (e.deviceClass == null) continue;
        confusion[e.referenceClass.wireValue][e.deviceClass!.wireValue]++;
        total++;
        if (e.referenceClass == e.deviceClass) agree++;
        if (e.deviceMgDl != null) {
          errors.add((e.referenceValueMgDl - e.deviceMgDl!).abs());
        }
      }
      final mae = errors.isEmpty ? null : errors.reduce((a, b) => a + b) / errors.length;
      return AccuracySummary(
        confusion: confusion,
        total: total,
        agree: agree,
        meanAbsoluteErrorMgDl: mae,
      );
    });
  }

  ReferenceReading _toReference(ReferenceRow row) => ReferenceReading(
        id: row.id,
        referenceValueMgDl: row.referenceValueMgDl,
        referenceClass: GlucoseClass.fromWireValue(row.referenceClass),
        deviceMgDl: row.deviceMgDl,
        deviceClass: row.deviceClass == null ? null : GlucoseClass.fromWireValue(row.deviceClass!),
        deviceConfidence: row.deviceConfidence,
        timestamp: row.timestamp,
      );
}
