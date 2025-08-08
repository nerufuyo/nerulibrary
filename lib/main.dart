import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/supabase_config.dart';
import 'core/startup/app_startup_manager.dart';
import 'features/reader/presentation/providers/theme_providers.dart';
import 'app.dart';

/// Main entry point for the LiteraLib application
/// 
/// Initializes core services and providers before starting the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize performance monitoring and optimized startup
  await AppStartupManager.instance.initialize();
  
  // Initialize Supabase
  await SupabaseConfig.instance.initialize();
  
  // Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: AppInitializer(
        child: const LiteraLibApp(),
      ),
    ),
  );
}
