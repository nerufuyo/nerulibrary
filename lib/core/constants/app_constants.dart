/// Application-wide constants for LiteraLib
///
/// Contains all constant values used throughout the application
/// including version info, timeouts, limits, and configuration values.
class AppConstants {
  // App Information
  static const String appName = 'LiteraLib';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Environment
  static const String envSupabaseUrl = 'SUPABASE_URL';
  static const String envSupabaseAnonKey = 'SUPABASE_ANON_KEY';
  static const String envApiBaseUrl = 'API_BASE_URL';
  static const String envDebugMode = 'DEBUG_MODE';

  // Network Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // File Limits
  static const int maxFileSizeMb = 100;
  static const int maxDownloadQueueSize = 5;
  static const int maxConcurrentDownloads = 3;

  // Cache Settings
  static const Duration cacheDurationMetadata = Duration(hours: 24);
  static const Duration cacheDurationSearch = Duration(hours: 1);
  static const Duration cacheDurationAuthor = Duration(days: 7);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Reading Settings
  static const int defaultFontSize = 16;
  static const int minFontSize = 8;
  static const int maxFontSize = 32;
  static const int fontSizeLevels = 8;

  // Performance
  static const int maxMemoryUsageMb = 100;
  static const Duration maxAppStartupTime = Duration(seconds: 3);
  static const Duration maxPageNavigationTime = Duration(milliseconds: 500);

  // Database
  static const String databaseName = 'literalib.db';
  static const int databaseVersion = 1;

  // Security
  static const String secureStoragePrefix = 'literalib_';

  // Private constructor to prevent instantiation
  AppConstants._();
}
