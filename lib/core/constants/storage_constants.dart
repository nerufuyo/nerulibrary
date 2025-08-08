/// Storage-related constants and paths
/// 
/// Contains constants for local storage, file paths, database tables,
/// and secure storage keys used throughout the application.
class StorageConstants {
  // Secure Storage Keys
  static const String secureKeyUserToken = 'literalib_user_token';
  static const String secureKeyRefreshToken = 'literalib_refresh_token';
  static const String secureKeyUserId = 'literalib_user_id';
  static const String secureKeyApiKeys = 'literalib_api_keys';
  
  // Local Storage Keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefReadingTheme = 'reading_theme';
  static const String prefFontFamily = 'font_family';
  static const String prefFontSize = 'font_size';
  static const String prefLastSync = 'last_sync';
  static const String prefOfflineMode = 'offline_mode';
  static const String prefAutoSync = 'auto_sync';
  
  // Database Tables
  static const String tableBooks = 'books';
  static const String tableAuthors = 'authors';
  static const String tableCategories = 'categories';
  static const String tableReadingProgress = 'reading_progress';
  static const String tableBookmarks = 'bookmarks';
  static const String tableNotes = 'notes';
  static const String tableCollections = 'collections';
  static const String tableDownloads = 'downloads';
  static const String tableSearchHistory = 'search_history';
  
  // Database Configuration
  static const String databaseName = 'literalib.db';
  static const int databaseVersion = 1;
  
  // Security
  static const String secureStoragePrefix = 'literalib_';
  
  // File Directories
  static const String dirBooks = 'books';
  static const String dirCovers = 'covers';
  static const String dirTemp = 'temp';
  static const String dirCache = 'cache';
  static const String dirLogs = 'logs';
  
  // File Extensions
  static const String extEpub = '.epub';
  static const String extPdf = '.pdf';
  static const String extTxt = '.txt';
  static const String extJson = '.json';
  static const String extDb = '.db';
  
  // File Naming Patterns
  static const String patternBookFile = '{book_id}_{format}';
  static const String patternCoverFile = 'cover_{book_id}.jpg';
  static const String patternTempFile = 'temp_{timestamp}_{filename}';
  
  // Cache Keys
  static const String cacheBookMetadata = 'book_metadata_';
  static const String cacheSearchResults = 'search_results_';
  static const String cacheAuthorInfo = 'author_info_';
  static const String cacheApiResponse = 'api_response_';
  
  // Backup and Sync
  static const String backupFilePrefix = 'literalib_backup_';
  static const String syncStatusPending = 'pending';
  static const String syncStatusSyncing = 'syncing';
  static const String syncStatusCompleted = 'completed';
  static const String syncStatusFailed = 'failed';
  
  // File Size Limits (in bytes)
  static const int maxBookFileSize = 100 * 1024 * 1024; // 100 MB
  static const int maxCoverFileSize = 5 * 1024 * 1024; // 5 MB
  static const int maxCacheSize = 500 * 1024 * 1024; // 500 MB
  
  // Cleanup Settings
  static const Duration tempFileRetention = Duration(days: 1);
  static const Duration logFileRetention = Duration(days: 30);
  static const Duration cacheFileRetention = Duration(days: 7);
  
  // Private constructor to prevent instantiation
  StorageConstants._();
}
