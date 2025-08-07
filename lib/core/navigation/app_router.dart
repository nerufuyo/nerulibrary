import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/library/presentation/pages/book_detail_page.dart';
import '../../features/reader/presentation/pages/pdf_reader_page.dart';
import '../../features/reader/presentation/pages/epub_reader_page.dart';
import '../../features/reader/presentation/widgets/theme_demo_page.dart';
import '../../features/reader/presentation/pages/reading_tools_demo.dart';
import '../../features/discovery/presentation/pages/discovery_page.dart';
import '../../features/discovery/presentation/pages/search_page.dart';
import '../../shared/pages/settings_page.dart';
import '../../shared/pages/profile_page.dart';
import '../../shared/pages/error_page.dart';
import '../navigation/route_paths.dart';
import '../navigation/route_guards.dart';

/// Global router provider for the entire application
/// 
/// Provides centralized navigation management with authentication guards,
/// route definitions, and error handling following Material Design patterns.
final routerProvider = Provider<GoRouter>((ref) {
  final routeGuard = ref.read(routeGuardProvider);
  
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => ErrorPage(
      error: state.error.toString(),
      onRetry: () => context.go(RoutePaths.splash),
    ),
    redirect: (context, state) => routeGuard.redirect(context, state),
    refreshListenable: routeGuard,
    routes: [
      // Splash and Authentication Routes
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Main App Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Library Tab Routes
          GoRoute(
            path: RoutePaths.library,
            name: RouteNames.library,
            builder: (context, state) => const LibraryPage(),
            routes: [
              GoRoute(
                path: 'book/:bookId',
                name: RouteNames.bookDetail,
                builder: (context, state) {
                  final bookId = state.pathParameters['bookId']!;
                  return BookDetailPage(bookId: bookId);
                },
              ),
            ],
          ),
          
          // Discovery Tab Routes
          GoRoute(
            path: RoutePaths.discovery,
            name: RouteNames.discovery,
            builder: (context, state) => const DiscoveryPage(),
            routes: [
              GoRoute(
                path: 'search',
                name: RouteNames.search,
                builder: (context, state) {
                  final query = state.uri.queryParameters['q'] ?? '';
                  return SearchPage(initialQuery: query);
                },
              ),
            ],
          ),
          
          // Profile Tab Routes
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'settings',
                name: RouteNames.settings,
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'theme-demo',
                    name: 'theme-demo',
                    builder: (context, state) => const ThemeDemoPage(),
                  ),
                  GoRoute(
                    path: 'reading-tools-demo',
                    name: 'reading-tools-demo',
                    builder: (context, state) => const ReadingToolsDemo(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      
      // Reader Routes (Full Screen)
      GoRoute(
        path: RoutePaths.pdfReader,
        name: RouteNames.pdfReader,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final filePath = state.uri.queryParameters['path'] ?? '';
          return PdfReaderPage(bookId: bookId, filePath: filePath);
        },
      ),
      GoRoute(
        path: RoutePaths.epubReader,
        name: RouteNames.epubReader,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final filePath = state.uri.queryParameters['path'] ?? '';
          return EpubReaderPage(bookId: bookId, filePath: filePath);
        },
      ),
    ],
  );
});

/// App shell widget that provides the bottom navigation structure
/// 
/// Manages the main navigation tabs and provides consistent layout
/// across the authenticated sections of the app.
class AppShell extends ConsumerWidget {
  final Widget child;
  
  const AppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

/// Bottom navigation bar widget implementing Material Design 3 patterns
/// 
/// Provides tab navigation between Library, Discovery, and Profile sections
/// with proper state management and navigation guards.
class AppBottomNavigation extends ConsumerWidget {
  const AppBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    
    int getCurrentIndex() {
      if (location.startsWith(RoutePaths.library)) return 0;
      if (location.startsWith(RoutePaths.discovery)) return 1;
      if (location.startsWith(RoutePaths.profile)) return 2;
      return 0;
    }

    return NavigationBar(
      selectedIndex: getCurrentIndex(),
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go(RoutePaths.library);
            break;
          case 1:
            context.go(RoutePaths.discovery);
            break;
          case 2:
            context.go(RoutePaths.profile);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books),
          label: 'Library',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Discovery',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
