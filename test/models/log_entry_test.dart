import 'package:flutter_test/flutter_test.dart';
import 'package:micro_break_manager/models/log_entry.dart';

void main() {
  group('LogEntry', () {
    test('fromTsv parses valid log entry', () {
      const line = '2025-06-12\t10:35:12\t10:40:05\tstretching\tCat–Camel stretch';
      final entry = LogEntry.fromTsv(line);

      expect(entry.start, equals(DateTime(2025, 6, 12, 10, 35, 12)));
      expect(entry.end, equals(DateTime(2025, 6, 12, 10, 40, 5)));
      expect(entry.listName, equals('stretching'));
      expect(entry.itemText, equals('Cat–Camel stretch'));
    });

    test('fromTsv throws on invalid format', () {
      const invalidLine = '2025-06-12\t10:35:12\t10:40:05';
      
      expect(
        () => LogEntry.fromTsv(invalidLine),
        throwsFormatException,
      );
    });

    test('toTsv formats entry correctly', () {
      final entry = LogEntry(
        start: DateTime(2025, 6, 12, 14, 3, 20),
        end: DateTime(2025, 6, 12, 14, 5, 0),
        listName: 'tai_chi',
        itemText: 'Cloud Hands',
      );

      final tsv = entry.toTsv();
      expect(tsv, equals('2025-06-12\t14:03:20\t14:05:00\ttai_chi\tCloud Hands'));
    });

    test('toTsv pads single digit values', () {
      final entry = LogEntry(
        start: DateTime(2025, 1, 2, 3, 4, 5),
        end: DateTime(2025, 1, 2, 3, 6, 7),
        listName: 'test',
        itemText: 'Test Item',
      );

      final tsv = entry.toTsv();
      expect(tsv, equals('2025-01-02\t03:04:05\t03:06:07\ttest\tTest Item'));
    });

    test('round-trip conversion preserves data', () {
      final original = LogEntry(
        start: DateTime(2025, 6, 12, 10, 35, 12),
        end: DateTime(2025, 6, 12, 10, 40, 5),
        listName: 'stretching',
        itemText: 'Cat–Camel stretch',
      );

      final tsv = original.toTsv();
      final reconstructed = LogEntry.fromTsv(tsv);

      expect(reconstructed.start, equals(original.start));
      expect(reconstructed.end, equals(original.end));
      expect(reconstructed.listName, equals(original.listName));
      expect(reconstructed.itemText, equals(original.itemText));
    });

    test('duration calculates correctly', () {
      final entry = LogEntry(
        start: DateTime(2025, 6, 12, 10, 35, 12),
        end: DateTime(2025, 6, 12, 10, 40, 5),
        listName: 'stretching',
        itemText: 'Cat–Camel stretch',
      );

      expect(entry.duration, equals(const Duration(minutes: 4, seconds: 53)));
    });

    test('equality works correctly', () {
      final entry1 = LogEntry(
        start: DateTime(2025, 6, 12, 10, 35, 12),
        end: DateTime(2025, 6, 12, 10, 40, 5),
        listName: 'stretching',
        itemText: 'Cat–Camel stretch',
      );

      final entry2 = LogEntry(
        start: DateTime(2025, 6, 12, 10, 35, 12),
        end: DateTime(2025, 6, 12, 10, 40, 5),
        listName: 'stretching',
        itemText: 'Cat–Camel stretch',
      );

      final entry3 = LogEntry(
        start: DateTime(2025, 6, 12, 10, 35, 12),
        end: DateTime(2025, 6, 12, 10, 40, 5),
        listName: 'different',
        itemText: 'Cat–Camel stretch',
      );

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
    });

    test('hashCode is consistent with equality', () {
      final entry1 = LogEntry(
        start: DateTime(2025, 6, 12, 10, 35, 12),
        end: DateTime(2025, 6, 12, 10, 40, 5),
        listName: 'stretching',
        itemText: 'Cat–Camel stretch',
      );

      final entry2 = LogEntry(
        start: DateTime(2025, 6, 12, 10, 35, 12),
        end: DateTime(2025, 6, 12, 10, 40, 5),
        listName: 'stretching',
        itemText: 'Cat–Camel stretch',
      );

      expect(entry1.hashCode, equals(entry2.hashCode));
    });
  });
}