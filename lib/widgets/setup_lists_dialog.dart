// ABOUTME: Modal dialog for managing micro-break lists with CRUD operations
// ABOUTME: Features sidebar list management and main text editor for list items

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/micro_break_list.dart';
import '../models/micro_break_item.dart';
import '../providers/app_providers.dart';

class SetupListsDialog extends ConsumerStatefulWidget {
  const SetupListsDialog({super.key});

  @override
  ConsumerState<SetupListsDialog> createState() => _SetupListsDialogState();
}

class _SetupListsDialogState extends ConsumerState<SetupListsDialog> {
  String? selectedListName;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _newListController = TextEditingController();
  final TextEditingController _renameController = TextEditingController();
  bool _hasUnsavedChanges = false;
  String? _editingList;

  @override
  void dispose() {
    _textController.dispose();
    _newListController.dispose();
    _renameController.dispose();
    super.dispose();
  }

  void _selectList(String listName, List<MicroBreakList> lists) {
    if (_hasUnsavedChanges) {
      _showUnsavedChangesDialog(() => _doSelectList(listName, lists));
      return;
    }
    _doSelectList(listName, lists);
  }

  void _doSelectList(String listName, List<MicroBreakList> lists) {
    final list = lists.firstWhere((l) => l.name == listName);
    setState(() {
      selectedListName = listName;
      _editingList = listName;
      _textController.text = list.items.map((item) => item.text).join('\n');
      _hasUnsavedChanges = false;
    });
  }

  void _onTextChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveCurrentList() async {
    if (_editingList == null) return;

    final lines = _textController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final items = lines.map((line) => MicroBreakItem(text: line)).toList();
    final list = MicroBreakList(name: _editingList!, items: items);

    await saveList(ref, list);

    setState(() {
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved list "$_editingList"')),
      );
    }
  }

  void _cancelChanges() {
    if (!_hasUnsavedChanges) return;

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    ).then((discard) {
      if (discard == true) {
        final listsAsync = ref.read(microBreakListsProvider);
        listsAsync.whenData((lists) {
          if (selectedListName != null) {
            _doSelectList(selectedListName!, lists);
          } else {
            setState(() {
              _textController.clear();
              _hasUnsavedChanges = false;
              _editingList = null;
            });
          }
        });
      }
    });
  }

  void _showUnsavedChangesDialog(VoidCallback onProceed) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              setState(() {
                _hasUnsavedChanges = false;
              });
              onProceed();
            },
            child: const Text('Discard Changes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              _saveCurrentList().then((_) => onProceed());
            },
            child: const Text('Save & Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewList() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New List'),
        content: TextField(
          controller: _newListController,
          decoration: const InputDecoration(
            labelText: 'List Name',
            hintText: 'Enter a name for the new list',
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_newListController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    _newListController.clear();

    if (name != null && name.isNotEmpty) {
      final listsAsync = ref.read(microBreakListsProvider);
      await listsAsync.when(
        data: (lists) async {
          // Check for duplicate names
          if (lists.any((list) => list.name == name)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('A list named "$name" already exists')),
              );
            }
            return;
          }

          // Create empty list
          final newList = MicroBreakList(name: name, items: const []);
          await saveList(ref, newList);

          // Select the new list
          setState(() {
            selectedListName = name;
            _editingList = name;
            _textController.clear();
            _hasUnsavedChanges = false;
          });
        },
        loading: () {},
        error: (_, __) {},
      );
    }
  }

  Future<void> _renameList(String oldName) async {
    _renameController.text = oldName;
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename List'),
        content: TextField(
          controller: _renameController,
          decoration: const InputDecoration(
            labelText: 'New Name',
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_renameController.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      final listsAsync = ref.read(microBreakListsProvider);
      await listsAsync.when(
        data: (lists) async {
          // Check for duplicate names
          if (lists.any((list) => list.name == newName)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('A list named "$newName" already exists')),
              );
            }
            return;
          }

          await renameList(ref, oldName, newName);

          setState(() {
            if (selectedListName == oldName) {
              selectedListName = newName;
              _editingList = newName;
            }
          });
        },
        loading: () {},
        error: (_, __) {},
      );
    }
  }

  Future<void> _deleteList(String listName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "$listName"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteList(ref, listName);

      setState(() {
        if (selectedListName == listName) {
          selectedListName = null;
          _editingList = null;
          _textController.clear();
          _hasUnsavedChanges = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(microBreakListsProvider);

    return Dialog(
      child: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Setup Micro-Breaks',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Row(
                children: [
                  // Sidebar
                  SizedBox(
                    width: 250,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Add list button
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _addNewList,
                                icon: const Icon(Icons.add),
                                label: const Text('Add List'),
                              ),
                            ),
                          ),
                          // Lists
                          Expanded(
                            child: listsAsync.when(
                              data: (lists) {
                                if (lists.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No lists yet.\nClick "Add List" to create one.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  );
                                }

                                final sortedLists = [...lists]..sort((a, b) => a.name.compareTo(b.name));

                                return ListView.builder(
                                  itemCount: sortedLists.length,
                                  itemBuilder: (context, index) {
                                    final list = sortedLists[index];
                                    final isSelected = selectedListName == list.name;

                                    return ListTile(
                                      title: Text(list.name),
                                      subtitle: Text('${list.items.length} items'),
                                      selected: isSelected,
                                      onTap: () => _selectList(list.name, lists),
                                      trailing: PopupMenuButton<String>(
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'rename',
                                            child: Text('Rename'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                        onSelected: (action) {
                                          switch (action) {
                                            case 'rename':
                                              _renameList(list.name);
                                              break;
                                            case 'delete':
                                              _deleteList(list.name);
                                              break;
                                          }
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (error, _) => Center(
                                child: Text('Error: $error'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Main content
                  Expanded(
                    child: selectedListName == null
                        ? const Center(
                            child: Text(
                              'Select a list to edit its items',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : Column(
                            children: [
                              // Toolbar
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Editing: $selectedListName',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    if (_hasUnsavedChanges)
                                      const Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: Colors.orange,
                                      ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: _hasUnsavedChanges ? _cancelChanges : null,
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _hasUnsavedChanges ? _saveCurrentList : null,
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              ),
                              // Text editor
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Enter one micro-break item per line:',
                                        style: TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _textController,
                                          onChanged: (_) => _onTextChanged(),
                                          maxLines: null,
                                          expands: true,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            hintText: 'Cat-Camel stretch\nStanding Back Extension\nSeated Pelvic Tilt',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}