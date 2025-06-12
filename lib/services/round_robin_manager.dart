// ABOUTME: Manages round-robin selection of micro-break items across multiple lists
// ABOUTME: Maintains state for list and item indices with rollback capability

import '../models/micro_break_list.dart';
import '../models/micro_break_item.dart';

class RoundRobinSelection {
  final MicroBreakList list;
  final MicroBreakItem item;

  const RoundRobinSelection({
    required this.list,
    required this.item,
  });
}

class RoundRobinManager {
  final List<MicroBreakList> lists;
  int _currentListIndex = 0;
  int? _previousListIndex;
  
  RoundRobinManager({required this.lists}) {
    if (lists.isEmpty) {
      throw ArgumentError('RoundRobinManager requires at least one list');
    }
  }
  
  RoundRobinSelection? nextItem() {
    if (lists.isEmpty) return null;
    
    // Check if all lists have only empty or blank items
    final hasAnyNonBlankItems = lists.any((list) => 
        list.items.any((item) => !item.isBlank));
    if (!hasAnyNonBlankItems) return null;
    
    // Save current state for potential rollback
    _previousListIndex = _currentListIndex;
    
    // Find a non-blank item starting from current position
    int attempts = 0;
    while (attempts < lists.length) {
      final currentList = lists[_currentListIndex];
      final currentItem = currentList.currentItem;
      
      if (currentItem != null) {
        if (!currentItem.isBlank) {
          // Found a valid non-blank item
          final selection = RoundRobinSelection(
            list: currentList,
            item: currentItem,
          );
          
          // Advance the item index in the current list
          currentList.moveToNext();
          
          // Move to the next list for next time
          _moveToNextList();
          
          return selection;
        } else {
          // Current item is blank, advance this list's index
          currentList.moveToNext();
          // Move to the next list (skip this turn)
          _moveToNextList();
          attempts++;
          continue;
        }
      }
      
      // This list is empty, try the next one
      _moveToNextList();
      attempts++;
    }
    
    // Should not reach here if hasAnyNonBlankItems was true
    return null;
  }
  
  void cancelSelection() {
    if (_previousListIndex != null) {
      // First, undo the list rotation
      _currentListIndex = _previousListIndex!;
      
      // Then, undo the item advancement in that list
      final previousList = lists[_currentListIndex];
      
      // Move the item index back by one
      if (previousList.items.isNotEmpty) {
        previousList.currentIndex = 
            (previousList.currentIndex - 1 + previousList.items.length) % 
            previousList.items.length;
      }
      
      _previousListIndex = null;
    }
  }
  
  void _moveToNextList() {
    _currentListIndex = (_currentListIndex + 1) % lists.length;
  }
  
  // Save indices state (for persistence)
  Map<String, int> getIndicesState() {
    final state = <String, int>{};
    state['listIndex'] = _currentListIndex;
    
    for (var i = 0; i < lists.length; i++) {
      state['list_${lists[i].name}_itemIndex'] = lists[i].currentIndex;
    }
    
    return state;
  }
  
  // Restore indices state (from persistence)
  void restoreIndicesState(Map<String, int> state) {
    _currentListIndex = state['listIndex'] ?? 0;
    
    for (final list in lists) {
      final savedIndex = state['list_${list.name}_itemIndex'];
      if (savedIndex != null) {
        list.currentIndex = savedIndex;
      }
    }
  }
}