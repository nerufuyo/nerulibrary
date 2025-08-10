import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/authentication/presentation/providers/guest_mode_provider.dart';
import 'route_paths.dart';

/// Route guard provider for managing navigation permissions
/// 
/// Handles authentication-based route protection and redirects
/// users to appropriate pages based on their authentication status.
final routeGuardProvider = Provider<RouteGuard>((ref) {
  return RouteGuard(ref);
});

/// Route guard implementation for authentication and authorization
/// 
/// Provides centralized logic for route protection, ensuring users
/// can only access pages they are authorized to view based on their
/// authentication status and app state.
class RouteGuard extends ChangeNotifier {
  final Ref _ref;
  
  RouteGuard(this._ref) {
    // Listen to auth state changes and notify router
    _ref.listen(currentUserProvider, (previous, next) {
      notifyListeners();
    });
    
    // Listen to guest mode changes and notify router
    _ref.listen(guestModeProvider, (previous, next) {
      notifyListeners();
    });
  }

  /// Main redirect logic for route protection
  /// 
  /// Determines if a user should be redirected based on their current
  /// authentication status, guest mode, and the route they're trying to access.
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(currentUserProvider);
    final isLoggedIn = authState.hasValue && authState.value != null;
    final accessMode = _ref.read(appAccessModeProvider);
    final currentLocation = state.uri.path;

    // Allow access to authentication pages when not logged in
    if (!isLoggedIn) {
      if (_isAuthRoute(currentLocation)) {
        return null; // Allow access to auth routes
      }
      
      // If user has guest mode enabled, allow access to main app
      if (accessMode.canReadBooks) {
        return null; // Allow guest access to app
      }
      
      // Redirect to splash for auth choice
      return RoutePaths.splash;
    }

    // Redirect logged-in users away from auth pages
    if (isLoggedIn && _isAuthRoute(currentLocation)) {
      return RoutePaths.library;
    }

    // Allow access to all other routes when logged in or in guest mode
    return null;
  }

  /// Check if the current route is an authentication route
  bool _isAuthRoute(String location) {
    return location == RoutePaths.splash ||
           location == RoutePaths.login ||
           location == RoutePaths.register;
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    final authState = _ref.read(currentUserProvider);
    return authState.hasValue && authState.value != null;
  }

  /// Check if user can access a specific route
  bool canAccessRoute(String routePath) {
    final accessMode = _ref.read(appAccessModeProvider);
    
    if (_isAuthRoute(routePath)) {
      return !isAuthenticated; // Can access auth routes only when not logged in
    }
    
    // Allow access to main app routes in guest mode or authenticated mode
    return accessMode.canReadBooks;
  }

  /// Get appropriate initial location based on auth state
  String getInitialLocation() {
    final accessMode = _ref.read(appAccessModeProvider);
    
    if (accessMode.isAuthenticated) {
      return RoutePaths.library;
    } else if (accessMode.isGuest) {
      return RoutePaths.library;
    } else {
      return RoutePaths.splash;
    }
  }

  /// Check if guest mode is enabled
  bool get isGuestMode {
    final accessMode = _ref.read(appAccessModeProvider);
    return accessMode.isGuest;
  }

  /// Check if user can save/favorite books
  bool get canSaveBooks {
    final accessMode = _ref.read(appAccessModeProvider);
    return accessMode.canSaveBooks;
  }
}

/// Navigation helper methods for common navigation patterns
/// 
/// Provides utility methods for common navigation scenarios
/// with proper error handling and state management.
class NavigationHelper {
  /// Navigate to login page with optional return path
  static void toLogin(BuildContext context, {String? returnPath}) {
    if (returnPath != null) {
      context.go('${RoutePaths.login}?return=$returnPath');
    } else {
      context.go(RoutePaths.login);
    }
  }

  /// Show authentication required dialog
  static void showAuthRequiredDialog(
    BuildContext context, {
    String title = 'Login Required',
    String message = 'Please log in to save books and access your personal library.',
    VoidCallback? onLogin,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
                toLogin(context);
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  /// Navigate to book detail page
  static void toBookDetail(BuildContext context, String bookId) {
    context.go(RoutePaths.buildBookDetailPath(bookId));
  }

  /// Navigate to PDF reader
  static void toPdfReader(
    BuildContext context, 
    String bookId, 
    {String? filePath}
  ) {
    final uri = Uri.parse(RoutePaths.buildPdfReaderPath(bookId));
    if (filePath != null) {
      final newUri = uri.replace(queryParameters: {'path': filePath});
      context.go(newUri.toString());
    } else {
      context.go(uri.toString());
    }
  }

  /// Navigate to EPUB reader
  static void toEpubReader(
    BuildContext context, 
    String bookId, 
    {String? filePath}
  ) {
    final uri = Uri.parse(RoutePaths.buildEpubReaderPath(bookId));
    if (filePath != null) {
      final newUri = uri.replace(queryParameters: {'path': filePath});
      context.go(newUri.toString());
    } else {
      context.go(uri.toString());
    }
  }

  /// Navigate to search with optional query
  static void toSearch(BuildContext context, {String? query}) {
    if (query != null && query.isNotEmpty) {
      context.go('${RoutePaths.discovery}/search?q=${Uri.encodeComponent(query)}');
    } else {
      context.go('${RoutePaths.discovery}/search');
    }
  }

  /// Pop navigation stack or go to library if no previous route
  static void popOrToLibrary(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.library);
    }
  }

  /// Check if current route is reader route
  static bool isReaderRoute(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return location.startsWith('/reader/');
  }

  /// Get current route name
  static String getCurrentRouteName(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    
    if (location == RoutePaths.splash) return RouteNames.splash;
    if (location == RoutePaths.login) return RouteNames.login;
    if (location == RoutePaths.register) return RouteNames.register;
    if (location.startsWith(RoutePaths.library)) return RouteNames.library;
    if (location.startsWith(RoutePaths.discovery)) return RouteNames.discovery;
    if (location.startsWith(RoutePaths.profile)) return RouteNames.profile;
    if (location.contains('/reader/pdf/')) return RouteNames.pdfReader;
    if (location.contains('/reader/epub/')) return RouteNames.epubReader;
    
    return 'unknown';
  }
}
