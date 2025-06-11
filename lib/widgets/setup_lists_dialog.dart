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
  final FocusNode _textFieldFocusNode = FocusNode();
  String? _editingList;

  @override
  void dispose() {
    _textController.dispose();
    _newListController.dispose();
    _renameController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void _selectList(String listName, List<MicroBreakList> lists) async {
    // Save current list before switching
    await _saveCurrentListIfNeeded();
    _doSelectList(listName, lists);
  }

  void _deselectList() async {
    // Save current list before deselecting
    await _saveCurrentListIfNeeded();
    setState(() {
      selectedListName = null;
      _editingList = null;
      _textController.clear();
    });
  }

  void _doSelectList(String listName, List<MicroBreakList> lists) {
    final list = lists.firstWhere((l) => l.name == listName);
    setState(() {
      selectedListName = listName;
      _editingList = listName;
      _textController.text = list.items.map((item) => item.text).join('\n');
    });
    
    // Auto-focus the text field and move cursor to start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFieldFocusNode.requestFocus();
      _textController.selection = TextSelection.fromPosition(
        const TextPosition(offset: 0),
      );
    });
  }

  void _onTextChanged() {
    // Just track that content has changed, don't save yet
  }

  Future<void> _saveCurrentListIfNeeded() async {
    if (_editingList == null) return;

    final lines = _textController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final items = lines.map((line) => MicroBreakItem(text: line)).toList();
    final list = MicroBreakList(name: _editingList!, items: items);

    await saveList(ref, list);
  }


  Future<void> _addNewList() async {
    // Save current list before creating new one
    await _saveCurrentListIfNeeded();
    
    await _doAddNewList();
  }

  Future<void> _doAddNewList() async {
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
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Duplicate Name'),
                  content: Text('A list named "$name" already exists. Please choose a different name.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return;
          }

          // Create empty list and save it immediately
          final newList = MicroBreakList(name: name, items: const []);
          await saveList(ref, newList);
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
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Duplicate Name'),
                  content: Text('A list named "$newName" already exists. Please choose a different name.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
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
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(microBreakListsProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _saveCurrentListIfNeeded();
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Dialog(
        child: SizedBox(
        width: 1000,
        height: 700,
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
                    onPressed: () async {
                      await _saveCurrentListIfNeeded();
                      if (mounted) Navigator.of(context).pop();
                    },
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
                    width: 300,
                    child: GestureDetector(
                      onTap: _deselectList,
                      behavior: HitTestBehavior.translucent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                          ),
                          border: Border(
                            right: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Column(
                        children: [
                          // Add list button
                          GestureDetector(
                            onTap: () {}, // Prevent parent GestureDetector from triggering
                            child: Padding(
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

                                    return GestureDetector(
                                      onTap: () {}, // Prevent parent GestureDetector from triggering
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                                          borderRadius: BorderRadius.circular(6),
                                          border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.3)) : null,
                                        ),
                                        child: ListTile(
                                        title: Text(
                                          list.name,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: isSelected ? Colors.blue.shade700 : null,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${list.items.length} items',
                                          style: TextStyle(
                                            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                                          ),
                                        ),
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
                                        ),
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
                        : Padding(
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
                                    focusNode: _textFieldFocusNode,
                                    onChanged: (_) => _onTextChanged(),
                                    maxLines: null,
                                    expands: true,
                                    textAlignVertical: TextAlignVertical.top,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
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
      ),
    );
  }
}