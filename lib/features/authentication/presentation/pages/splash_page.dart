import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_paths.dart';
import '../providers/auth_providers.dart';

/// Splash page for app initialization and authentication check
/// 
/// Displays app logo and branding while checking user authentication
/// status and automatically redirecting to appropriate screen.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check authentication status
    final authState = ref.read(currentUserProvider);
    
    if (authState.hasValue && authState.value != null) {
      // User is authenticated, go to library
      context.go(RoutePaths.library);
    } else {
      // User is not authenticated, go to login
      context.go(RoutePaths.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.library_books,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Name
            Text(
              'LiteraLib',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // App Tagline
            Text(
              'Your Digital Library Companion',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading Indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
