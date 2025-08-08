import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/performance_service.dart';
import '../config/supabase_config.dart';

/// Optimized app startup manager
///
/// Handles app initialization with performance optimizations,
/// lazy loading, and startup time monitoring.
class AppStartupManager {
  static AppStartupManager? _instance;
  static AppStartupManager get instance => _instance ??= AppStartupManager._();

  AppStartupManager._();

  bool _isInitialized = false;
  SharedPreferences? _sharedPreferences;
  final Completer<void> _initializationCompleter = Completer<void>();

  /// Future that completes when app is fully initialized
  Future<void> get initialized => _initializationCompleter.future;

  /// Check if app is initialized
  bool get isInitialized => _isInitialized;

  /// Get shared preferences instance (available after initialization)
  SharedPreferences get sharedPreferences {
    if (_sharedPreferences == null) {
      throw StateError('App not initialized. Call initialize() first.');
    }
    return _sharedPreferences!;
  }

  /// Initialize app with performance optimizations
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Start performance monitoring
    PerformanceService.instance.initialize();
    PerformanceService.instance.startTiming('app_initialization');

    try {
      // Ensure Flutter binding is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Configure app for performance
      await _configureAppForPerformance();

      // Initialize critical services in parallel
      await _initializeCriticalServices();

      // Initialize non-critical services asynchronously
      _initializeNonCriticalServices();

      _isInitialized = true;
      _initializationCompleter.complete();

      // Mark app as ready for performance tracking
      PerformanceService.instance.markAppReady();
      PerformanceService.instance.stopTiming('app_initialization');
    } catch (error, stackTrace) {
      _initializationCompleter.completeError(error, stackTrace);
      PerformanceService.instance.stopTiming('app_initialization',
          metadata: {'error': error.toString()});
      rethrow;
    }
  }

  /// Configure app for optimal performance
  Future<void> _configureAppForPerformance() async {
    PerformanceService.instance.startTiming('performance_configuration');

    // Set target frame rate for optimal performance
    if (!kDebugMode) {
      // In release mode, ensure smooth animations
      WidgetsBinding.instance.deferFirstFrame();
    }

    // Configure system UI for performance
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Configure image cache for optimal memory usage
    PerformanceService.instance.optimizeImageLoading();

    PerformanceService.instance.stopTiming('performance_configuration');
  }

  /// Initialize critical services that block app startup
  Future<void> _initializeCriticalServices() async {
    PerformanceService.instance.startTiming('critical_services_init');

    // Initialize services in parallel for faster startup
    final futures = <Future>[
      _initializeSharedPreferences(),
      _initializeSupabase(),
    ];

    await Future.wait(futures);

    PerformanceService.instance.stopTiming('critical_services_init');
  }

  /// Initialize SharedPreferences
  Future<void> _initializeSharedPreferences() async {
    PerformanceService.instance.startTiming('shared_preferences_init');

    _sharedPreferences = await SharedPreferences.getInstance();

    PerformanceService.instance.stopTiming('shared_preferences_init');
  }

  /// Initialize Supabase
  Future<void> _initializeSupabase() async {
    PerformanceService.instance.startTiming('supabase_init');

    await SupabaseConfig.instance.initialize();

    PerformanceService.instance.stopTiming('supabase_init');
  }

  /// Initialize non-critical services asynchronously
  void _initializeNonCriticalServices() {
    // Run in background without blocking app startup
    _initializeBackgroundServices();
  }

  /// Initialize background services
  Future<void> _initializeBackgroundServices() async {
    // Database warmup
    _warmupDatabase();

    // Cache warmup
    _warmupCache();

    // Network connectivity check
    _checkNetworkConnectivity();
  }

  /// Warmup database connections
  Future<void> _warmupDatabase() async {
    try {
      PerformanceService.instance.startTiming('database_warmup');

      // Perform a simple database operation to warm up connections
      // This would connect to your SQLite database and perform a simple query

      PerformanceService.instance.stopTiming('database_warmup');
    } catch (e) {
      // Silently handle warmup errors
      if (kDebugMode) {
        print('Database warmup failed: $e');
      }
    }
  }

  /// Warmup image and data caches
  Future<void> _warmupCache() async {
    try {
      PerformanceService.instance.startTiming('cache_warmup');

      // Preload critical app assets
      // This could include app icons, default images, etc.

      PerformanceService.instance.stopTiming('cache_warmup');
    } catch (e) {
      // Silently handle warmup errors
      if (kDebugMode) {
        print('Cache warmup failed: $e');
      }
    }
  }

  /// Check network connectivity
  Future<void> _checkNetworkConnectivity() async {
    try {
      PerformanceService.instance.startTiming('network_check');

      // Check network connectivity for sync and API features
      // This would use connectivity_plus package to check status

      PerformanceService.instance.stopTiming('network_check');
    } catch (e) {
      // Silently handle connectivity errors
      if (kDebugMode) {
        print('Network check failed: $e');
      }
    }
  }

  /// Allow first frame to be drawn (for deferred frame loading)
  void allowFirstFrame() {
    if (!kDebugMode) {
      WidgetsBinding.instance.allowFirstFrame();
    }
  }
}

/// Optimized app initialization widget
///
/// Shows loading screen while app initializes and transitions
/// to main app when ready.
class AppInitializer extends StatefulWidget {
  final Widget child;
  final Widget? loadingWidget;

  const AppInitializer({
    super.key,
    required this.child,
    this.loadingWidget,
  });

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await AppStartupManager.instance.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Allow first frame after initialization
        AppStartupManager.instance.allowFirstFrame();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isInitialized = false;
                    });
                    _initializeApp();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return widget.loadingWidget ?? _buildDefaultLoadingWidget();
    }

    return widget.child;
  }

  Widget _buildDefaultLoadingWidget() {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.book,
                  size: 40,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 24),

              // App name
              const Text(
                'LiteraLib',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'Your Digital Library',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // Loading indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
