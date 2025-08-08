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
  String get supabaseUrl => _getEnvVar(AppConstants.envSupabaseUrl, '');
  String get supabaseAnonKey => _getEnvVar(AppConstants.envSupabaseAnonKey, '');
  String get apiBaseUrl => _getEnvVar(AppConstants.envApiBaseUrl, 'https://api.example.com');
  bool get debugMode => _getBoolEnvVar(AppConstants.envDebugMode, kDebugMode);
  
  // App Information
  String get appName => AppConstants.appName;
  String get appVersion => AppConstants.appVersion;
  String get buildNumber => AppConstants.appBuildNumber;
  
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
  Duration get networkTimeout => AppConstants.networkTimeout;
  Duration get connectionTimeout => AppConstants.connectionTimeout;
  Duration get receiveTimeout => AppConstants.receiveTimeout;
  
  // File and Storage Configuration
  int get maxFileSizeMB => AppConstants.maxFileSizeMb;
  int get maxDownloadQueueSize => AppConstants.maxDownloadQueueSize;
  int get maxConcurrentDownloads => AppConstants.maxConcurrentDownloads;
  
  // Cache Configuration
  Duration get cacheMetadataDuration => AppConstants.cacheDurationMetadata;
  Duration get cacheSearchDuration => AppConstants.cacheDurationSearch;
  Duration get cacheAuthorDuration => AppConstants.cacheDurationAuthor;
  
  // Performance Configuration
  int get maxMemoryUsageMB => AppConstants.maxMemoryUsageMb;
  Duration get maxAppStartupTime => AppConstants.maxAppStartupTime;
  Duration get maxPageNavigationTime => AppConstants.maxPageNavigationTime;
  
  // Database Configuration
  String get databaseName => AppConstants.databaseName;
  int get databaseVersion => AppConstants.databaseVersion;
  
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
