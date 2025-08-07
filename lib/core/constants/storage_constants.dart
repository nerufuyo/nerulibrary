/// Storage-related constants and paths
/// 
/// Contains constants for local storage, file paths, database tables,
/// and secure storage keys used throughout the application.
class StorageConstants {
  // Secure Storage Keys
  static const String SECURE_KEY_USER_TOKEN = 'literalib_user_token';
  static const String SECURE_KEY_REFRESH_TOKEN = 'literalib_refresh_token';
  static const String SECURE_KEY_USER_ID = 'literalib_user_id';
  static const String SECURE_KEY_API_KEYS = 'literalib_api_keys';
  
  // Local Storage Keys
  static const String PREF_THEME_MODE = 'theme_mode';
  static const String PREF_READING_THEME = 'reading_theme';
  static const String PREF_FONT_FAMILY = 'font_family';
  static const String PREF_FONT_SIZE = 'font_size';
  static const String PREF_LAST_SYNC = 'last_sync';
  static const String PREF_OFFLINE_MODE = 'offline_mode';
  static const String PREF_AUTO_SYNC = 'auto_sync';
  
  // Database Tables
  static const String TABLE_BOOKS = 'books';
  static const String TABLE_AUTHORS = 'authors';
  static const String TABLE_CATEGORIES = 'categories';
  static const String TABLE_READING_PROGRESS = 'reading_progress';
  static const String TABLE_BOOKMARKS = 'bookmarks';
  static const String TABLE_NOTES = 'notes';
  static const String TABLE_COLLECTIONS = 'collections';
  static const String TABLE_DOWNLOADS = 'downloads';
  static const String TABLE_SEARCH_HISTORY = 'search_history';
  
  // Database Configuration
  static const String DATABASE_NAME = 'literalib.db';
  static const int DATABASE_VERSION = 1;
  
  // Security
  static const String SECURE_STORAGE_PREFIX = 'literalib_';
  
  // File Directories
  static const String DIR_BOOKS = 'books';
  static const String DIR_COVERS = 'covers';
  static const String DIR_TEMP = 'temp';
  static const String DIR_CACHE = 'cache';
  static const String DIR_LOGS = 'logs';
  
  // File Extensions
  static const String EXT_EPUB = '.epub';
  static const String EXT_PDF = '.pdf';
  static const String EXT_TXT = '.txt';
  static const String EXT_JSON = '.json';
  static const String EXT_DB = '.db';
  
  // File Naming Patterns
  static const String PATTERN_BOOK_FILE = '{book_id}_{format}';
  static const String PATTERN_COVER_FILE = 'cover_{book_id}.jpg';
  static const String PATTERN_TEMP_FILE = 'temp_{timestamp}_{filename}';
  
  // Cache Keys
  static const String CACHE_BOOK_METADATA = 'book_metadata_';
  static const String CACHE_SEARCH_RESULTS = 'search_results_';
  static const String CACHE_AUTHOR_INFO = 'author_info_';
  static const String CACHE_API_RESPONSE = 'api_response_';
  
  // Backup and Sync
  static const String BACKUP_FILE_PREFIX = 'literalib_backup_';
  static const String SYNC_STATUS_PENDING = 'pending';
  static const String SYNC_STATUS_SYNCING = 'syncing';
  static const String SYNC_STATUS_COMPLETED = 'completed';
  static const String SYNC_STATUS_FAILED = 'failed';
  
  // File Size Limits (in bytes)
  static const int MAX_BOOK_FILE_SIZE = 100 * 1024 * 1024; // 100 MB
  static const int MAX_COVER_FILE_SIZE = 5 * 1024 * 1024; // 5 MB
  static const int MAX_CACHE_SIZE = 500 * 1024 * 1024; // 500 MB
  
  // Cleanup Settings
  static const Duration TEMP_FILE_RETENTION = Duration(days: 1);
  static const Duration LOG_FILE_RETENTION = Duration(days: 30);
  static const Duration CACHE_FILE_RETENTION = Duration(days: 7);
  
  // Private constructor to prevent instantiation
  StorageConstants._();
}
