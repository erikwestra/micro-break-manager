// ABOUTME: Settings dialog for configuring application preferences
// ABOUTME: Currently supports changing the data storage directory location

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../providers/settings_provider.dart';
import '../providers/app_providers.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  String? _selectedDirectory;

  @override
  void initState() {
    super.initState();
    _loadCurrentDirectory();
  }

  Future<void> _loadCurrentDirectory() async {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final dataDir = await settingsNotifier.getMicroBreakDataDirectory();
    
    setState(() {
      _selectedDirectory = path.dirname(dataDir);
    });
  }

  Future<void> _selectDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose Data Storage Location',
      );

      if (result != null) {
        setState(() {
          _selectedDirectory = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting directory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_selectedDirectory == null) return;
    
    final settingsNotifier = ref.read(settingsProvider.notifier);
    await settingsNotifier.setDataDirectory(_selectedDirectory);
    
    // Refresh providers to use new location
    ref.invalidate(storageServiceProvider);
    ref.invalidate(microBreakListsProvider);
    ref.invalidate(availableLogDatesProvider);
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final microBreakDataPath = _selectedDirectory != null 
        ? path.join(_selectedDirectory!, 'Micro-Break Data')
        : '';
    
    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Storage Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose where to store your micro-break lists and logs.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.folder,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Storage Location',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    microBreakDataPath,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _selectDirectory,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose Folder'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveSettings,
          child: const Text('Save'),
        ),
      ],
    );
  }
}