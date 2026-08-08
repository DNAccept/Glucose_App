import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_monitor/ui/widgets/duration_picker_sheet.dart';

void main() {
  group('formatDuration', () {
    test('minutes under an hour', () {
      expect(formatDuration(const Duration(minutes: 30)), '30m');
      expect(formatDuration(const Duration(minutes: 5)), '5m');
    });

    test('whole hours', () {
      expect(formatDuration(const Duration(hours: 3)), '3h');
      expect(formatDuration(const Duration(hours: 24)), '1d');
    });

    test('hours with leftover minutes', () {
      expect(formatDuration(const Duration(hours: 2, minutes: 30)), '2h 30m');
    });

    test('days with leftover hours', () {
      expect(formatDuration(const Duration(days: 5, hours: 12)), '5d 12h');
    });

    test('whole days', () {
      expect(formatDuration(const Duration(days: 30)), '30d');
    });
  });
}
