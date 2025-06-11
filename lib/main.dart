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
  const dialogSize = Size(1200, 800);
  final currentSize = await windowManager.getSize();
  
  if (currentSize.width < dialogSize.width || currentSize.height < dialogSize.height) {
    final newWidth = currentSize.width < dialogSize.width ? dialogSize.width : currentSize.width;
    final newHeight = currentSize.height < dialogSize.height ? dialogSize.height : currentSize.height;
    await windowManager.setSize(Size(newWidth, newHeight));
    await windowManager.center();
  }
}

Future<void> restoreWindowSize() async {
  if (_originalWindowSize != null) {
    await windowManager.setSize(_originalWindowSize!);
    await windowManager.center();
    _originalWindowSize = null;
  }
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
    minimumSize: Size(400, 300),
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
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

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final breakNotifier = ref.read(breakStateProvider.notifier);
      final breakState = ref.read(breakStateProvider);
      
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (breakState.isActive) {
          breakNotifier.finishBreak();
        } else {
          breakNotifier.startBreak();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (breakState.isActive) {
          breakNotifier.cancelBreak();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakState = ref.watch(breakStateProvider);
    final listsAsync = ref.watch(microBreakListsProvider);
    
    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: _handleKeyEvent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(24),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.list_alt,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'No micro-break lists found',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Go to Setup Micro-Breaks to create your first list',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[500],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.play_arrow_rounded,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Ready for your next micro-break',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Press Space to start',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            listName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          itemText,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            final elapsed = DateTime.now().difference(startTime);
            final minutes = elapsed.inMinutes;
            final seconds = elapsed.inSeconds % 60;
            
            return Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Space',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' to finish • ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Escape',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' to cancel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Error loading data',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}