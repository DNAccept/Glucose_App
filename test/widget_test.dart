import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_monitor/core/glucose_class.dart';
import 'package:glucose_monitor/ui/widgets/state_ring.dart';
import 'package:flutter/material.dart';
import 'package:glucose_monitor/models/glucose_reading.dart';

void main() {
  testWidgets('StateRing shows the class label and mg/dL for a reading', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StateRing(
          reading: GlucoseReading(
            timestamp: DateTime(2026, 1, 1, 10, 30),
            mgDl: 132,
            glucoseClass: GlucoseClass.normal,
            confidence: 91,
          ),
        ),
      ),
    ));

    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('132 mg/dL'), findsOneWidget);
    expect(find.text('91% confidence'), findsOneWidget);
  });

  testWidgets('StateRing shows a placeholder when there is no reading yet', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StateRing(reading: null)),
    ));

    expect(find.text('No reading'), findsOneWidget);
    expect(find.text('Waiting for device'), findsOneWidget);
  });
}
