import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/authentication/presentation/providers/guest_mode_provider.dart';
import '../../core/navigation/route_paths.dart';

/// User profile page showing account information
/// 
/// Displays user profile information, reading statistics,
/// and account management options.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessMode = ref.watch(appAccessModeProvider);
    final authState = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (accessMode.isGuest)
            TextButton(
              onPressed: () => context.go(RoutePaths.login),
              child: const Text('Login'),
            ),
        ],
      ),
      body: accessMode.isAuthenticated 
          ? _buildAuthenticatedProfile(context, ref, authState)
          : _buildGuestProfile(context, ref),
    );
  }

  Widget _buildAuthenticatedProfile(
    BuildContext context, 
    WidgetRef ref, 
    AsyncValue user,
  ) {
    return user.when(
      data: (userData) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Avatar and Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData?.name ?? 'User',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      userData?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Profile Options
            _buildProfileOption(
              context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () => context.go(RoutePaths.profile + '/settings'),
            ),
            _buildProfileOption(
              context,
              icon: Icons.book,
              title: 'Reading Statistics',
              onTap: () {
                // TODO: Navigate to reading statistics
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.cloud_sync,
              title: 'Sync Data',
              onTap: () {
                // TODO: Trigger data sync
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: () => _showSignOutDialog(context, ref),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading profile: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestProfile(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Guest Avatar and Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Icon(
                      Icons.person_outline,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Guest User',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    'Browsing in guest mode',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Guest Mode Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Guest Mode',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You\'re browsing as a guest. Create an account to:',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem(context, 'Save favorite books'),
                  _buildFeatureItem(context, 'Sync across devices'),
                  _buildFeatureItem(context, 'Track reading progress'),
                  _buildFeatureItem(context, 'Create custom collections'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go(RoutePaths.login),
              child: const Text('Sign In'),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(RoutePaths.register),
              child: const Text('Create Account'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Basic Settings (available to guests)
          _buildProfileOption(
            context,
            icon: Icons.settings,
            title: 'App Settings',
            onTap: () => context.go(RoutePaths.profile + '/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(currentUserProvider.notifier).signOut();
              if (context.mounted) {
                context.go(RoutePaths.splash);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
