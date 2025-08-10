import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/authentication_helper.dart';

/// Widget that wraps authentication-required actions
///
/// Shows authentication dialog when guest users try to perform
/// actions that require authentication like saving or favoriting books.
class AuthRequiredWrapper extends ConsumerWidget {
  final Widget child;
  final VoidCallback onAction;
  final String? authTitle;
  final String? authMessage;
  final bool showDialogOnUnauthorized;

  const AuthRequiredWrapper({
    super.key,
    required this.child,
    required this.onAction,
    this.authTitle,
    this.authMessage,
    this.showDialogOnUnauthorized = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (AuthenticationHelper.canSaveBooks(
          context,
          ref,
          showDialogIfRequired: showDialogOnUnauthorized,
          customMessage: authMessage,
        )) {
          onAction();
        }
      },
      child: child,
    );
  }
}

/// Specific wrapper for favorite button
class FavoriteAuthWrapper extends ConsumerWidget {
  final Widget child;
  final VoidCallback onFavorite;
  final String? bookTitle;

  const FavoriteAuthWrapper({
    super.key,
    required this.child,
    required this.onFavorite,
    this.bookTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (AuthenticationHelper.canSaveBooks(context, ref, showDialogIfRequired: false)) {
          onFavorite();
        } else {
          AuthenticationHelper.showFavoriteBookDialog(
            context,
            bookTitle: bookTitle ?? 'this book',
          );
        }
      },
      child: child,
    );
  }
}

/// Specific wrapper for save book button
class SaveBookAuthWrapper extends ConsumerWidget {
  final Widget child;
  final VoidCallback onSave;
  final String? bookTitle;

  const SaveBookAuthWrapper({
    super.key,
    required this.child,
    required this.onSave,
    this.bookTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (AuthenticationHelper.canSaveBooks(context, ref, showDialogIfRequired: false)) {
          onSave();
        } else {
          AuthenticationHelper.showSaveBookDialog(
            context,
            bookTitle: bookTitle ?? 'this book',
          );
        }
      },
      child: child,
    );
  }
}

/// Badge widget that shows guest mode indicator
class GuestModeBadge extends ConsumerWidget {
  final Widget child;
  final bool showBadge;

  const GuestModeBadge({
    super.key,
    required this.child,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showBadge) return child;

    final isGuest = AuthenticationHelper.isGuestMode(ref);
    
    if (!isGuest) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Guest',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// App bar that shows guest mode status
class GuestAwareAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const GuestAwareAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = AuthenticationHelper.isGuestMode(ref);
    
    return AppBar(
      title: Text(title),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        if (isGuest)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(
                'Guest Mode',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              side: BorderSide.none,
            ),
          ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
