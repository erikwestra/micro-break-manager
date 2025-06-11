// ABOUTME: Native macOS menu bar configuration and routing to dialogs
// ABOUTME: Integrates with Flutter's PlatformMenuBar for native menu experience

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../main.dart';
import 'setup_lists_dialog.dart';
import 'view_logs_dialog.dart';

class AppMenuBar extends StatelessWidget {
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

  void _showSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SetupListsDialog(),
    );
  }

  void _showLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ViewLogsDialog(),
    );
  }

  void _quitApp() async {
    quitApp();
  }

  @override
  Widget build(BuildContext context) {
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
          label: 'Manage',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Setup Micro-Breaks...',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                  onSelected: () => _showSetupDialog(context),
                ),
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
          ],
        ),
      ],
      child: child,
    );
  }
}