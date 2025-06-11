// ABOUTME: Riverpod providers for managing app state and dependencies
// ABOUTME: Connects FileStorageService, RoundRobinManager, and app state

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_storage_service.dart';
import '../services/round_robin_manager.dart';
import '../models/micro_break_list.dart';
import '../models/micro_break_item.dart';
import '../models/log_entry.dart';

// Storage service provider
final storageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

// Lists provider that loads from storage
final microBreakListsProvider = FutureProvider<List<MicroBreakList>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return await storage.readLists();
});

// Round-robin manager provider
final roundRobinManagerProvider = Provider<RoundRobinManager?>((ref) {
  final listsAsync = ref.watch(microBreakListsProvider);
  
  return listsAsync.when(
    data: (lists) {
      if (lists.isEmpty) return null;
      
      final manager = RoundRobinManager(lists: lists);
      
      // Restore saved indices if available
      final savedIndices = ref.watch(savedIndicesProvider);
      if (savedIndices.isNotEmpty) {
        manager.restoreIndicesState(savedIndices);
      }
      
      return manager;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Saved indices state (persisted locally)
final savedIndicesProvider = StateProvider<Map<String, int>>((ref) {
  // In a real implementation, this would load from persistent storage
  // For now, we'll start with an empty map
  return {};
});

// Current break state
class BreakState {
  final bool isActive;
  final DateTime? startTime;
  final MicroBreakList? currentList;
  final MicroBreakItem? currentItem;

  const BreakState({
    this.isActive = false,
    this.startTime,
    this.currentList,
    this.currentItem,
  });

  BreakState copyWith({
    bool? isActive,
    DateTime? startTime,
    MicroBreakList? currentList,
    MicroBreakItem? currentItem,
  }) {
    return BreakState(
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      currentList: currentList ?? this.currentList,
      currentItem: currentItem ?? this.currentItem,
    );
  }
}

final breakStateProvider = StateNotifierProvider<BreakStateNotifier, BreakState>((ref) {
  return BreakStateNotifier(ref);
});

class BreakStateNotifier extends StateNotifier<BreakState> {
  final Ref ref;
  
  BreakStateNotifier(this.ref) : super(const BreakState());
  
  void startBreak() {
    final manager = ref.read(roundRobinManagerProvider);
    if (manager == null) return;
    
    final selection = manager.nextItem();
    if (selection == null) return;
    
    state = BreakState(
      isActive: true,
      startTime: DateTime.now(),
      currentList: selection.list,
      currentItem: selection.item,
    );
  }
  
  Future<void> finishBreak() async {
    if (!state.isActive || state.startTime == null || 
        state.currentList == null || state.currentItem == null) {
      return;
    }
    
    // Create log entry
    final entry = LogEntry(
      start: state.startTime!,
      end: DateTime.now(),
      listName: state.currentList!.name,
      itemText: state.currentItem!.text,
    );
    
    // Save to log
    final storage = ref.read(storageServiceProvider);
    await storage.appendLogEntry(entry);
    
    // Save indices state
    final manager = ref.read(roundRobinManagerProvider);
    if (manager != null) {
      ref.read(savedIndicesProvider.notifier).state = manager.getIndicesState();
    }
    
    // Reset state
    state = const BreakState();
  }
  
  void cancelBreak() {
    if (!state.isActive) return;
    
    // Roll back the selection
    final manager = ref.read(roundRobinManagerProvider);
    manager?.cancelSelection();
    
    // Reset state
    state = const BreakState();
  }
}

// Available log dates provider
final availableLogDatesProvider = FutureProvider<List<DateTime>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return await storage.getAvailableLogDates();
});

// Selected log date provider
final selectedLogDateProvider = StateProvider<DateTime?>((ref) => null);

// Log entries for selected date
final selectedDateLogEntriesProvider = FutureProvider<List<LogEntry>>((ref) async {
  final selectedDate = ref.watch(selectedLogDateProvider);
  if (selectedDate == null) return [];
  
  final storage = ref.watch(storageServiceProvider);
  return await storage.readDailyLog(selectedDate);
});

// Method to refresh lists after changes
void refreshLists(WidgetRef ref) {
  ref.invalidate(microBreakListsProvider);
}

// Method to save a list
Future<void> saveList(WidgetRef ref, MicroBreakList list) async {
  final storage = ref.read(storageServiceProvider);
  await storage.saveList(list);
  refreshLists(ref);
}

// Method to delete a list
Future<void> deleteList(WidgetRef ref, String listName) async {
  final storage = ref.read(storageServiceProvider);
  await storage.deleteList(listName);
  refreshLists(ref);
}

// Method to rename a list
Future<void> renameList(WidgetRef ref, String oldName, String newName) async {
  final storage = ref.read(storageServiceProvider);
  await storage.renameList(oldName, newName);
  refreshLists(ref);
}