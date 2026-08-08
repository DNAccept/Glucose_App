import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_monitor/core/glucose_class.dart';
import 'package:glucose_monitor/data/app_database.dart';
import 'package:glucose_monitor/data/readings_repository.dart';
import 'package:glucose_monitor/models/glucose_reading.dart';
import 'package:glucose_monitor/models/reference_reading.dart';

void main() {
  late AppDatabase db;
  late ReadingsRepository readings;
  late ReferenceRepository references;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    readings = ReadingsRepository(db);
    references = ReferenceRepository(db);
  });

  tearDown(() => db.close());

  test('watchFractions computes low/normal/high proportions over the window', () async {
    final now = DateTime.now();
    await readings.addReading(GlucoseReading(timestamp: now, mgDl: 60, glucoseClass: GlucoseClass.low, confidence: 90));
    await readings.addReading(GlucoseReading(timestamp: now, mgDl: 110, glucoseClass: GlucoseClass.normal, confidence: 90));
    await readings.addReading(GlucoseReading(timestamp: now, mgDl: 115, glucoseClass: GlucoseClass.normal, confidence: 90));
    await readings.addReading(GlucoseReading(timestamp: now, mgDl: 200, glucoseClass: GlucoseClass.high, confidence: 90));

    final fractions = await readings.watchFractions(const Duration(hours: 24)).first;

    expect(fractions.count, 4);
    expect(fractions.low, closeTo(0.25, 0.001));
    expect(fractions.normal, closeTo(0.5, 0.001));
    expect(fractions.high, closeTo(0.25, 0.001));
  });

  test('watchWindow excludes readings older than the window', () async {
    final now = DateTime.now();
    await readings.addReading(GlucoseReading(
        timestamp: now.subtract(const Duration(hours: 30)), mgDl: 110, glucoseClass: GlucoseClass.normal, confidence: 90));
    await readings.addReading(GlucoseReading(timestamp: now, mgDl: 115, glucoseClass: GlucoseClass.normal, confidence: 90));

    final windowed = await readings.watchWindow(const Duration(hours: 24)).first;

    expect(windowed.length, 1);
  });

  test('watchAccuracy computes agreement rate, confusion matrix, and mean absolute error', () async {
    final now = DateTime.now();
    // Agrees: reference normal, device normal, off by 5 mg/dL.
    await references.addReference(ReferenceReading(
      referenceValueMgDl: 110,
      referenceClass: GlucoseClass.normal,
      deviceMgDl: 115,
      deviceClass: GlucoseClass.normal,
      deviceConfidence: 88,
      timestamp: now,
    ));
    // Disagrees: reference high, device normal, off by 40 mg/dL.
    await references.addReference(ReferenceReading(
      referenceValueMgDl: 190,
      referenceClass: GlucoseClass.high,
      deviceMgDl: 150,
      deviceClass: GlucoseClass.normal,
      deviceConfidence: 70,
      timestamp: now,
    ));
    // No device reading at the time -> excluded from accuracy stats.
    await references.addReference(ReferenceReading(
      referenceValueMgDl: 95,
      referenceClass: GlucoseClass.normal,
      timestamp: now,
    ));

    final summary = await references.watchAccuracy().first;

    expect(summary.total, 2);
    expect(summary.agree, 1);
    expect(summary.agreementRate, closeTo(0.5, 0.001));
    expect(summary.confusion[GlucoseClass.normal.wireValue][GlucoseClass.normal.wireValue], 1);
    expect(summary.confusion[GlucoseClass.high.wireValue][GlucoseClass.normal.wireValue], 1);
    expect(summary.meanAbsoluteErrorMgDl, closeTo((5 + 40) / 2, 0.001));
  });

  test('deleteReference removes the entry', () async {
    await references.addReference(ReferenceReading(
      referenceValueMgDl: 100,
      referenceClass: GlucoseClass.normal,
      timestamp: DateTime.now(),
    ));
    final before = await references.watchAll().first;
    expect(before.length, 1);

    await references.deleteReference(before.first.id!);
    final after = await references.watchAll().first;
    expect(after, isEmpty);
  });
}
