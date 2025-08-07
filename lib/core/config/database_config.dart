import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/storage_constants.dart';
import '../errors/exceptions.dart' as app_exceptions;

/// Database configuration and initialization
/// 
/// Handles SQLite database setup, migrations, and connection management.
/// Provides centralized database access with proper error handling.
class DatabaseConfig {
  static DatabaseConfig? _instance;
  static DatabaseConfig get instance => _instance ??= DatabaseConfig._();
  
  Database? _database;
  
  DatabaseConfig._();
  
  /// Get the database instance, initializing if necessary
  Future<Database> get database async {
    _database ??= await _initializeDatabase();
    return _database!;
  }
  
  /// Initialize the database with proper schema
  Future<Database> _initializeDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, StorageConstants.DATABASE_NAME);
      
      return await openDatabase(
        path,
        version: StorageConstants.DATABASE_VERSION,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
        onConfigure: _configureDatabase,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to initialize database: ${e.toString()}');
    }
  }
  
  /// Configure database settings
  Future<void> _configureDatabase(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
    
    // Configure performance settings
    await db.execute('PRAGMA journal_mode = WAL');
    await db.execute('PRAGMA synchronous = NORMAL');
    await db.execute('PRAGMA cache_size = 10000');
    await db.execute('PRAGMA temp_store = MEMORY');
  }
  
  /// Create database schema
  Future<void> _createDatabase(Database db, int version) async {
    final batch = db.batch();
    
    // Books table
    batch.execute('''
      CREATE TABLE ${StorageConstants.TABLE_BOOKS} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subtitle TEXT,
        description TEXT,
        language TEXT,
        isbn TEXT,
        publication_date TEXT,
        page_count INTEGER,
        file_path TEXT,
        file_size INTEGER,
        format TEXT NOT NULL,
        cover_url TEXT,
        cover_path TEXT,
        download_url TEXT,
        source TEXT NOT NULL,
        source_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        downloaded_at INTEGER,
        last_opened_at INTEGER
      )
    ''');
    
    // Authors table
    batch.execute('''
      CREATE TABLE ${StorageConstants.TABLE_AUTHORS} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        bio TEXT,
        birth_date TEXT,
        death_date TEXT,
        nationality TEXT,
        image_url TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    // Book-Author relationship table
    batch.execute('''
      CREATE TABLE book_authors (
        book_id TEXT NOT NULL,
        author_id TEXT NOT NULL,
        role TEXT DEFAULT 'author',
        PRIMARY KEY (book_id, author_id),
        FOREIGN KEY (book_id) REFERENCES ${StorageConstants.TABLE_BOOKS}(id) ON DELETE CASCADE,
        FOREIGN KEY (author_id) REFERENCES ${StorageConstants.TABLE_AUTHORS}(id) ON DELETE CASCADE
      )
    ''');
    
    // Categories table
    batch.execute('''
      CREATE TABLE ${StorageConstants.TABLE_CATEGORIES} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        parent_id TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES ${StorageConstants.TABLE_CATEGORIES}(id)
      )
    ''');
    
    // Book-Category relationship table
    batch.execute('''
      CREATE TABLE book_categories (
        book_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        PRIMARY KEY (book_id, category_id),
        FOREIGN KEY (book_id) REFERENCES ${StorageConstants.TABLE_BOOKS}(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES ${StorageConstants.TABLE_CATEGORIES}(id) ON DELETE CASCADE
      )
    ''');
    
    // Reading progress table
    batch.execute('''
      CREATE TABLE ${StorageConstants.TABLE_READING_PROGRESS} (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        user_id TEXT,
        current_page INTEGER DEFAULT 0,
        total_pages INTEGER DEFAULT 0,
        progress_percentage REAL DEFAULT 0.0,
        reading_time_minutes INTEGER DEFAULT 0,
        last_position TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES ${StorageConstants.TABLE_BOOKS}(id) ON DELETE CASCADE
      )
    ''');
    
    // Bookmarks table
    batch.execute('''
      CREATE TABLE ${StorageConstants.TABLE_BOOKMARKS} (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        user_id TEXT,
        page_number INTEGER NOT NULL,
        position TEXT,
        title TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES ${StorageConstants.TABLE_BOOKS}(id) ON DELETE CASCADE
      )
    ''');
    
    // Notes table
    batch.execute('''
      CREATE TABLE ${StorageConstants.TABLE_NOTES} (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        user_id TEXT,
        page_number INTEGER,
        position_start TEXT,
        position_end TEXT,
        selected_text TEXT,
        note_text TEXT NOT NULL,
        highlight_color TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES ${StorageConstants.TABLE_BOOKS}(id) ON DELETE CASCADE
      )
    ''');
    
    // Collections table
    batch.execute('''
      CREATE TABLE ${StorageConstants.TABLE_COLLECTIONS} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        user_id TEXT,
        is_public BOOLEAN DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    // Collection-Book relationship table
    batch.execute('''
      CREATE TABLE collection_books (
        collection_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (collection_id, book_id),
        FOREIGN KEY (collection_id) REFERENCES ${StorageConstants.TABLE_COLLECTIONS}(id) ON DELETE CASCADE,
        FOREIGN KEY (book_id) REFERENCES ${StorageConstants.TABLE_BOOKS}(id) ON DELETE CASCADE
      )
    ''');
    
    // Downloads table
    batch.execute('''
      CREATE TABLE ${StorageConstants.TABLE_DOWNLOADS} (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        download_url TEXT NOT NULL,
        file_path TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        progress REAL DEFAULT 0.0,
        total_bytes INTEGER,
        downloaded_bytes INTEGER DEFAULT 0,
        error_message TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        completed_at INTEGER,
        FOREIGN KEY (book_id) REFERENCES ${StorageConstants.TABLE_BOOKS}(id) ON DELETE CASCADE
      )
    ''');
    
    // Search history table
    batch.execute('''
      CREATE TABLE ${StorageConstants.TABLE_SEARCH_HISTORY} (
        id TEXT PRIMARY KEY,
        query TEXT NOT NULL,
        filters TEXT,
        results_count INTEGER DEFAULT 0,
        user_id TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    
    // Create indexes for better performance
    _createIndexes(batch);
    
    await batch.commit();
  }
  
  /// Create database indexes
  void _createIndexes(Batch batch) {
    // Books indexes
    batch.execute('CREATE INDEX idx_books_title ON ${StorageConstants.TABLE_BOOKS}(title)');
    batch.execute('CREATE INDEX idx_books_format ON ${StorageConstants.TABLE_BOOKS}(format)');
    batch.execute('CREATE INDEX idx_books_source ON ${StorageConstants.TABLE_BOOKS}(source)');
    batch.execute('CREATE INDEX idx_books_created_at ON ${StorageConstants.TABLE_BOOKS}(created_at)');
    batch.execute('CREATE INDEX idx_books_last_opened ON ${StorageConstants.TABLE_BOOKS}(last_opened_at)');
    
    // Authors indexes
    batch.execute('CREATE INDEX idx_authors_name ON ${StorageConstants.TABLE_AUTHORS}(name)');
    
    // Reading progress indexes
    batch.execute('CREATE INDEX idx_reading_progress_book ON ${StorageConstants.TABLE_READING_PROGRESS}(book_id)');
    batch.execute('CREATE INDEX idx_reading_progress_user ON ${StorageConstants.TABLE_READING_PROGRESS}(user_id)');
    
    // Bookmarks indexes
    batch.execute('CREATE INDEX idx_bookmarks_book ON ${StorageConstants.TABLE_BOOKMARKS}(book_id)');
    batch.execute('CREATE INDEX idx_bookmarks_user ON ${StorageConstants.TABLE_BOOKMARKS}(user_id)');
    
    // Notes indexes
    batch.execute('CREATE INDEX idx_notes_book ON ${StorageConstants.TABLE_NOTES}(book_id)');
    batch.execute('CREATE INDEX idx_notes_user ON ${StorageConstants.TABLE_NOTES}(user_id)');
    
    // Downloads indexes
    batch.execute('CREATE INDEX idx_downloads_status ON ${StorageConstants.TABLE_DOWNLOADS}(status)');
    batch.execute('CREATE INDEX idx_downloads_book ON ${StorageConstants.TABLE_DOWNLOADS}(book_id)');
    
    // Full-text search index for books
    batch.execute('''
      CREATE VIRTUAL TABLE books_fts USING fts5(
        title, subtitle, description, 
        content=${StorageConstants.TABLE_BOOKS},
        content_rowid=rowid
      )
    ''');
  }
  
  /// Handle database upgrades
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle version upgrades here
    // For now, we only have version 1, so no upgrades needed
    if (oldVersion < newVersion) {
      // Future migrations will be implemented here
    }
  }
  
  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
  
  /// Delete the database file (for testing or reset)
  Future<void> deleteDatabase() async {
    try {
      await close();
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, StorageConstants.DATABASE_NAME);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete database: ${e.toString()}');
    }
  }
  
  /// Get database file size in bytes
  Future<int> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, StorageConstants.DATABASE_NAME);
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
