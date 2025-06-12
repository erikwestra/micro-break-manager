import 'package:flutter_test/flutter_test.dart';
import 'package:micro_break_manager/services/round_robin_manager.dart';
import 'package:micro_break_manager/models/micro_break_list.dart';
import 'package:micro_break_manager/models/micro_break_item.dart';

void main() {
  group('RoundRobinManager', () {
    test('throws ArgumentError when created with empty lists', () {
      expect(
        () => RoundRobinManager(lists: []),
        throwsArgumentError,
      );
    });

    test('cycles through two lists with different lengths correctly', () {
      final listA = MicroBreakList(
        name: 'A',
        items: const [
          MicroBreakItem(text: 'A1'),
          MicroBreakItem(text: 'A2'),
        ],
      );
      
      final listB = MicroBreakList(
        name: 'B',
        items: const [
          MicroBreakItem(text: 'B1'),
        ],
      );
      
      final manager = RoundRobinManager(lists: [listA, listB]);
      
      // Expected order: A1, B1, A2, B1, A1, B1...
      expect(manager.nextItem()?.item.text, equals('A1'));
      expect(manager.nextItem()?.item.text, equals('B1'));
      expect(manager.nextItem()?.item.text, equals('A2'));
      expect(manager.nextItem()?.item.text, equals('B1'));
      expect(manager.nextItem()?.item.text, equals('A1'));
      expect(manager.nextItem()?.item.text, equals('B1'));
    });

    test('skips empty lists', () {
      final listA = MicroBreakList(
        name: 'A',
        items: const [
          MicroBreakItem(text: 'A1'),
        ],
      );
      
      final listB = MicroBreakList(
        name: 'B',
        items: const [], // Empty list
      );
      
      final listC = MicroBreakList(
        name: 'C',
        items: const [
          MicroBreakItem(text: 'C1'),
        ],
      );
      
      final manager = RoundRobinManager(lists: [listA, listB, listC]);
      
      // Should skip B entirely
      expect(manager.nextItem()?.item.text, equals('A1'));
      expect(manager.nextItem()?.item.text, equals('C1'));
      expect(manager.nextItem()?.item.text, equals('A1'));
      expect(manager.nextItem()?.item.text, equals('C1'));
    });

    test('returns null when all lists are empty', () {
      final listA = MicroBreakList(name: 'A', items: const []);
      final listB = MicroBreakList(name: 'B', items: const []);
      
      final manager = RoundRobinManager(lists: [listA, listB]);
      
      expect(manager.nextItem(), isNull);
    });

    test('cancelSelection rolls back list and item indices', () {
      final listA = MicroBreakList(
        name: 'A',
        items: const [
          MicroBreakItem(text: 'A1'),
          MicroBreakItem(text: 'A2'),
        ],
      );
      
      final listB = MicroBreakList(
        name: 'B',
        items: const [
          MicroBreakItem(text: 'B1'),
          MicroBreakItem(text: 'B2'),
        ],
      );
      
      final manager = RoundRobinManager(lists: [listA, listB]);
      
      // Get first item
      expect(manager.nextItem()?.item.text, equals('A1'));
      
      // Cancel it
      manager.cancelSelection();
      
      // Should get the same item again
      expect(manager.nextItem()?.item.text, equals('A1'));
      
      // Continue normally
      expect(manager.nextItem()?.item.text, equals('B1'));
      expect(manager.nextItem()?.item.text, equals('A2'));
      
      // Cancel again
      manager.cancelSelection();
      
      // Should get A2 again
      expect(manager.nextItem()?.item.text, equals('A2'));
    });

    test('cancelSelection does nothing when called without prior nextItem', () {
      final listA = MicroBreakList(
        name: 'A',
        items: const [
          MicroBreakItem(text: 'A1'),
        ],
      );
      
      final manager = RoundRobinManager(lists: [listA]);
      
      // Cancel without getting an item first
      manager.cancelSelection();
      
      // Should still start from the beginning
      expect(manager.nextItem()?.item.text, equals('A1'));
    });

    test('getIndicesState returns current state', () {
      final listA = MicroBreakList(
        name: 'A',
        items: const [
          MicroBreakItem(text: 'A1'),
          MicroBreakItem(text: 'A2'),
        ],
      );
      
      final listB = MicroBreakList(
        name: 'B',
        items: const [
          MicroBreakItem(text: 'B1'),
        ],
      );
      
      final manager = RoundRobinManager(lists: [listA, listB]);
      
      // Initial state
      var state = manager.getIndicesState();
      expect(state['listIndex'], equals(0));
      expect(state['list_A_itemIndex'], equals(0));
      expect(state['list_B_itemIndex'], equals(0));
      
      // After getting some items
      manager.nextItem(); // A1
      manager.nextItem(); // B1
      
      state = manager.getIndicesState();
      expect(state['listIndex'], equals(0)); // Back to A
      expect(state['list_A_itemIndex'], equals(1)); // A moved to next
      expect(state['list_B_itemIndex'], equals(0)); // B wrapped around
    });

    test('restoreIndicesState restores saved state', () {
      final listA = MicroBreakList(
        name: 'A',
        items: const [
          MicroBreakItem(text: 'A1'),
          MicroBreakItem(text: 'A2'),
        ],
      );
      
      final listB = MicroBreakList(
        name: 'B',
        items: const [
          MicroBreakItem(text: 'B1'),
          MicroBreakItem(text: 'B2'),
        ],
      );
      
      final manager1 = RoundRobinManager(lists: [listA, listB]);
      
      // Get some items to advance state
      manager1.nextItem(); // A1
      manager1.nextItem(); // B1
      manager1.nextItem(); // A2
      
      // Save state
      final savedState = manager1.getIndicesState();
      
      // Create new manager with fresh lists
      final listA2 = MicroBreakList(
        name: 'A',
        items: const [
          MicroBreakItem(text: 'A1'),
          MicroBreakItem(text: 'A2'),
        ],
      );
      
      final listB2 = MicroBreakList(
        name: 'B',
        items: const [
          MicroBreakItem(text: 'B1'),
          MicroBreakItem(text: 'B2'),
        ],
      );
      
      final manager2 = RoundRobinManager(lists: [listA2, listB2]);
      
      // Restore state
      manager2.restoreIndicesState(savedState);
      
      // Should continue from where we left off
      expect(manager2.nextItem()?.item.text, equals('B2'));
      expect(manager2.nextItem()?.item.text, equals('A1'));
    });

    test('handles single list correctly', () {
      final list = MicroBreakList(
        name: 'Single',
        items: const [
          MicroBreakItem(text: 'Item 1'),
          MicroBreakItem(text: 'Item 2'),
          MicroBreakItem(text: 'Item 3'),
        ],
      );
      
      final manager = RoundRobinManager(lists: [list]);
      
      expect(manager.nextItem()?.item.text, equals('Item 1'));
      expect(manager.nextItem()?.item.text, equals('Item 2'));
      expect(manager.nextItem()?.item.text, equals('Item 3'));
      expect(manager.nextItem()?.item.text, equals('Item 1'));
    });

    test('returns correct list and item in selection', () {
      final listA = MicroBreakList(
        name: 'Stretching',
        items: const [
          MicroBreakItem(text: 'Cat-Camel'),
        ],
      );
      
      final listB = MicroBreakList(
        name: 'Tai Chi',
        items: const [
          MicroBreakItem(text: 'Cloud Hands'),
        ],
      );
      
      final manager = RoundRobinManager(lists: [listA, listB]);
      
      final selection1 = manager.nextItem();
      expect(selection1?.list.name, equals('Stretching'));
      expect(selection1?.item.text, equals('Cat-Camel'));
      
      final selection2 = manager.nextItem();
      expect(selection2?.list.name, equals('Tai Chi'));
      expect(selection2?.item.text, equals('Cloud Hands'));
    });

    test('skips blank entries and moves to next list', () {
      final listA = MicroBreakList(
        name: 'A',
        items: const [
          MicroBreakItem(text: ''),
          MicroBreakItem(text: ''),
          MicroBreakItem(text: ''),
          MicroBreakItem(text: 'A1'),
        ],
      );
      
      final listB = MicroBreakList(
        name: 'B',
        items: const [
          MicroBreakItem(text: 'B1'),
          MicroBreakItem(text: 'B2'),
          MicroBreakItem(text: 'B3'),
        ],
      );
      
      final manager = RoundRobinManager(lists: [listA, listB]);
      
      // Expected: blank from A skips to B1, blank from A skips to B2, 
      // blank from A skips to B3, A1, B1, blank from A skips to B2...
      expect(manager.nextItem()?.item.text, equals('B1'));
      expect(manager.nextItem()?.item.text, equals('B2'));
      expect(manager.nextItem()?.item.text, equals('B3'));
      expect(manager.nextItem()?.item.text, equals('A1'));
      expect(manager.nextItem()?.item.text, equals('B1'));
      expect(manager.nextItem()?.item.text, equals('B2'));
    });

    test('handles mixed blank and non-blank items', () {
      final listA = MicroBreakList(
        name: 'A',
        items: const [
          MicroBreakItem(text: 'A1'),
          MicroBreakItem(text: ''),
          MicroBreakItem(text: 'A2'),
          MicroBreakItem(text: ''),
        ],
      );
      
      final listB = MicroBreakList(
        name: 'B',
        items: const [
          MicroBreakItem(text: 'B1'),
          MicroBreakItem(text: 'B2'),
        ],
      );
      
      final manager = RoundRobinManager(lists: [listA, listB]);
      
      // Expected: A1, B1, blank skips to B2, A2, B1, blank skips to B2, A1...
      expect(manager.nextItem()?.item.text, equals('A1'));
      expect(manager.nextItem()?.item.text, equals('B1'));
      expect(manager.nextItem()?.item.text, equals('B2'));
      expect(manager.nextItem()?.item.text, equals('A2'));
      expect(manager.nextItem()?.item.text, equals('B1'));
      expect(manager.nextItem()?.item.text, equals('B2'));
      expect(manager.nextItem()?.item.text, equals('A1'));
    });

    test('returns null when all items are blank', () {
      final listA = MicroBreakList(
        name: 'A',
        items: const [
          MicroBreakItem(text: ''),
          MicroBreakItem(text: '   '),
        ],
      );
      
      final listB = MicroBreakList(
        name: 'B',
        items: const [
          MicroBreakItem(text: ''),
        ],
      );
      
      final manager = RoundRobinManager(lists: [listA, listB]);
      
      expect(manager.nextItem(), isNull);
    });

    test('handles list with only blanks correctly', () {
      final listA = MicroBreakList(
        name: 'A',
        items: const [
          MicroBreakItem(text: ''),
          MicroBreakItem(text: ''),
        ],
      );
      
      final listB = MicroBreakList(
        name: 'B',
        items: const [
          MicroBreakItem(text: 'B1'),
          MicroBreakItem(text: 'B2'),
        ],
      );
      
      final listC = MicroBreakList(
        name: 'C',
        items: const [
          MicroBreakItem(text: 'C1'),
        ],
      );
      
      final manager = RoundRobinManager(lists: [listA, listB, listC]);
      
      // A always skips, so we alternate between B and C
      expect(manager.nextItem()?.item.text, equals('B1'));
      expect(manager.nextItem()?.item.text, equals('C1'));
      expect(manager.nextItem()?.item.text, equals('B2'));
      expect(manager.nextItem()?.item.text, equals('C1'));
      expect(manager.nextItem()?.item.text, equals('B1'));
    });
  });
}