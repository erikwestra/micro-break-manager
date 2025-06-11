// ABOUTME: Modal dialog for viewing micro-break session logs by date
// ABOUTME: Features date sidebar and read-only log content viewer

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/log_entry.dart';

class ViewLogsDialog extends ConsumerWidget {
  const ViewLogsDialog({super.key});

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour < 12 ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Widget _buildLogEntry(LogEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.listName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_formatTime(entry.start)} - ${_formatTime(entry.end)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(entry.duration),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.itemText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableDatesAsync = ref.watch(availableLogDatesProvider);
    final selectedDate = ref.watch(selectedLogDateProvider);
    final selectedEntriesAsync = ref.watch(selectedDateLogEntriesProvider);

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
                    'View Logs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // Clear selection when closing
                      ref.read(selectedLogDateProvider.notifier).state = null;
                      Navigator.of(context).pop();
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
                  // Sidebar - Available dates
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Available Logs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: availableDatesAsync.when(
                              data: (dates) {
                                if (dates.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'No logs yet.\nComplete some micro-breaks to see them here.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: dates.length,
                                  itemBuilder: (context, index) {
                                    final date = dates[index];
                                    final isSelected = selectedDate != null &&
                                        selectedDate.year == date.year &&
                                        selectedDate.month == date.month &&
                                        selectedDate.day == date.day;
                                    
                                    final isToday = DateTime.now().year == date.year &&
                                        DateTime.now().month == date.month &&
                                        DateTime.now().day == date.day;

                                    return ListTile(
                                      title: Text(_formatDate(date)),
                                      subtitle: isToday ? const Text('Today') : null,
                                      selected: isSelected,
                                      onTap: () {
                                        ref.read(selectedLogDateProvider.notifier).state = date;
                                      },
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (error, _) => Center(
                                child: Text('Error loading dates: $error'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Main content - Log entries
                  Expanded(
                    child: selectedDate == null
                        ? const Center(
                            child: Text(
                              'Select a date to view logs',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : Column(
                            children: [
                              // Date header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(selectedDate),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    selectedEntriesAsync.when(
                                      data: (entries) {
                                        final totalDuration = entries.fold(
                                          Duration.zero,
                                          (sum, entry) => sum + entry.duration,
                                        );
                                        return Text(
                                          '${entries.length} sessions • ${_formatDuration(totalDuration)} total',
                                          style: const TextStyle(color: Colors.grey),
                                        );
                                      },
                                      loading: () => const Text(
                                        'Loading...',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      error: (_, __) => const Text(
                                        'Error loading data',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Log entries
                              Expanded(
                                child: selectedEntriesAsync.when(
                                  data: (entries) {
                                    if (entries.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'No sessions on this date',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: entries.length,
                                      itemBuilder: (context, index) {
                                        return _buildLogEntry(entries[index]);
                                      },
                                    );
                                  },
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (error, _) => Center(
                                    child: Text('Error loading entries: $error'),
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