// ABOUTME: Native macOS menu bar configuration and routing to dialogs
// ABOUTME: Integrates with Flutter's PlatformMenuBar for native menu experience

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../main.dart';
import '../providers/app_providers.dart';
import 'setup_lists_dialog.dart';
import 'view_logs_dialog.dart';

class AppMenuBar extends ConsumerWidget {
  final Widget child;

  const AppMenuBar({super.key, required this.child});

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Micro-Break Manager',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(Icons.self_improvement, size: 64),
        children: const [
          Text('A structured micro-break manager that rotates through multiple user-defined micro-break lists.'),
        ],
      ),
    );
  }

  void _showSetupDialog(BuildContext context) async {
    await prepareWindowForLargeDialog();
    showDialog(
      context: context,
      builder: (context) => const SetupListsDialog(),
    ).then((_) {
      restoreWindowSize();
    });
  }

  void _showLogsDialog(BuildContext context) async {
    await prepareWindowForLargeDialog();
    showDialog(
      context: context,
      builder: (context) => const ViewLogsDialog(),
    ).then((_) {
      restoreWindowSize();
    });
  }

  void _showListsInFinder(WidgetRef ref) async {
    final storage = ref.read(storageServiceProvider);
    await storage.showListsInFinder();
  }

  void _showLogsInFinder(WidgetRef ref) async {
    final storage = ref.read(storageServiceProvider);
    await storage.showLogsInFinder();
  }

  void _quitApp() async {
    quitApp();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakState = ref.watch(breakStateProvider);
    final breakNotifier = ref.read(breakStateProvider.notifier);
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'Micro-Break Manager',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'About Micro-Break Manager',
                  onSelected: () => _showAboutDialog(context),
                ),
                PlatformMenuItem(
                  label: 'Setup Micro-Breaks...',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                  onSelected: () => _showSetupDialog(context),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Hide Micro-Break Manager',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyH,
                    meta: true,
                  ),
                  onSelected: () async {
                    await windowManager.hide();
                  },
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Quit Micro-Break Manager',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyQ,
                    meta: true,
                  ),
                  onSelected: () {
                    _quitApp();
                  },
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: 'Breaks',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: breakState.isActive ? 'Stop Micro-Break' : 'Start Micro-Break',
                  onSelected: breakState.isActive 
                    ? () => breakNotifier.finishBreak()
                    : () => breakNotifier.startBreak(),
                ),
                PlatformMenuItem(
                  label: 'Cancel Micro-Break',
                  shortcut: const SingleActivator(LogicalKeyboardKey.escape),
                  onSelected: breakState.isActive ? () => breakNotifier.cancelBreak() : null,
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: 'Utils',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'View Logs...',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyL,
                    meta: true,
                  ),
                  onSelected: () => _showLogsDialog(context),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Show Lists in Finder',
                  onSelected: () => _showListsInFinder(ref),
                ),
                PlatformMenuItem(
                  label: 'Show Logs in Finder',
                  onSelected: () => _showLogsInFinder(ref),
                ),
              ],
            ),
          ],
        ),
      ],
      child: child,
    );
  }
}