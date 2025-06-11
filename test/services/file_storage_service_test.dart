import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_break_manager/services/file_storage_service.dart';
import 'package:micro_break_manager/models/micro_break_list.dart';
import 'package:micro_break_manager/models/micro_break_item.dart';
import 'package:micro_break_manager/models/log_entry.dart';
import 'package:path/path.dart' as path;

void main() {
  late FileStorageService service;
  late Directory tempDir;

  setUp(() async {
    service = FileStorageService();
    // Create a temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('micro_break_test_');
  });

  tearDown(() async {
    // Clean up the temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileStorageService', () {
    // Helper to create test directory structure
    Future<void> createTestStructure() async {
      final listsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'lists'));
      final logsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'logs'));
      
      await listsDir.create(recursive: true);
      await logsDir.create(recursive: true);
    }

    group('readLists', () {
      test('returns empty list when no files exist', () async {
        await createTestStructure();
        
        // Override the service to use our temp directory
        service = TestableFileStorageService(tempDir.path);
        
        final lists = await service.readLists();
        expect(lists, isEmpty);
      });

      test('reads single list file correctly', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        // Create a test list file
        final listsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'lists'));
        final file = File(path.join(listsDir.path, 'stretching.txt'));
        await file.writeAsString('Cat-Camel stretch\nStanding Back Extension\nSeated Pelvic Tilt');
        
        final lists = await service.readLists();
        
        expect(lists.length, equals(1));
        expect(lists[0].name, equals('stretching'));
        expect(lists[0].items.length, equals(3));
        expect(lists[0].items[0].text, equals('Cat-Camel stretch'));
        expect(lists[0].items[1].text, equals('Standing Back Extension'));
        expect(lists[0].items[2].text, equals('Seated Pelvic Tilt'));
      });

      test('reads multiple list files and sorts alphabetically', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final listsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'lists'));
        
        // Create test files in non-alphabetical order
        await File(path.join(listsDir.path, 'tai_chi.txt')).writeAsString('Cloud Hands\nBrush Knee');
        await File(path.join(listsDir.path, 'chinese.txt')).writeAsString('Character 一\nCharacter 二');
        await File(path.join(listsDir.path, 'stretching.txt')).writeAsString('Cat-Camel stretch');
        
        final lists = await service.readLists();
        
        expect(lists.length, equals(3));
        expect(lists[0].name, equals('chinese'));
        expect(lists[1].name, equals('stretching'));
        expect(lists[2].name, equals('tai_chi'));
      });

      test('skips non-txt files', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final listsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'lists'));
        
        await File(path.join(listsDir.path, 'valid.txt')).writeAsString('Item 1');
        await File(path.join(listsDir.path, 'invalid.pdf')).writeAsString('Should be ignored');
        await File(path.join(listsDir.path, '.hidden.txt')).writeAsString('Hidden file');
        
        final lists = await service.readLists();
        
        expect(lists.length, equals(2)); // .hidden.txt is still a valid txt file
        expect(lists.any((l) => l.name == 'valid'), isTrue);
        expect(lists.any((l) => l.name == '.hidden'), isTrue);
        expect(lists.any((l) => l.name == 'invalid'), isFalse);
      });
    });

    group('saveList', () {
      test('creates new list file', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final list = MicroBreakList(
          name: 'test_list',
          items: const [
            MicroBreakItem(text: 'Item 1'),
            MicroBreakItem(text: 'Item 2'),
          ],
        );
        
        await service.saveList(list);
        
        final listsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'lists'));
        final file = File(path.join(listsDir.path, 'test_list.txt'));
        
        expect(await file.exists(), isTrue);
        final content = await file.readAsString();
        expect(content, equals('Item 1\nItem 2'));
      });

      test('overwrites existing list file', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final listsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'lists'));
        final file = File(path.join(listsDir.path, 'existing.txt'));
        await file.writeAsString('Old content');
        
        final list = MicroBreakList(
          name: 'existing',
          items: const [
            MicroBreakItem(text: 'New Item 1'),
            MicroBreakItem(text: 'New Item 2'),
          ],
        );
        
        await service.saveList(list);
        
        final content = await file.readAsString();
        expect(content, equals('New Item 1\nNew Item 2'));
      });
    });

    group('deleteList', () {
      test('deletes existing list file', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final listsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'lists'));
        final file = File(path.join(listsDir.path, 'to_delete.txt'));
        await file.writeAsString('Some content');
        
        expect(await file.exists(), isTrue);
        
        await service.deleteList('to_delete');
        
        expect(await file.exists(), isFalse);
      });

      test('does not throw if file does not exist', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        // Should not throw
        await service.deleteList('non_existent');
      });
    });

    group('renameList', () {
      test('renames existing list file', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final listsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'lists'));
        final oldFile = File(path.join(listsDir.path, 'old_name.txt'));
        await oldFile.writeAsString('Content to keep');
        
        await service.renameList('old_name', 'new_name');
        
        final newFile = File(path.join(listsDir.path, 'new_name.txt'));
        
        expect(await oldFile.exists(), isFalse);
        expect(await newFile.exists(), isTrue);
        expect(await newFile.readAsString(), equals('Content to keep'));
      });
    });

    group('Log operations', () {
      test('readDailyLog returns empty list for non-existent file', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final entries = await service.readDailyLog(DateTime(2025, 6, 12));
        expect(entries, isEmpty);
      });

      test('readDailyLog reads existing log entries', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final logsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'logs'));
        final file = File(path.join(logsDir.path, '2025-06-12.txt'));
        
        await file.writeAsString(
          '2025-06-12\t10:35:12\t10:40:05\tstretching\tCat-Camel stretch\n'
          '2025-06-12\t14:03:20\t14:05:00\ttai_chi\tCloud Hands'
        );
        
        final entries = await service.readDailyLog(DateTime(2025, 6, 12));
        
        expect(entries.length, equals(2));
        expect(entries[0].listName, equals('stretching'));
        expect(entries[0].itemText, equals('Cat-Camel stretch'));
        expect(entries[1].listName, equals('tai_chi'));
        expect(entries[1].itemText, equals('Cloud Hands'));
      });

      test('appendLogEntry creates new file if needed', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final entry = LogEntry(
          start: DateTime(2025, 6, 12, 10, 35, 12),
          end: DateTime(2025, 6, 12, 10, 40, 5),
          listName: 'stretching',
          itemText: 'Cat-Camel stretch',
        );
        
        await service.appendLogEntry(entry);
        
        final logsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'logs'));
        final file = File(path.join(logsDir.path, '2025-06-12.txt'));
        
        expect(await file.exists(), isTrue);
        expect(await file.readAsString(), equals('2025-06-12\t10:35:12\t10:40:05\tstretching\tCat-Camel stretch'));
      });

      test('appendLogEntry appends to existing file', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final logsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'logs'));
        final file = File(path.join(logsDir.path, '2025-06-12.txt'));
        await file.writeAsString('2025-06-12\t10:35:12\t10:40:05\tstretching\tCat-Camel stretch');
        
        final entry = LogEntry(
          start: DateTime(2025, 6, 12, 14, 3, 20),
          end: DateTime(2025, 6, 12, 14, 5, 0),
          listName: 'tai_chi',
          itemText: 'Cloud Hands',
        );
        
        await service.appendLogEntry(entry);
        
        final content = await file.readAsString();
        expect(content, equals(
          '2025-06-12\t10:35:12\t10:40:05\tstretching\tCat-Camel stretch\n'
          '2025-06-12\t14:03:20\t14:05:00\ttai_chi\tCloud Hands'
        ));
      });

      test('getAvailableLogDates returns sorted dates', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final logsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'logs'));
        
        // Create log files in random order
        await File(path.join(logsDir.path, '2025-06-10.txt')).writeAsString('content');
        await File(path.join(logsDir.path, '2025-06-12.txt')).writeAsString('content');
        await File(path.join(logsDir.path, '2025-06-11.txt')).writeAsString('content');
        
        final dates = await service.getAvailableLogDates();
        
        expect(dates.length, equals(3));
        expect(dates[0], equals(DateTime(2025, 6, 12))); // Most recent first
        expect(dates[1], equals(DateTime(2025, 6, 11)));
        expect(dates[2], equals(DateTime(2025, 6, 10)));
      });

      test('purgeOldLogs deletes logs older than keepDays', () async {
        await createTestStructure();
        service = TestableFileStorageService(tempDir.path);
        
        final logsDir = Directory(path.join(tempDir.path, 'MicroBreakManager', 'logs'));
        
        // Create log files with different ages
        final now = DateTime.now();
        final recent = now.subtract(const Duration(days: 10));
        final old = now.subtract(const Duration(days: 35));
        final veryOld = now.subtract(const Duration(days: 60));
        
        final recentFile = File(path.join(logsDir.path, 
          '${recent.year.toString().padLeft(4, '0')}-'
          '${recent.month.toString().padLeft(2, '0')}-'
          '${recent.day.toString().padLeft(2, '0')}.txt'
        ));
        final oldFile = File(path.join(logsDir.path,
          '${old.year.toString().padLeft(4, '0')}-'
          '${old.month.toString().padLeft(2, '0')}-'
          '${old.day.toString().padLeft(2, '0')}.txt'
        ));
        final veryOldFile = File(path.join(logsDir.path,
          '${veryOld.year.toString().padLeft(4, '0')}-'
          '${veryOld.month.toString().padLeft(2, '0')}-'
          '${veryOld.day.toString().padLeft(2, '0')}.txt'
        ));
        
        await recentFile.writeAsString('recent');
        await oldFile.writeAsString('old');
        await veryOldFile.writeAsString('very old');
        
        await service.purgeOldLogs(keepDays: 30);
        
        expect(await recentFile.exists(), isTrue);
        expect(await oldFile.exists(), isFalse);
        expect(await veryOldFile.exists(), isFalse);
      });
    });
  });
}

// Test-specific subclass that allows us to override the app directory
class TestableFileStorageService extends FileStorageService {
  final String testBasePath;
  
  TestableFileStorageService(this.testBasePath);
  
  @override
  Future<Directory> getAppDirectory() async {
    final appDir = Directory(path.join(testBasePath, 'MicroBreakManager'));
    
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    
    return appDir;
  }
}