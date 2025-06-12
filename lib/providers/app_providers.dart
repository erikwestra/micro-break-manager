// ABOUTME: Riverpod providers for managing app state and dependencies
// ABOUTME: Connects FileStorageService, RoundRobinManager, and app state

import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
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
final roundRobinManagerProvider = FutureProvider<RoundRobinManager?>((ref) async {
  final listsAsync = ref.watch(microBreakListsProvider);
  
  return listsAsync.when(
    data: (lists) {
      if (lists.isEmpty) {
        return null;
      }
      
      final manager = RoundRobinManager(lists: lists);
      
      // Restore saved indices if available
      final savedIndices = ref.read(savedIndicesProvider);
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
final savedIndicesProvider = StateNotifierProvider<SavedIndicesNotifier, Map<String, int>>((ref) {
  return SavedIndicesNotifier(ref);
});

class SavedIndicesNotifier extends StateNotifier<Map<String, int>> {
  final Ref ref;
  
  SavedIndicesNotifier(this.ref) : super({}) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final appDir = await storage.getAppDirectory();
      final stateFile = File(path.join(appDir.path, 'state.json'));
      
      if (await stateFile.exists()) {
        final jsonString = await stateFile.readAsString();
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        final Map<String, int> loadedState = {};
        
        for (final entry in jsonData.entries) {
          if (entry.value is int) {
            loadedState[entry.key] = entry.value;
          }
        }
        
        state = loadedState;
      }
    } catch (e) {
      print('Error loading state: $e');
    }
  }

  Future<void> updateState(Map<String, int> newState) async {
    state = newState;
    await _saveState();
  }

  Future<void> _saveState() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final appDir = await storage.getAppDirectory();
      final stateFile = File(path.join(appDir.path, 'state.json'));
      
      final jsonString = json.encode(state);
      await stateFile.writeAsString(jsonString);
    } catch (e) {
      print('Error saving state: $e');
    }
  }
}

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreakState &&
          runtimeType == other.runtimeType &&
          isActive == other.isActive &&
          startTime == other.startTime &&
          currentList == other.currentList &&
          currentItem == other.currentItem;

  @override
  int get hashCode =>
      isActive.hashCode ^
      startTime.hashCode ^
      currentList.hashCode ^
      currentItem.hashCode;

  @override
  String toString() => 'BreakState(isActive: $isActive, startTime: $startTime, currentList: ${currentList?.name}, currentItem: ${currentItem?.text})';
}

final breakStateProvider = StateNotifierProvider<BreakStateNotifier, BreakState>((ref) {
  return BreakStateNotifier(ref);
});

class BreakStateNotifier extends StateNotifier<BreakState> {
  final Ref ref;
  
  BreakStateNotifier(this.ref) : super(const BreakState());
  
  void startBreak() {
    final managerAsync = ref.read(roundRobinManagerProvider);
    managerAsync.when(
      data: (manager) {
        if (manager == null) return;
        
        final selection = manager.nextItem();
        if (selection == null) return;
        
        state = BreakState(
          isActive: true,
          startTime: DateTime.now(),
          currentList: selection.list,
          currentItem: selection.item,
        );
      },
      loading: () {},
      error: (_, __) {},
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
    final managerAsync = ref.read(roundRobinManagerProvider);
    managerAsync.whenData((manager) async {
      if (manager != null) {
        await ref.read(savedIndicesProvider.notifier).updateState(manager.getIndicesState());
      }
    });
    
    // Reset state
    state = const BreakState();
  }
  
  void cancelBreak() {
    if (!state.isActive) return;
    
    // Roll back the selection
    final managerAsync = ref.read(roundRobinManagerProvider);
    managerAsync.whenData((manager) {
      manager?.cancelSelection();
    });
    
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
  // Invalidate providers to refresh with new data
  ref.invalidate(microBreakListsProvider);
  ref.invalidate(roundRobinManagerProvider);
}

// Method to delete a list
Future<void> deleteList(WidgetRef ref, String listName) async {
  final storage = ref.read(storageServiceProvider);
  await storage.deleteList(listName);
  ref.invalidate(microBreakListsProvider);
  ref.invalidate(roundRobinManagerProvider);
}

// Method to rename a list
Future<void> renameList(WidgetRef ref, String oldName, String newName) async {
  final storage = ref.read(storageServiceProvider);
  await storage.renameList(oldName, newName);
  ref.invalidate(microBreakListsProvider);
  ref.invalidate(roundRobinManagerProvider);
}