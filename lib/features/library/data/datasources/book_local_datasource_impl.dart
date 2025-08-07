import 'package:sqflite/sqflite.dart';

import '../../../../core/config/database_config.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/errors/exceptions.dart' as app_exceptions;
import '../models/book_model.dart';
import '../models/author_model.dart';
import '../models/category_model.dart';
import '../../domain/entities/collection.dart';
import 'book_local_datasource.dart';

/// Implementation of BookLocalDataSource using SQLite
/// 
/// Provides concrete implementation of all database operations
/// for books, authors, categories, and their relationships.
class BookLocalDataSourceImpl implements BookLocalDataSource {
  final DatabaseConfig _databaseConfig;
  
  const BookLocalDataSourceImpl({
    required DatabaseConfig databaseConfig,
  }) : _databaseConfig = databaseConfig;

  // Book operations
  
  @override
  Future<BookModel> getBookById(String id) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.TABLE_BOOKS,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        throw app_exceptions.NotFoundException('Book not found with ID: $id');
      }
      
      return BookModel.fromMap(maps.first);
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to get book: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getBooks({
    int? limit,
    int? offset,
    String? search,
    String? format,
    String? source,
    String? authorId,
    String? categoryId,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final db = await _databaseConfig.database;
      
      String query = 'SELECT DISTINCT b.* FROM ${StorageConstants.TABLE_BOOKS} b';
      List<String> whereConditions = [];
      List<Object> whereArgs = [];
      
      // Add joins if needed
      if (authorId != null) {
        query += ' INNER JOIN book_authors ba ON b.id = ba.book_id';
        whereConditions.add('ba.author_id = ?');
        whereArgs.add(authorId);
      }
      
      if (categoryId != null) {
        query += ' INNER JOIN book_categories bc ON b.id = bc.book_id';
        whereConditions.add('bc.category_id = ?');
        whereArgs.add(categoryId);
      }
      
      // Add where conditions
      if (search != null && search.isNotEmpty) {
        whereConditions.add('(b.title LIKE ? OR b.description LIKE ?)');
        whereArgs.addAll(['%$search%', '%$search%']);
      }
      
      if (format != null) {
        whereConditions.add('b.format = ?');
        whereArgs.add(format);
      }
      
      if (source != null) {
        whereConditions.add('b.source = ?');
        whereArgs.add(source);
      }
      
      // Build final query
      if (whereConditions.isNotEmpty) {
        query += ' WHERE ${whereConditions.join(' AND ')}';
      }
      
      // Add ordering
      final validSortBy = sortBy ?? 'title';
      final validSortOrder = sortOrder ?? 'ASC';
      query += ' ORDER BY b.$validSortBy $validSortOrder';
      
      // Add pagination
      if (limit != null) {
        query += ' LIMIT $limit';
        if (offset != null) {
          query += ' OFFSET $offset';
        }
      }
      
      final maps = await db.rawQuery(query, whereArgs);
      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get books: ${e.toString()}');
    }
  }

  @override
  Future<int> getBooksCount({
    String? search,
    String? format,
    String? source,
    String? authorId,
    String? categoryId,
  }) async {
    try {
      final db = await _databaseConfig.database;
      
      String query = 'SELECT COUNT(DISTINCT b.id) as count FROM ${StorageConstants.TABLE_BOOKS} b';
      List<String> whereConditions = [];
      List<Object> whereArgs = [];
      
      // Add joins if needed
      if (authorId != null) {
        query += ' INNER JOIN book_authors ba ON b.id = ba.book_id';
        whereConditions.add('ba.author_id = ?');
        whereArgs.add(authorId);
      }
      
      if (categoryId != null) {
        query += ' INNER JOIN book_categories bc ON b.id = bc.book_id';
        whereConditions.add('bc.category_id = ?');
        whereArgs.add(categoryId);
      }
      
      // Add where conditions
      if (search != null && search.isNotEmpty) {
        whereConditions.add('(b.title LIKE ? OR b.description LIKE ?)');
        whereArgs.addAll(['%$search%', '%$search%']);
      }
      
      if (format != null) {
        whereConditions.add('b.format = ?');
        whereArgs.add(format);
      }
      
      if (source != null) {
        whereConditions.add('b.source = ?');
        whereArgs.add(source);
      }
      
      // Build final query
      if (whereConditions.isNotEmpty) {
        query += ' WHERE ${whereConditions.join(' AND ')}';
      }
      
      final result = await db.rawQuery(query, whereArgs);
      return result.first['count'] as int;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get books count: ${e.toString()}');
    }
  }

  @override
  Future<BookModel> insertBook(BookModel book) async {
    try {
      final db = await _databaseConfig.database;
      await db.insert(
        StorageConstants.TABLE_BOOKS,
        book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return book;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to insert book: ${e.toString()}');
    }
  }

  @override
  Future<BookModel> updateBook(BookModel book) async {
    try {
      final db = await _databaseConfig.database;
      final updatedBook = book.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      
      final count = await db.update(
        StorageConstants.TABLE_BOOKS,
        updatedBook.toMap(),
        where: 'id = ?',
        whereArgs: [book.id],
      );
      
      if (count == 0) {
        throw app_exceptions.NotFoundException('Book not found for update: ${book.id}');
      }
      
      return updatedBook;
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to update book: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteBook(String id) async {
    try {
      final db = await _databaseConfig.database;
      final count = await db.delete(
        StorageConstants.TABLE_BOOKS,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw app_exceptions.NotFoundException('Book not found for deletion: $id');
      }
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to delete book: ${e.toString()}');
    }
  }

  @override
  Future<int> deleteBooks(List<String> ids) async {
    try {
      final db = await _databaseConfig.database;
      final placeholders = List.filled(ids.length, '?').join(',');
      final count = await db.rawDelete(
        'DELETE FROM ${StorageConstants.TABLE_BOOKS} WHERE id IN ($placeholders)',
        ids,
      );
      return count;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete books: ${e.toString()}');
    }
  }

  // Search operations
  
  @override
  Future<List<BookModel>> searchBooks({
    required String query,
    int? limit,
    int? offset,
    List<String>? formats,
    List<String>? sources,
  }) async {
    try {
      final db = await _databaseConfig.database;
      
      String sqlQuery = '''
        SELECT b.* FROM ${StorageConstants.TABLE_BOOKS} b
        WHERE b.title LIKE ? OR b.description LIKE ? OR b.subtitle LIKE ?
      ''';
      
      List<Object> args = ['%$query%', '%$query%', '%$query%'];
      
      // Add format filter
      if (formats != null && formats.isNotEmpty) {
        final formatPlaceholders = List.filled(formats.length, '?').join(',');
        sqlQuery += ' AND b.format IN ($formatPlaceholders)';
        args.addAll(formats);
      }
      
      // Add source filter
      if (sources != null && sources.isNotEmpty) {
        final sourcePlaceholders = List.filled(sources.length, '?').join(',');
        sqlQuery += ' AND b.source IN ($sourcePlaceholders)';
        args.addAll(sources);
      }
      
      sqlQuery += ' ORDER BY b.title ASC';
      
      // Add pagination
      if (limit != null) {
        sqlQuery += ' LIMIT $limit';
        if (offset != null) {
          sqlQuery += ' OFFSET $offset';
        }
      }
      
      final maps = await db.rawQuery(sqlQuery, args);
      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to search books: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getRecentBooks({int limit = 10}) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.TABLE_BOOKS,
        where: 'last_opened_at IS NOT NULL',
        orderBy: 'last_opened_at DESC',
        limit: limit,
      );
      
      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get recent books: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getDownloadedBooks({int? limit, int? offset}) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.TABLE_BOOKS,
        where: 'file_path IS NOT NULL AND downloaded_at IS NOT NULL',
        orderBy: 'downloaded_at DESC',
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get downloaded books: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getBooksByFormat(String format, {int? limit, int? offset}) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.TABLE_BOOKS,
        where: 'format = ?',
        whereArgs: [format],
        orderBy: 'title ASC',
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get books by format: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getBooksBySource(String source, {int? limit, int? offset}) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.TABLE_BOOKS,
        where: 'source = ?',
        whereArgs: [source],
        orderBy: 'title ASC',
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get books by source: ${e.toString()}');
    }
  }

  // Author operations
  
  @override
  Future<AuthorModel> getAuthorById(String id) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.TABLE_AUTHORS,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        throw app_exceptions.NotFoundException('Author not found with ID: $id');
      }
      
      return AuthorModel.fromMap(maps.first);
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to get author: ${e.toString()}');
    }
  }

  @override
  Future<List<AuthorModel>> getAuthors({int? limit, int? offset, String? search}) async {
    try {
      final db = await _databaseConfig.database;
      
      String where = '';
      List<Object> whereArgs = [];
      
      if (search != null && search.isNotEmpty) {
        where = 'name LIKE ?';
        whereArgs.add('%$search%');
      }
      
      final maps = await db.query(
        StorageConstants.TABLE_AUTHORS,
        where: where.isNotEmpty ? where : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'name ASC',
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => AuthorModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get authors: ${e.toString()}');
    }
  }

  @override
  Future<AuthorModel> insertAuthor(AuthorModel author) async {
    try {
      final db = await _databaseConfig.database;
      await db.insert(
        StorageConstants.TABLE_AUTHORS,
        author.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return author;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to insert author: ${e.toString()}');
    }
  }

  @override
  Future<AuthorModel> updateAuthor(AuthorModel author) async {
    try {
      final db = await _databaseConfig.database;
      final count = await db.update(
        StorageConstants.TABLE_AUTHORS,
        author.toMap(),
        where: 'id = ?',
        whereArgs: [author.id],
      );
      
      if (count == 0) {
        throw app_exceptions.NotFoundException('Author not found for update: ${author.id}');
      }
      
      return author;
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to update author: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAuthor(String id) async {
    try {
      final db = await _databaseConfig.database;
      final count = await db.delete(
        StorageConstants.TABLE_AUTHORS,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw app_exceptions.NotFoundException('Author not found for deletion: $id');
      }
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to delete author: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getBooksByAuthor(String authorId, {int? limit, int? offset}) async {
    try {
      final db = await _databaseConfig.database;
      final sqlQuery = '''
        SELECT b.* FROM ${StorageConstants.TABLE_BOOKS} b
        INNER JOIN book_authors ba ON b.id = ba.book_id
        WHERE ba.author_id = ?
        ORDER BY b.title ASC
      ''';
      
      String finalQuery = sqlQuery;
      List<Object> args = [authorId];
      
      if (limit != null) {
        finalQuery += ' LIMIT $limit';
        if (offset != null) {
          finalQuery += ' OFFSET $offset';
        }
      }
      
      final maps = await db.rawQuery(finalQuery, args);
      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get books by author: ${e.toString()}');
    }
  }

  @override
  Future<List<AuthorModel>> searchAuthors(String query) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.TABLE_AUTHORS,
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'name ASC',
      );
      
      return maps.map((map) => AuthorModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to search authors: ${e.toString()}');
    }
  }

  // Helper methods for relationships
  
  @override
  Future<void> addBookAuthor(String bookId, String authorId, {String role = 'author'}) async {
    try {
      final db = await _databaseConfig.database;
      await db.insert(
        'book_authors',
        {
          'book_id': bookId,
          'author_id': authorId,
          'role': role,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to add book author: ${e.toString()}');
    }
  }

  @override
  Future<void> removeBookAuthor(String bookId, String authorId) async {
    try {
      final db = await _databaseConfig.database;
      await db.delete(
        'book_authors',
        where: 'book_id = ? AND author_id = ?',
        whereArgs: [bookId, authorId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to remove book author: ${e.toString()}');
    }
  }

  @override
  Future<List<AuthorModel>> getBookAuthors(String bookId) async {
    try {
      final db = await _databaseConfig.database;
      final sqlQuery = '''
        SELECT a.* FROM ${StorageConstants.TABLE_AUTHORS} a
        INNER JOIN book_authors ba ON a.id = ba.author_id
        WHERE ba.book_id = ?
        ORDER BY a.name ASC
      ''';
      
      final maps = await db.rawQuery(sqlQuery, [bookId]);
      return maps.map((map) => AuthorModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get book authors: ${e.toString()}');
    }
  }

  // File operations
  
  @override
  Future<BookModel> updateBookFilePath(String bookId, String filePath) async {
    try {
      final db = await _databaseConfig.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final count = await db.update(
        StorageConstants.TABLE_BOOKS,
        {
          'file_path': filePath,
          'downloaded_at': now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [bookId],
      );
      
      if (count == 0) {
        throw app_exceptions.NotFoundException('Book not found for file path update: $bookId');
      }
      
      return await getBookById(bookId);
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to update book file path: ${e.toString()}');
    }
  }

  @override
  Future<void> updateLastOpened(String bookId) async {
    try {
      final db = await _databaseConfig.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.update(
        StorageConstants.TABLE_BOOKS,
        {
          'last_opened_at': now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [bookId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update last opened: ${e.toString()}');
    }
  }

  @override
  Future<int> getTotalStorageUsed() async {
    try {
      final db = await _databaseConfig.database;
      final result = await db.rawQuery(
        'SELECT SUM(file_size) as total FROM ${StorageConstants.TABLE_BOOKS} WHERE file_path IS NOT NULL',
      );
      
      final total = result.first['total'];
      return total != null ? total as int : 0;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get total storage used: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getOrphanedFiles() async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.TABLE_BOOKS,
        columns: ['file_path'],
        where: 'file_path IS NOT NULL',
      );
      
      return maps
          .map((map) => map['file_path'] as String?)
          .where((path) => path != null)
          .cast<String>()
          .toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get orphaned files: ${e.toString()}');
    }
  }

  // Stub implementations for remaining methods (to be completed)
  
  @override
  Future<CategoryModel> getCategoryById(String id) async {
    // TODO: Implement category operations
    throw UnimplementedError('Category operations will be implemented in next iteration');
  }

  @override
  Future<List<CategoryModel>> getCategories({String? parentId, bool includeChildCategories = true}) async {
    throw UnimplementedError('Category operations will be implemented in next iteration');
  }

  @override
  Future<CategoryModel> insertCategory(CategoryModel category) async {
    throw UnimplementedError('Category operations will be implemented in next iteration');
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    throw UnimplementedError('Category operations will be implemented in next iteration');
  }

  @override
  Future<void> deleteCategory(String id) async {
    throw UnimplementedError('Category operations will be implemented in next iteration');
  }

  @override
  Future<List<BookModel>> getBooksByCategory(String categoryId, {int? limit, int? offset, bool includeSubcategories = false}) async {
    throw UnimplementedError('Category operations will be implemented in next iteration');
  }

  @override
  Future<List<CategoryModel>> searchCategories(String query) async {
    throw UnimplementedError('Category operations will be implemented in next iteration');
  }

  @override
  Future<Collection> getCollectionById(String id) async {
    throw UnimplementedError('Collection operations will be implemented in next iteration');
  }

  @override
  Future<List<Collection>> getCollections({int? limit, int? offset, bool publicOnly = false}) async {
    throw UnimplementedError('Collection operations will be implemented in next iteration');
  }

  @override
  Future<Collection> insertCollection(Collection collection) async {
    throw UnimplementedError('Collection operations will be implemented in next iteration');
  }

  @override
  Future<Collection> updateCollection(Collection collection) async {
    throw UnimplementedError('Collection operations will be implemented in next iteration');
  }

  @override
  Future<void> deleteCollection(String id) async {
    throw UnimplementedError('Collection operations will be implemented in next iteration');
  }

  @override
  Future<void> addBookToCollection(String collectionId, String bookId) async {
    throw UnimplementedError('Collection operations will be implemented in next iteration');
  }

  @override
  Future<void> removeBookFromCollection(String collectionId, String bookId) async {
    throw UnimplementedError('Collection operations will be implemented in next iteration');
  }

  @override
  Future<List<BookModel>> getBooksInCollection(String collectionId, {int? limit, int? offset}) async {
    throw UnimplementedError('Collection operations will be implemented in next iteration');
  }

  @override
  Future<void> addBookCategory(String bookId, String categoryId) async {
    throw UnimplementedError('Category operations will be implemented in next iteration');
  }

  @override
  Future<void> removeBookCategory(String bookId, String categoryId) async {
    throw UnimplementedError('Category operations will be implemented in next iteration');
  }

  @override
  Future<List<CategoryModel>> getBookCategories(String bookId) async {
    throw UnimplementedError('Category operations will be implemented in next iteration');
  }
}
