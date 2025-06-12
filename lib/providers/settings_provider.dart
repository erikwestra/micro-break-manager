// ABOUTME: Provider for managing app settings including data directory location
// ABOUTME: Persists user preferences using shared_preferences

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AppSettings {
  final String? customDataDirectory;

  const AppSettings({
    this.customDataDirectory,
  });

  AppSettings copyWith({
    String? customDataDirectory,
  }) {
    return AppSettings(
      customDataDirectory: customDataDirectory ?? this.customDataDirectory,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _dataDirectoryKey = 'custom_data_directory';
  
  SettingsNotifier() : super(const AppSettings());

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final dataDir = prefs.getString(_dataDirectoryKey);
    
    if (dataDir != null && await Directory(dataDir).exists()) {
      state = state.copyWith(customDataDirectory: dataDir);
    }
  }

  Future<void> setDataDirectory(String? directory) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (directory == null) {
      await prefs.remove(_dataDirectoryKey);
    } else {
      await prefs.setString(_dataDirectoryKey, directory);
    }
    
    state = state.copyWith(customDataDirectory: directory);
  }

  Future<String> getDataDirectory() async {
    // Ensure settings are loaded first
    await _ensureSettingsLoaded();
    
    if (state.customDataDirectory != null) {
      return state.customDataDirectory!;
    }
    
    // Default to Application Support directory
    final appSupport = await getApplicationSupportDirectory();
    return appSupport.path;
  }

  bool _settingsLoaded = false;

  Future<void> _ensureSettingsLoaded() async {
    if (!_settingsLoaded) {
      await _loadSettings();
      _settingsLoaded = true;
    }
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