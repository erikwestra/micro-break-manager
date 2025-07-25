import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:micro_break_manager/main.dart';

void main() {
  testWidgets('Main window loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MicroBreakApp(),
      ),
    );

    // Wait for first frame
    await tester.pump();

    // Should find the main window structure
    expect(find.byType(MainWindow), findsOneWidget);
  });

  testWidgets('Error view displays properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const ErrorView(error: 'Test error message'),
      ),
    );

    expect(find.text('Error: Test error message'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('Idle view displays properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const IdleView(),
      ),
    );

    expect(find.text('Micro-Break'), findsOneWidget);
  });

  testWidgets('Active break view displays properly', (WidgetTester tester) async {
    final startTime = DateTime.now().subtract(const Duration(minutes: 2, seconds: 30));
    
    await tester.pumpWidget(
      MaterialApp(
        home: ActiveBreakView(
          listName: 'Test List',
          itemText: 'Test Exercise',
          startTime: startTime,
        ),
      ),
    );

    expect(find.text('Test Exercise'), findsOneWidget);
    
    // Should show elapsed time (02:30 or similar)
    expect(find.textContaining('02:'), findsOneWidget);
  });
}
