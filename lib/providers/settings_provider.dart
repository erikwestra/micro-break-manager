// ABOUTME: Simplified provider for managing app settings - now uses Documents folder only
// ABOUTME: No longer supports custom data directory selection

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

class AppSettings {
  const AppSettings();
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  Future<String> getDataDirectory() async {
    // Always use Documents directory for better cross-computer access
    final home = Platform.environment['HOME'] ?? '';
    if (home.isNotEmpty) {
      return path.join(home, 'Documents');
    }
    
    // Fallback if HOME is not set (shouldn't happen on macOS)
    throw Exception('Could not determine home directory');
  }

  Future<String> getMicroBreakDataDirectory() async {
    final baseDir = await getDataDirectory();
    final dataDir = Directory(path.join(baseDir, 'Micro-Break Data'));
    
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    
    return dataDir.path;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});