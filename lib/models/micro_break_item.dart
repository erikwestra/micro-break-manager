// ABOUTME: Model representing a single micro-break item with TSV serialization
// ABOUTME: Supports parsing from and converting to tab-delimited format

class MicroBreakItem {
  final String text;

  const MicroBreakItem({required this.text});

  factory MicroBreakItem.fromTsv(String line) {
    return MicroBreakItem(text: line.trim());
  }

  String toTsv() {
    return text;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MicroBreakItem &&
          runtimeType == other.runtimeType &&
          text == other.text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'MicroBreakItem(text: $text)';
}