import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/reader/presentation/providers/theme_providers.dart';

/// Main application widget for LiteraLib
/// 
/// Configures theming, routing, and global app settings
/// using Material Design 3 and go_router navigation.
class LiteraLibApp extends ConsumerWidget {
  const LiteraLibApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeConfig = ref.watch(themeNotifierProvider);
    
    return themeConfig.when(
      loading: () => MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp.router(
        title: 'LiteraLib',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        supportedLocales: const [Locale('en', 'US')],
      ),
      data: (config) => MaterialApp.router(
        title: 'LiteraLib',
        debugShowCheckedModeBanner: false,
        
        // Theme Configuration from Theme System
        theme: config.getAppThemeData(),
        darkTheme: config.getAppThemeData(),
        themeMode: config.effectiveThemeMode,
        
        // Router Configuration
        routerConfig: router,
        
        // Accessibility and Localization
        supportedLocales: const [
          Locale('en', 'US'),
        ],
      ),
    );
  }
}

/// Shared preferences provider initialization helper
class AppProviders {
  static Future<ProviderContainer> createContainer() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
    );
    
    return container;
  }
}
