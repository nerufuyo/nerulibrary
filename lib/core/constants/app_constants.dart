/// Application-wide constants for LiteraLib
/// 
/// Contains all constant values used throughout the application
/// including version info, timeouts, limits, and configuration values.
class AppConstants {
  // App Information
  static const String APP_NAME = 'LiteraLib';
  static const String APP_VERSION = '1.0.0';
  static const String APP_BUILD_NUMBER = '1';
  
  // Environment
  static const String ENV_SUPABASE_URL = 'SUPABASE_URL';
  static const String ENV_SUPABASE_ANON_KEY = 'SUPABASE_ANON_KEY';
  static const String ENV_API_BASE_URL = 'API_BASE_URL';
  static const String ENV_DEBUG_MODE = 'DEBUG_MODE';
  
  // Network Timeouts
  static const Duration NETWORK_TIMEOUT = Duration(seconds: 30);
  static const Duration CONNECTION_TIMEOUT = Duration(seconds: 15);
  static const Duration RECEIVE_TIMEOUT = Duration(seconds: 30);
  
  // File Limits
  static const int MAX_FILE_SIZE_MB = 100;
  static const int MAX_DOWNLOAD_QUEUE_SIZE = 5;
  static const int MAX_CONCURRENT_DOWNLOADS = 3;
  
  // Cache Settings
  static const Duration CACHE_DURATION_METADATA = Duration(hours: 24);
  static const Duration CACHE_DURATION_SEARCH = Duration(hours: 1);
  static const Duration CACHE_DURATION_AUTHOR = Duration(days: 7);
  
  // Pagination
  static const int DEFAULT_PAGE_SIZE = 20;
  static const int MAX_PAGE_SIZE = 100;
  
  // Reading Settings
  static const int DEFAULT_FONT_SIZE = 16;
  static const int MIN_FONT_SIZE = 8;
  static const int MAX_FONT_SIZE = 32;
  static const int FONT_SIZE_LEVELS = 8;
  
  // Performance
  static const int MAX_MEMORY_USAGE_MB = 100;
  static const Duration MAX_APP_STARTUP_TIME = Duration(seconds: 3);
  static const Duration MAX_PAGE_NAVIGATION_TIME = Duration(milliseconds: 500);
  
  // Database
  static const String DATABASE_NAME = 'literalib.db';
  static const int DATABASE_VERSION = 1;
  
  // Security
  static const String SECURE_STORAGE_PREFIX = 'literalib_';
  
  // Private constructor to prevent instantiation
  AppConstants._();
}
