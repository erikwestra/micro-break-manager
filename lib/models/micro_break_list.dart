// ABOUTME: Model representing a list of micro-break items with TSV file support
// ABOUTME: Manages the collection of items and tracks current position for round-robin cycling

import 'micro_break_item.dart';

class MicroBreakList {
  final String name;
  final List<MicroBreakItem> items;
  int currentIndex;

  MicroBreakList({
    required this.name,
    required this.items,
    this.currentIndex = 0,
  });

  factory MicroBreakList.fromTsvLines(String name, List<String> lines) {
    final items = lines
        .map((line) => MicroBreakItem.fromTsv(line))
        .toList();
    
    return MicroBreakList(
      name: name,
      items: items,
    );
  }

  List<String> toTsvLines() {
    return items.map((item) => item.toTsv()).toList();
  }

  MicroBreakItem? get currentItem {
    if (items.isEmpty) return null;
    if (currentIndex >= items.length) {
      currentIndex = 0;
    }
    return items[currentIndex];
  }

  void moveToNext() {
    if (items.isNotEmpty) {
      currentIndex = (currentIndex + 1) % items.length;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MicroBreakList &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          items == other.items &&
          currentIndex == other.currentIndex;

  @override
  int get hashCode => name.hashCode ^ items.hashCode ^ currentIndex.hashCode;

  @override
  String toString() => 'MicroBreakList(name: $name, items: ${items.length}, currentIndex: $currentIndex)';
}