import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Settings page for app configuration
/// 
/// Provides access to app settings, preferences,
/// and configuration options.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Development Section
          _SectionHeader(title: 'Development & Demos'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme System Demo'),
            subtitle: const Text('CHECKPOINT 3.1: Theme customization showcase'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'COMPLETED',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => context.go('/profile/settings/theme-demo'),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Reading Tools Demo'),
            subtitle: const Text('CHECKPOINT 3.2: Bookmarks, highlights & progress'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'COMPLETED',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => context.go('/profile/settings/reading-tools-demo'),
          ),
          
          const Divider(),
          
          // Settings Section
          _SectionHeader(title: 'App Settings'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Display'),
            subtitle: const Text('Theme, brightness, and appearance'),
            onTap: () {
              // TODO: Navigate to display settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Reading'),
            subtitle: const Text('Font size, line spacing, and reading preferences'),
            onTap: () {
              // TODO: Navigate to reading settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('Sync & Backup'),
            subtitle: const Text('Cloud synchronization and data backup'),
            onTap: () {
              // TODO: Navigate to sync settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Reading reminders and app notifications'),
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          
          const Divider(),
          
          // About Section
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About LiteraLib'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              // TODO: Show about dialog
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact support'),
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Learn about your privacy'),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
