// ABOUTME: Main entry point for the Micro-Break Manager macOS application
// ABOUTME: Sets up Riverpod providers and window management for native macOS behavior

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/app_providers.dart';
import 'services/file_storage_service.dart';
import 'widgets/app_menu.dart';

// Global quit flag and function
bool _isQuitting = false;

void quitApp() async {
  _isQuitting = true;
  await windowManager.destroy();
}

// Window resize utilities for dialogs
Size? _originalWindowSize;

Future<void> prepareWindowForLargeDialog() async {
  _originalWindowSize = await windowManager.getSize();
  const dialogSize = Size(1000, 700);
  await windowManager.setSize(dialogSize);
  await windowManager.center();
}

Future<void> restoreWindowSize() async {
  // Always restore to the fixed 400x100 size
  await windowManager.setSize(const Size(400, 100));
  await windowManager.center();
  _originalWindowSize = null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window manager
  await windowManager.ensureInitialized();
  
  // Purge old logs on startup
  try {
    final storage = FileStorageService();
    await storage.purgeOldLogs();
  } catch (e) {
    print('Error purging old logs: $e');
  }
  
  const windowOptions = WindowOptions(
    size: Size(400, 100),
    minimumSize: Size(400, 100),
    maximumSize: Size(400, 100),
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
    title: 'Micro-Break Manager',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });
  
  runApp(
    const ProviderScope(
      child: MicroBreakApp(),
    ),
  );
}

class MicroBreakApp extends StatefulWidget {
  const MicroBreakApp({super.key});

  @override
  State<MicroBreakApp> createState() => _MicroBreakAppState();
}

class _MicroBreakAppState extends State<MicroBreakApp> with WindowListener {

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // If we're quitting, allow the close to proceed
    if (_isQuitting) {
      return;
    }
    
    // Otherwise, hide the window instead of closing
    await windowManager.hide();
  }

  @override
  void onWindowFocus() async {
    // When window gains focus, make sure it's visible
    bool isVisible = await windowManager.isVisible();
    if (!isVisible) {
      await windowManager.show();
      await windowManager.focus();
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Micro-Break Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AppMenuBar(child: MainWindow()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainWindow extends ConsumerStatefulWidget {
  const MainWindow({super.key});

  @override
  ConsumerState<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends ConsumerState<MainWindow> {

  @override
  Widget build(BuildContext context) {
    final breakState = ref.watch(breakStateProvider);
    final listsAsync = ref.watch(microBreakListsProvider);
    
    
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // Pale blue
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          windowManager.startDragging();
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Center(
            child: listsAsync.when(
              data: (lists) {
                if (lists.isEmpty) {
                  return const NoListsView();
                }
                
                if (breakState.isActive) {
                  return ActiveBreakView(
                    listName: breakState.currentList?.name ?? '',
                    itemText: breakState.currentItem?.text ?? '',
                    startTime: breakState.startTime ?? DateTime.now(),
                  );
                } else {
                  return const IdleView();
                }
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => ErrorView(error: error.toString()),
            ),
          ),
        ),
      ),
    );
  }
}

class NoListsView extends StatelessWidget {
  const NoListsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.list_alt,
          size: 24,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Text(
          'No lists - use Setup menu',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class IdleView extends StatelessWidget {
  const IdleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Micro-Break',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class ActiveBreakView extends StatelessWidget {
  final String listName;
  final String itemText;
  final DateTime startTime;

  const ActiveBreakView({
    super.key,
    required this.listName,
    required this.itemText,
    required this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Timer
        StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            final elapsed = DateTime.now().difference(startTime);
            final minutes = elapsed.inMinutes;
            final seconds = elapsed.inSeconds % 60;
            
            return Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
        const SizedBox(width: 24),
        // Description
        Expanded(
          child: Text(
            itemText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class ErrorView extends StatelessWidget {
  final String error;

  const ErrorView({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 24,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Error: $error',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}