## Running the App

- Erik will always run the Flutter app himself
- Do NOT use `flutter run` commands - Erik handles all app execution
- Focus on code changes, fixes, and feature implementation only
- If testing is needed, ask Erik to run the app and report results

## Development Workflow

- Make code changes as requested
- Explain what was changed and why
- Let Erik handle running and testing the app
- Respond to any runtime issues Erik reports by fixing the code

## Native macOS Window Management

- This app uses the `window_manager` package for proper Mac-style window behavior
- **Critical Implementation**: Requires BOTH native macOS code AND Flutter window listener changes:

### Native AppDelegate Changes (`macos/Runner/AppDelegate.swift`):
```swift
override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false  // Keeps app alive when all windows are hidden
}

override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
        // Dock click with no visible windows - show main window
        if let window = mainFlutterWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    return true
}

override func applicationDidBecomeActive(_ notification: Notification) {
    // CMD+Tab activation - show window if no visible windows
    if NSApp.windows.filter({ $0.isVisible }).isEmpty {
        if let window = mainFlutterWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
```

### Flutter WindowListener Changes (`main.dart`):
```dart
class _MyAppState extends State<MyApp> with WindowListener {
    static bool _isQuitting = false;

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
        // Ensure window is visible when it gains focus
        bool isVisible = await windowManager.isVisible();
        if (!isVisible) {
            await windowManager.show();
            await windowManager.focus();
        }
    }

    static void _quitApp() async {
        if (!kIsWeb) {
            _MyAppState._isQuitting = true;
            await windowManager.destroy();
        } else {
            SystemNavigator.pop();
        }
    }
}
```

- **Behavior**: App stays running in Dock when hidden, restored by dock click OR CMD+Tab
- **Window Manager Setup**: Initialized in `main()` with `setPreventClose(true)`
- **Menu Integration**: "Hide Task Manager" (⌘H) uses `windowManager.hide()`, "Quit" (⌘Q) uses `windowManager.close()`

## UI Guidelines

### Snackbars in Modal Dialogs
- **NEVER use snackbars in modal dialogs** - they are either hidden behind the modal or barely visible
- Use AlertDialog for error messages and confirmations instead
- Silent operations with button state changes are preferred for simple feedback (save/cancel states)

## Flutter API References

- ALWAYS use the API reference in `/Users/erik/Development/api-reference/flutter-api` for all Flutter development
- ALWAYS use the API reference in `/Users/erik/Development/api-reference/flutter-macos-widgets-and-themes` when building macOS apps in Flutter
- Do NOT use any external API references
- Do NOT guess at API methods or constructors - check the local references first
- If unsure about an API, ask Erik to verify the correct syntax rather than guessing