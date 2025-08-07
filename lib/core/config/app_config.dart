import 'dart:io';

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Application configuration management
/// 
/// Handles environment variables, debug settings, and app-wide configuration.
/// Provides centralized access to configuration values with proper defaults.
class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();
  
  AppConfig._();
  
  // Environment Variables
  String get supabaseUrl => _getEnvVar(AppConstants.ENV_SUPABASE_URL, '');
  String get supabaseAnonKey => _getEnvVar(AppConstants.ENV_SUPABASE_ANON_KEY, '');
  String get apiBaseUrl => _getEnvVar(AppConstants.ENV_API_BASE_URL, 'https://api.example.com');
  bool get debugMode => _getBoolEnvVar(AppConstants.ENV_DEBUG_MODE, kDebugMode);
  
  // App Information
  String get appName => AppConstants.APP_NAME;
  String get appVersion => AppConstants.APP_VERSION;
  String get buildNumber => AppConstants.APP_BUILD_NUMBER;
  
  // Platform Information
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isWeb => kIsWeb;
  bool get isMobile => isAndroid || isIOS;
  bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  
  // Feature Flags
  bool get enableAnalytics => !debugMode;
  bool get enableCrashReporting => !debugMode;
  bool get enablePerformanceMonitoring => !debugMode;
  bool get enableOfflineMode => true;
  bool get enableCloudSync => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  
  // Network Configuration
  Duration get networkTimeout => AppConstants.NETWORK_TIMEOUT;
  Duration get connectionTimeout => AppConstants.CONNECTION_TIMEOUT;
  Duration get receiveTimeout => AppConstants.RECEIVE_TIMEOUT;
  
  // File and Storage Configuration
  int get maxFileSizeMB => AppConstants.MAX_FILE_SIZE_MB;
  int get maxDownloadQueueSize => AppConstants.MAX_DOWNLOAD_QUEUE_SIZE;
  int get maxConcurrentDownloads => AppConstants.MAX_CONCURRENT_DOWNLOADS;
  
  // Cache Configuration
  Duration get cacheMetadataDuration => AppConstants.CACHE_DURATION_METADATA;
  Duration get cacheSearchDuration => AppConstants.CACHE_DURATION_SEARCH;
  Duration get cacheAuthorDuration => AppConstants.CACHE_DURATION_AUTHOR;
  
  // Performance Configuration
  int get maxMemoryUsageMB => AppConstants.MAX_MEMORY_USAGE_MB;
  Duration get maxAppStartupTime => AppConstants.MAX_APP_STARTUP_TIME;
  Duration get maxPageNavigationTime => AppConstants.MAX_PAGE_NAVIGATION_TIME;
  
  // Database Configuration
  String get databaseName => AppConstants.DATABASE_NAME;
  int get databaseVersion => AppConstants.DATABASE_VERSION;
  
  // Validation Methods
  bool get isConfigurationValid {
    if (!enableCloudSync) return true; // Cloud sync is optional
    return supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty &&
           _isValidUrl(supabaseUrl);
  }
  
  List<String> get missingConfiguration {
    final missing = <String>[];
    
    if (enableCloudSync) {
      if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
      if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
      if (supabaseUrl.isNotEmpty && !_isValidUrl(supabaseUrl)) {
        missing.add('Valid SUPABASE_URL format');
      }
    }
    
    return missing;
  }
  
  // Private helper methods
  String _getEnvVar(String key, String defaultValue) {
    try {
      return Platform.environment[key] ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
  
  bool _getBoolEnvVar(String key, bool defaultValue) {
    try {
      final value = Platform.environment[key];
      if (value == null) return defaultValue;
      return value.toLowerCase() == 'true';
    } catch (e) {
      return defaultValue;
    }
  }
  
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Development helpers
  Map<String, dynamic> toDebugMap() {
    return {
      'appName': appName,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'debugMode': debugMode,
      'platform': _getPlatformName(),
      'supabaseConfigured': supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
      'configurationValid': isConfigurationValid,
      'enableCloudSync': enableCloudSync,
      'enableOfflineMode': enableOfflineMode,
      'networkTimeout': networkTimeout.inSeconds,
      'maxFileSizeMB': maxFileSizeMB,
    };
  }
  
  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
