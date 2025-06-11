import 'package:flutter_test/flutter_test.dart';
import 'package:micro_break_manager/models/micro_break_item.dart';

void main() {
  group('MicroBreakItem', () {
    test('fromTsv creates item from string', () {
      final item = MicroBreakItem.fromTsv('Cat–Camel stretch');
      expect(item.text, equals('Cat–Camel stretch'));
    });

    test('fromTsv trims whitespace', () {
      final item = MicroBreakItem.fromTsv('  Standing Back Extension  ');
      expect(item.text, equals('Standing Back Extension'));
    });

    test('toTsv returns text', () {
      const item = MicroBreakItem(text: 'Seated Pelvic Tilt');
      expect(item.toTsv(), equals('Seated Pelvic Tilt'));
    });

    test('round-trip conversion preserves data', () {
      const originalText = 'Cloud Hands';
      final item = MicroBreakItem.fromTsv(originalText);
      final serialized = item.toTsv();
      final deserialized = MicroBreakItem.fromTsv(serialized);

      expect(deserialized.text, equals(originalText));
    });

    test('equality works correctly', () {
      const item1 = MicroBreakItem(text: 'Test Item');
      const item2 = MicroBreakItem(text: 'Test Item');
      const item3 = MicroBreakItem(text: 'Different Item');

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });

    test('hashCode is consistent with equality', () {
      const item1 = MicroBreakItem(text: 'Test Item');
      const item2 = MicroBreakItem(text: 'Test Item');

      expect(item1.hashCode, equals(item2.hashCode));
    });
  });
}