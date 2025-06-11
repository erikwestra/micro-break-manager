// ABOUTME: Model representing a completed micro-break session with timestamps
// ABOUTME: Serializes to/from tab-delimited format for daily log files

class LogEntry {
  final DateTime start;
  final DateTime end;
  final String listName;
  final String itemText;

  const LogEntry({
    required this.start,
    required this.end,
    required this.listName,
    required this.itemText,
  });

  factory LogEntry.fromTsv(String line) {
    final parts = line.split('\t');
    if (parts.length != 5) {
      throw FormatException('Invalid log entry format: expected 5 fields, got ${parts.length}');
    }

    final date = parts[0];
    final startTime = parts[1];
    final endTime = parts[2];
    final listName = parts[3];
    final itemText = parts[4];

    final startDateTime = DateTime.parse('$date $startTime');
    final endDateTime = DateTime.parse('$date $endTime');

    return LogEntry(
      start: startDateTime,
      end: endDateTime,
      listName: listName,
      itemText: itemText,
    );
  }

  String toTsv() {
    final dateStr = '${start.year.toString().padLeft(4, '0')}-'
        '${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';
    
    final startTimeStr = '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}:'
        '${start.second.toString().padLeft(2, '0')}';
    
    final endTimeStr = '${end.hour.toString().padLeft(2, '0')}:'
        '${end.minute.toString().padLeft(2, '0')}:'
        '${end.second.toString().padLeft(2, '0')}';

    return '$dateStr\t$startTimeStr\t$endTimeStr\t$listName\t$itemText';
  }

  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntry &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          listName == other.listName &&
          itemText == other.itemText;

  @override
  int get hashCode =>
      start.hashCode ^ end.hashCode ^ listName.hashCode ^ itemText.hashCode;

  @override
  String toString() => 'LogEntry(start: $start, end: $end, listName: $listName, itemText: $itemText)';
}