// ABOUTME: Service for managing file-based storage of micro-break lists and logs
// ABOUTME: Handles reading/writing TSV files and automatic log purging after 30 days

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/micro_break_list.dart';
import '../models/log_entry.dart';

class FileStorageService {
  static const String appDirName = 'MicroBreakManager';
  static const String listsDirName = 'lists';
  static const String logsDirName = 'logs';
  
  Future<Directory> getAppDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final appDir = Directory(path.join(directory.path, appDirName));
    
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    
    return appDir;
  }
  
  Future<Directory> getListsDirectory() async {
    final appDir = await getAppDirectory();
    final listsDir = Directory(path.join(appDir.path, listsDirName));
    
    if (!await listsDir.exists()) {
      await listsDir.create(recursive: true);
    }
    
    return listsDir;
  }
  
  Future<Directory> getLogsDirectory() async {
    final appDir = await getAppDirectory();
    final logsDir = Directory(path.join(appDir.path, logsDirName));
    
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    
    return logsDir;
  }
  
  Future<List<MicroBreakList>> readLists() async {
    final listsDir = await getListsDirectory();
    final lists = <MicroBreakList>[];
    
    await for (final entity in listsDir.list()) {
      if (entity is File && entity.path.endsWith('.txt')) {
        try {
          final fileName = path.basenameWithoutExtension(entity.path);
          final lines = await entity.readAsLines();
          
          if (lines.isNotEmpty) {
            lists.add(MicroBreakList.fromTsvLines(fileName, lines));
          }
        } catch (e) {
          // Skip malformed files
          print('Error reading list file ${entity.path}: $e');
        }
      }
    }
    
    // Sort alphabetically by name
    lists.sort((a, b) => a.name.compareTo(b.name));
    
    return lists;
  }
  
  Future<void> saveList(MicroBreakList list) async {
    final listsDir = await getListsDirectory();
    final file = File(path.join(listsDir.path, '${list.name}.txt'));
    
    final lines = list.toTsvLines();
    await file.writeAsString(lines.join('\n'));
  }
  
  Future<void> deleteList(String listName) async {
    final listsDir = await getListsDirectory();
    final file = File(path.join(listsDir.path, '$listName.txt'));
    
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  Future<void> renameList(String oldName, String newName) async {
    final listsDir = await getListsDirectory();
    final oldFile = File(path.join(listsDir.path, '$oldName.txt'));
    final newFile = File(path.join(listsDir.path, '$newName.txt'));
    
    if (await oldFile.exists()) {
      await oldFile.rename(newFile.path);
    }
  }
  
  String _getLogFileName(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}.txt';
  }
  
  Future<List<LogEntry>> readDailyLog(DateTime date) async {
    final logsDir = await getLogsDirectory();
    final fileName = _getLogFileName(date);
    final file = File(path.join(logsDir.path, fileName));
    
    if (!await file.exists()) {
      return [];
    }
    
    final entries = <LogEntry>[];
    final lines = await file.readAsLines();
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      try {
        entries.add(LogEntry.fromTsv(line));
      } catch (e) {
        // Skip malformed log entries
        print('Error parsing log entry: $e');
      }
    }
    
    return entries;
  }
  
  Future<void> appendLogEntry(LogEntry entry) async {
    final logsDir = await getLogsDirectory();
    final fileName = _getLogFileName(entry.start);
    final file = File(path.join(logsDir.path, fileName));
    
    final tsv = entry.toTsv();
    
    if (await file.exists()) {
      await file.writeAsString('\n$tsv', mode: FileMode.append);
    } else {
      await file.writeAsString(tsv);
    }
  }
  
  Future<List<DateTime>> getAvailableLogDates() async {
    final logsDir = await getLogsDirectory();
    final dates = <DateTime>[];
    
    await for (final entity in logsDir.list()) {
      if (entity is File && entity.path.endsWith('.txt')) {
        final fileName = path.basenameWithoutExtension(entity.path);
        
        try {
          // Parse YYYY-MM-DD format
          final parts = fileName.split('-');
          if (parts.length == 3) {
            final date = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            dates.add(date);
          }
        } catch (e) {
          // Skip malformed filenames
          print('Error parsing log filename $fileName: $e');
        }
      }
    }
    
    // Sort in descending order (most recent first)
    dates.sort((a, b) => b.compareTo(a));
    
    return dates;
  }
  
  Future<void> purgeOldLogs({int keepDays = 30}) async {
    final logsDir = await getLogsDirectory();
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
    
    await for (final entity in logsDir.list()) {
      if (entity is File && entity.path.endsWith('.txt')) {
        final fileName = path.basenameWithoutExtension(entity.path);
        
        try {
          // Parse YYYY-MM-DD format
          final parts = fileName.split('-');
          if (parts.length == 3) {
            final date = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            
            if (date.isBefore(cutoffDate)) {
              await entity.delete();
              print('Deleted old log file: $fileName');
            }
          }
        } catch (e) {
          // Skip malformed filenames
          print('Error processing log file $fileName: $e');
        }
      }
    }
  }
}