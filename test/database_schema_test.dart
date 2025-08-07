import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nerulibrary/core/config/database_config.dart';
import 'package:nerulibrary/features/library/data/datasources/book_local_datasource_impl.dart';
import 'package:nerulibrary/features/library/data/models/book_model.dart';
import 'package:nerulibrary/features/library/data/models/author_model.dart';

void main() {
  group('Database Schema Implementation Tests', () {
    late BookLocalDataSourceImpl dataSource;
    late DatabaseConfig databaseConfig;

    setUpAll(() {
      // Initialize Flutter bindings for testing
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Initialize FFI for testing
      sqfliteFfiInit();
      
      // Use in-memory database for testing
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create a fresh database instance for each test
      databaseConfig = DatabaseConfig.instance;
      dataSource = BookLocalDataSourceImpl(databaseConfig: databaseConfig);
      
      // Clean up any existing database
      await databaseConfig.deleteDatabase();
    });

    tearDown(() async {
      await databaseConfig.close();
    });

    test('should create database with correct schema', () async {
      // Act
      final db = await databaseConfig.database;
      
      // Assert - Check that all tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      
      final tableNames = tables.map((table) => table['name']).toSet();
      
      expect(tableNames, contains('books'));
      expect(tableNames, contains('authors'));
      expect(tableNames, contains('book_authors'));
      expect(tableNames, contains('categories'));
      expect(tableNames, contains('book_categories'));
      expect(tableNames, contains('reading_progress'));
      expect(tableNames, contains('bookmarks'));
      expect(tableNames, contains('notes'));
      expect(tableNames, contains('collections'));
      expect(tableNames, contains('collection_books'));
      expect(tableNames, contains('downloads'));
      expect(tableNames, contains('search_history'));
    });

    test('should create database indexes', () async {
      // Act
      final db = await databaseConfig.database;
      
      // Assert - Check that indexes exist
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index'",
      );
      
      final indexNames = indexes.map((index) => index['name']).toSet();
      
      expect(indexNames, contains('idx_books_title'));
      expect(indexNames, contains('idx_books_format'));
      expect(indexNames, contains('idx_books_source'));
    });

    test('should insert and retrieve a book', () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookModel = BookModel(
        id: 'test-book-1',
        title: 'Test Book',
        format: 'epub',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await dataSource.insertBook(bookModel);
      final retrievedBook = await dataSource.getBookById('test-book-1');

      // Assert
      expect(retrievedBook.id, equals('test-book-1'));
      expect(retrievedBook.title, equals('Test Book'));
      expect(retrievedBook.format, equals('epub'));
      expect(retrievedBook.source, equals('manual'));
    });

    test('should insert and retrieve an author', () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      final authorModel = AuthorModel(
        id: 'test-author-1',
        name: 'Test Author',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await dataSource.insertAuthor(authorModel);
      final retrievedAuthor = await dataSource.getAuthorById('test-author-1');

      // Assert
      expect(retrievedAuthor.id, equals('test-author-1'));
      expect(retrievedAuthor.name, equals('Test Author'));
    });

    test('should create book-author relationship', () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final bookModel = BookModel(
        id: 'test-book-1',
        title: 'Test Book',
        format: 'epub',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );
      
      final authorModel = AuthorModel(
        id: 'test-author-1',
        name: 'Test Author',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await dataSource.insertBook(bookModel);
      await dataSource.insertAuthor(authorModel);
      await dataSource.addBookAuthor('test-book-1', 'test-author-1');
      
      final bookAuthors = await dataSource.getBookAuthors('test-book-1');

      // Assert
      expect(bookAuthors, hasLength(1));
      expect(bookAuthors.first.id, equals('test-author-1'));
      expect(bookAuthors.first.name, equals('Test Author'));
    });

    test('should search books by title', () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final book1 = BookModel(
        id: 'book-1',
        title: 'Flutter Development Guide',
        format: 'epub',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );
      
      final book2 = BookModel(
        id: 'book-2',
        title: 'Android Programming',
        format: 'pdf',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await dataSource.insertBook(book1);
      await dataSource.insertBook(book2);
      
      final searchResults = await dataSource.searchBooks(query: 'Flutter');

      // Assert
      expect(searchResults, hasLength(1));
      expect(searchResults.first.title, equals('Flutter Development Guide'));
    });

    test('should get books count', () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final book1 = BookModel(
        id: 'book-1',
        title: 'Book 1',
        format: 'epub',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );
      
      final book2 = BookModel(
        id: 'book-2',
        title: 'Book 2',
        format: 'pdf',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await dataSource.insertBook(book1);
      await dataSource.insertBook(book2);
      
      final count = await dataSource.getBooksCount();

      // Assert
      expect(count, equals(2));
    });

    test('should update book file path', () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookModel = BookModel(
        id: 'test-book-1',
        title: 'Test Book',
        format: 'epub',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await dataSource.insertBook(bookModel);
      final updatedBook = await dataSource.updateBookFilePath(
        'test-book-1',
        '/path/to/book.epub',
      );

      // Assert
      expect(updatedBook.filePath, equals('/path/to/book.epub'));
      expect(updatedBook.downloadedAt, isNotNull);
    });

    test('should delete book', () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookModel = BookModel(
        id: 'test-book-1',
        title: 'Test Book',
        format: 'epub',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await dataSource.insertBook(bookModel);
      await dataSource.deleteBook('test-book-1');

      // Assert
      expect(
        () => dataSource.getBookById('test-book-1'),
        throwsA(isA<Exception>()),
      );
    });

    test('should get books by format', () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final epubBook = BookModel(
        id: 'epub-book',
        title: 'EPUB Book',
        format: 'epub',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );
      
      final pdfBook = BookModel(
        id: 'pdf-book',
        title: 'PDF Book',
        format: 'pdf',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await dataSource.insertBook(epubBook);
      await dataSource.insertBook(pdfBook);
      
      final epubBooks = await dataSource.getBooksByFormat('epub');

      // Assert
      expect(epubBooks, hasLength(1));
      expect(epubBooks.first.format, equals('epub'));
    });

    test('should get total storage used', () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookModel = BookModel(
        id: 'test-book-1',
        title: 'Test Book',
        format: 'epub',
        source: 'manual',
        fileSize: 1024 * 1024, // 1 MB
        filePath: '/path/to/book.epub',
        createdAt: now,
        updatedAt: now,
        downloadedAt: now,
      );

      // Act
      await dataSource.insertBook(bookModel);
      final totalStorage = await dataSource.getTotalStorageUsed();

      // Assert
      expect(totalStorage, equals(1024 * 1024));
    });
  });
}
