import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/presentation/providers/guest_mode_provider.dart';
import '../navigation/route_guards.dart';

/// Utility class for handling authentication requirements
///
/// Provides helper methods to check authentication status and show
/// appropriate dialogs when authentication is required for certain features.
class AuthenticationHelper {
  /// Check if user can perform save/favorite operations
  /// 
  /// Returns true if authenticated, false if guest or not logged in.
  /// Shows authentication dialog if required.
  static bool canSaveBooks(
    BuildContext context, 
    WidgetRef ref, {
    bool showDialogIfRequired = true,
    String? customMessage,
  }) {
    final accessMode = ref.read(appAccessModeProvider);
    
    if (accessMode.canSaveBooks) {
      return true;
    }
    
    if (showDialogIfRequired) {
      showAuthRequiredDialog(
        context,
        title: 'Login Required',
        message: customMessage ?? 
          'Please log in to save books to your personal library. '
          'This will sync your favorites across all your devices.',
      );
    }
    
    return false;
  }

  /// Check if user can access sync features
  static bool canSync(
    BuildContext context,
    WidgetRef ref, {
    bool showDialogIfRequired = true,
    String? customMessage,
  }) {
    final accessMode = ref.read(appAccessModeProvider);
    
    if (accessMode.canSync) {
      return true;
    }
    
    if (showDialogIfRequired) {
      showAuthRequiredDialog(
        context,
        title: 'Account Required',
        message: customMessage ?? 
          'Create an account to sync your library across devices and '
          'access your books from anywhere.',
      );
    }
    
    return false;
  }

  /// Check if user can access profile features
  static bool canAccessProfile(
    BuildContext context,
    WidgetRef ref, {
    bool showDialogIfRequired = true,
    String? customMessage,
  }) {
    final accessMode = ref.read(appAccessModeProvider);
    
    if (accessMode.canAccessProfile) {
      return true;
    }
    
    if (showDialogIfRequired) {
      showAuthRequiredDialog(
        context,
        title: 'Login Required',
        message: customMessage ?? 
          'Please log in to access your profile and reading statistics.',
      );
    }
    
    return false;
  }

  /// Show authentication required dialog with customizable options
  static void showAuthRequiredDialog(
    BuildContext context, {
    String title = 'Authentication Required',
    String message = 'Please log in to access this feature.',
    String loginButtonText = 'Login',
    String cancelButtonText = 'Cancel',
    VoidCallback? onLogin,
    VoidCallback? onCancel,
  }) {
    NavigationHelper.showAuthRequiredDialog(
      context,
      title: title,
      message: message,
      onLogin: onLogin,
    );
  }

  /// Show save book dialog for guests
  static void showSaveBookDialog(
    BuildContext context, {
    String bookTitle = 'this book',
    VoidCallback? onLogin,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To save "$bookTitle" to your library, please log in.'),
            const SizedBox(height: 16),
            const Text(
              'With an account you can:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(context, 'Save favorite books'),
            _buildBenefitItem(context, 'Sync across devices'),
            _buildBenefitItem(context, 'Track reading progress'),
            _buildBenefitItem(context, 'Create collections'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onLogin != null) {
                onLogin();
              } else {
                NavigationHelper.toLogin(context);
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  /// Show favorite book dialog for guests
  static void showFavoriteBookDialog(
    BuildContext context, {
    String bookTitle = 'this book',
    VoidCallback? onLogin,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Add to Favorites'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('To add "$bookTitle" to your favorites, please log in.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_sync,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your favorites will sync across all your devices!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onLogin != null) {
                onLogin();
              } else {
                NavigationHelper.toLogin(context);
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  static Widget _buildBenefitItem(BuildContext context, String text) {
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

  /// Check if current user is in guest mode
  static bool isGuestMode(WidgetRef ref) {
    final accessMode = ref.read(appAccessModeProvider);
    return accessMode.isGuest;
  }

  /// Check if current user is authenticated
  static bool isAuthenticated(WidgetRef ref) {
    final accessMode = ref.read(appAccessModeProvider);
    return accessMode.isAuthenticated;
  }

  /// Get the current access mode
  static AppAccessMode getAccessMode(WidgetRef ref) {
    return ref.read(appAccessModeProvider);
  }
}
