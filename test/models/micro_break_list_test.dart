import 'package:flutter_test/flutter_test.dart';
import 'package:micro_break_manager/models/micro_break_list.dart';
import 'package:micro_break_manager/models/micro_break_item.dart';

void main() {
  group('MicroBreakList', () {
    test('fromTsvLines creates list from lines', () {
      final lines = [
        'Cat–Camel stretch',
        'Standing Back Extension',
        'Seated Pelvic Tilt',
      ];

      final list = MicroBreakList.fromTsvLines('stretching', lines);

      expect(list.name, equals('stretching'));
      expect(list.items.length, equals(3));
      expect(list.items[0].text, equals('Cat–Camel stretch'));
      expect(list.items[1].text, equals('Standing Back Extension'));
      expect(list.items[2].text, equals('Seated Pelvic Tilt'));
    });

    test('fromTsvLines preserves empty lines', () {
      final lines = [
        'Item 1',
        '',
        '  ',
        'Item 2',
      ];

      final list = MicroBreakList.fromTsvLines('test', lines);

      expect(list.items.length, equals(4));
      expect(list.items[0].text, equals('Item 1'));
      expect(list.items[1].text, equals(''));
      expect(list.items[2].text, equals('  '));
      expect(list.items[3].text, equals('Item 2'));
    });

    test('toTsvLines returns lines', () {
      final list = MicroBreakList(
        name: 'test',
        items: const [
          MicroBreakItem(text: 'Item 1'),
          MicroBreakItem(text: 'Item 2'),
        ],
      );

      final lines = list.toTsvLines();

      expect(lines.length, equals(2));
      expect(lines[0], equals('Item 1'));
      expect(lines[1], equals('Item 2'));
    });

    test('currentItem returns correct item', () {
      final list = MicroBreakList(
        name: 'test',
        items: const [
          MicroBreakItem(text: 'Item 1'),
          MicroBreakItem(text: 'Item 2'),
        ],
        currentIndex: 0,
      );

      expect(list.currentItem?.text, equals('Item 1'));
    });

    test('currentItem returns null for empty list', () {
      final list = MicroBreakList(
        name: 'test',
        items: const [],
      );

      expect(list.currentItem, isNull);
    });

    test('currentItem wraps around if index is out of bounds', () {
      final list = MicroBreakList(
        name: 'test',
        items: const [
          MicroBreakItem(text: 'Item 1'),
          MicroBreakItem(text: 'Item 2'),
        ],
        currentIndex: 5,
      );

      expect(list.currentItem?.text, equals('Item 1'));
      expect(list.currentIndex, equals(0));
    });

    test('moveToNext advances index', () {
      final list = MicroBreakList(
        name: 'test',
        items: const [
          MicroBreakItem(text: 'Item 1'),
          MicroBreakItem(text: 'Item 2'),
          MicroBreakItem(text: 'Item 3'),
        ],
        currentIndex: 0,
      );

      expect(list.currentItem?.text, equals('Item 1'));

      list.moveToNext();
      expect(list.currentIndex, equals(1));
      expect(list.currentItem?.text, equals('Item 2'));

      list.moveToNext();
      expect(list.currentIndex, equals(2));
      expect(list.currentItem?.text, equals('Item 3'));
    });

    test('moveToNext wraps around at end', () {
      final list = MicroBreakList(
        name: 'test',
        items: const [
          MicroBreakItem(text: 'Item 1'),
          MicroBreakItem(text: 'Item 2'),
        ],
        currentIndex: 1,
      );

      list.moveToNext();
      expect(list.currentIndex, equals(0));
      expect(list.currentItem?.text, equals('Item 1'));
    });

    test('moveToNext does nothing for empty list', () {
      final list = MicroBreakList(
        name: 'test',
        items: const [],
        currentIndex: 0,
      );

      list.moveToNext();
      expect(list.currentIndex, equals(0));
    });

    test('round-trip conversion preserves data', () {
      final originalLines = [
        'Item 1',
        'Item 2',
        'Item 3',
      ];

      final list = MicroBreakList.fromTsvLines('test', originalLines);
      final serializedLines = list.toTsvLines();
      final reconstructedList = MicroBreakList.fromTsvLines('test', serializedLines);

      expect(reconstructedList.items.length, equals(list.items.length));
      for (var i = 0; i < list.items.length; i++) {
        expect(reconstructedList.items[i].text, equals(list.items[i].text));
      }
    });

    test('blank lines are recognized as blank', () {
      final lines = [
        'Item 1',
        '',
        '   ',
        '\t',
        'Item 2',
      ];

      final list = MicroBreakList.fromTsvLines('test', lines);

      expect(list.items[0].isBlank, isFalse);
      expect(list.items[1].isBlank, isTrue);
      expect(list.items[2].isBlank, isTrue);
      expect(list.items[3].isBlank, isTrue);
      expect(list.items[4].isBlank, isFalse);
    });
  });
}