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
        StorageConstants.tableBooks,
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
      throw app_exceptions.DatabaseException(
          'Failed to get book: ${e.toString()}');
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

      String query =
          'SELECT DISTINCT b.* FROM ${StorageConstants.tableBooks} b';
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
      throw app_exceptions.DatabaseException(
          'Failed to get books: ${e.toString()}');
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

      String query =
          'SELECT COUNT(DISTINCT b.id) as count FROM ${StorageConstants.tableBooks} b';
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
      throw app_exceptions.DatabaseException(
          'Failed to get books count: ${e.toString()}');
    }
  }

  @override
  Future<BookModel> insertBook(BookModel book) async {
    try {
      final db = await _databaseConfig.database;
      await db.insert(
        StorageConstants.tableBooks,
        book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return book;
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to insert book: ${e.toString()}');
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
        StorageConstants.tableBooks,
        updatedBook.toMap(),
        where: 'id = ?',
        whereArgs: [book.id],
      );

      if (count == 0) {
        throw app_exceptions.NotFoundException(
            'Book not found for update: ${book.id}');
      }

      return updatedBook;
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to update book: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteBook(String id) async {
    try {
      final db = await _databaseConfig.database;
      final count = await db.delete(
        StorageConstants.tableBooks,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw app_exceptions.NotFoundException(
            'Book not found for deletion: $id');
      }
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to delete book: ${e.toString()}');
    }
  }

  @override
  Future<int> deleteBooks(List<String> ids) async {
    try {
      final db = await _databaseConfig.database;
      final placeholders = List.filled(ids.length, '?').join(',');
      final count = await db.rawDelete(
        'DELETE FROM ${StorageConstants.tableBooks} WHERE id IN ($placeholders)',
        ids,
      );
      return count;
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to delete books: ${e.toString()}');
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
        SELECT b.* FROM ${StorageConstants.tableBooks} b
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
      throw app_exceptions.DatabaseException(
          'Failed to search books: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getRecentBooks({int limit = 10}) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.tableBooks,
        where: 'last_opened_at IS NOT NULL',
        orderBy: 'last_opened_at DESC',
        limit: limit,
      );

      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get recent books: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getDownloadedBooks({int? limit, int? offset}) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.tableBooks,
        where: 'file_path IS NOT NULL AND downloaded_at IS NOT NULL',
        orderBy: 'downloaded_at DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get downloaded books: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getBooksByFormat(String format,
      {int? limit, int? offset}) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.tableBooks,
        where: 'format = ?',
        whereArgs: [format],
        orderBy: 'title ASC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get books by format: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getBooksBySource(String source,
      {int? limit, int? offset}) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.tableBooks,
        where: 'source = ?',
        whereArgs: [source],
        orderBy: 'title ASC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get books by source: ${e.toString()}');
    }
  }

  // Author operations

  @override
  Future<AuthorModel> getAuthorById(String id) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.tableAuthors,
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
      throw app_exceptions.DatabaseException(
          'Failed to get author: ${e.toString()}');
    }
  }

  @override
  Future<List<AuthorModel>> getAuthors(
      {int? limit, int? offset, String? search}) async {
    try {
      final db = await _databaseConfig.database;

      String where = '';
      List<Object> whereArgs = [];

      if (search != null && search.isNotEmpty) {
        where = 'name LIKE ?';
        whereArgs.add('%$search%');
      }

      final maps = await db.query(
        StorageConstants.tableAuthors,
        where: where.isNotEmpty ? where : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'name ASC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => AuthorModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get authors: ${e.toString()}');
    }
  }

  @override
  Future<AuthorModel> insertAuthor(AuthorModel author) async {
    try {
      final db = await _databaseConfig.database;
      await db.insert(
        StorageConstants.tableAuthors,
        author.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return author;
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to insert author: ${e.toString()}');
    }
  }

  @override
  Future<AuthorModel> updateAuthor(AuthorModel author) async {
    try {
      final db = await _databaseConfig.database;
      final count = await db.update(
        StorageConstants.tableAuthors,
        author.toMap(),
        where: 'id = ?',
        whereArgs: [author.id],
      );

      if (count == 0) {
        throw app_exceptions.NotFoundException(
            'Author not found for update: ${author.id}');
      }

      return author;
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to update author: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAuthor(String id) async {
    try {
      final db = await _databaseConfig.database;
      final count = await db.delete(
        StorageConstants.tableAuthors,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw app_exceptions.NotFoundException(
            'Author not found for deletion: $id');
      }
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to delete author: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getBooksByAuthor(String authorId,
      {int? limit, int? offset}) async {
    try {
      final db = await _databaseConfig.database;
      final sqlQuery = '''
        SELECT b.* FROM ${StorageConstants.tableBooks} b
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
      throw app_exceptions.DatabaseException(
          'Failed to get books by author: ${e.toString()}');
    }
  }

  @override
  Future<List<AuthorModel>> searchAuthors(String query) async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.tableAuthors,
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'name ASC',
      );

      return maps.map((map) => AuthorModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to search authors: ${e.toString()}');
    }
  }

  // Helper methods for relationships

  @override
  Future<void> addBookAuthor(String bookId, String authorId,
      {String role = 'author'}) async {
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
      throw app_exceptions.DatabaseException(
          'Failed to add book author: ${e.toString()}');
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
      throw app_exceptions.DatabaseException(
          'Failed to remove book author: ${e.toString()}');
    }
  }

  @override
  Future<List<AuthorModel>> getBookAuthors(String bookId) async {
    try {
      final db = await _databaseConfig.database;
      final sqlQuery = '''
        SELECT a.* FROM ${StorageConstants.tableAuthors} a
        INNER JOIN book_authors ba ON a.id = ba.author_id
        WHERE ba.book_id = ?
        ORDER BY a.name ASC
      ''';

      final maps = await db.rawQuery(sqlQuery, [bookId]);
      return maps.map((map) => AuthorModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get book authors: ${e.toString()}');
    }
  }

  // File operations

  @override
  Future<BookModel> updateBookFilePath(String bookId, String filePath) async {
    try {
      final db = await _databaseConfig.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final count = await db.update(
        StorageConstants.tableBooks,
        {
          'file_path': filePath,
          'downloaded_at': now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [bookId],
      );

      if (count == 0) {
        throw app_exceptions.NotFoundException(
            'Book not found for file path update: $bookId');
      }

      return await getBookById(bookId);
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to update book file path: ${e.toString()}');
    }
  }

  @override
  Future<void> updateLastOpened(String bookId) async {
    try {
      final db = await _databaseConfig.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.update(
        StorageConstants.tableBooks,
        {
          'last_opened_at': now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [bookId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to update last opened: ${e.toString()}');
    }
  }

  @override
  Future<int> getTotalStorageUsed() async {
    try {
      final db = await _databaseConfig.database;
      final result = await db.rawQuery(
        'SELECT SUM(file_size) as total FROM ${StorageConstants.tableBooks} WHERE file_path IS NOT NULL',
      );

      final total = result.first['total'];
      return total != null ? total as int : 0;
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get total storage used: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getOrphanedFiles() async {
    try {
      final db = await _databaseConfig.database;
      final maps = await db.query(
        StorageConstants.tableBooks,
        columns: ['file_path'],
        where: 'file_path IS NOT NULL',
      );

      return maps
          .map((map) => map['file_path'] as String?)
          .where((path) => path != null)
          .cast<String>()
          .toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get orphaned files: ${e.toString()}');
    }
  }

  // Stub implementations for remaining methods (to be completed)

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final db = await DatabaseConfig.instance.database;
      final maps = await db.query(
        StorageConstants.tableCategories,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        throw app_exceptions.NotFoundException(
            'Category not found with id: $id');
      }

      return CategoryModel.fromMap(maps.first);
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to get category: ${e.toString()}');
    }
  }

  @override
  Future<List<CategoryModel>> getCategories(
      {String? parentId, bool includeChildCategories = true}) async {
    try {
      final db = await DatabaseConfig.instance.database;

      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (parentId != null) {
        whereClause = 'parent_id = ?';
        whereArgs = [parentId];
      } else if (!includeChildCategories) {
        whereClause = 'parent_id IS NULL';
      }

      final maps = await db.query(
        StorageConstants.tableCategories,
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'name ASC',
      );

      return maps.map((map) => CategoryModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get categories: ${e.toString()}');
    }
  }

  @override
  Future<CategoryModel> insertCategory(CategoryModel category) async {
    try {
      final db = await DatabaseConfig.instance.database;

      // Check if category with same name already exists
      final existing = await db.query(
        StorageConstants.tableCategories,
        where:
            'name = ? AND parent_id ${category.parentId != null ? '= ?' : 'IS NULL'}',
        whereArgs: category.parentId != null
            ? [category.name, category.parentId]
            : [category.name],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw app_exceptions.DatabaseException(
            'Category with name "${category.name}" already exists');
      }

      await db.insert(StorageConstants.tableCategories, category.toMap());
      return category;
    } catch (e) {
      if (e is app_exceptions.DatabaseException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to insert category: ${e.toString()}');
    }
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      final db = await DatabaseConfig.instance.database;

      final count = await db.update(
        StorageConstants.tableCategories,
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );

      if (count == 0) {
        throw app_exceptions.NotFoundException(
            'Category not found with id: ${category.id}');
      }

      return category;
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to update category: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      final db = await DatabaseConfig.instance.database;

      // Check if category exists
      final existing = await db.query(
        StorageConstants.tableCategories,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (existing.isEmpty) {
        throw app_exceptions.NotFoundException(
            'Category not found with id: $id');
      }

      // Check if category has children
      final children = await db.query(
        StorageConstants.tableCategories,
        where: 'parent_id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (children.isNotEmpty) {
        throw app_exceptions.DatabaseException(
            'Cannot delete category with child categories');
      }

      await db.delete(
        StorageConstants.tableCategories,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (e is app_exceptions.NotFoundException ||
          e is app_exceptions.DatabaseException) {
        rethrow;
      }
      throw app_exceptions.DatabaseException(
          'Failed to delete category: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getBooksByCategory(String categoryId,
      {int? limit, int? offset, bool includeSubcategories = false}) async {
    try {
      final db = await DatabaseConfig.instance.database;

      String query = '''
        SELECT DISTINCT b.* FROM ${StorageConstants.tableBooks} b
        INNER JOIN book_categories bc ON b.id = bc.book_id
        WHERE bc.category_id = ?
      ''';

      List<dynamic> args = [categoryId];

      if (includeSubcategories) {
        // Include subcategories in search
        query = '''
          SELECT DISTINCT b.* FROM ${StorageConstants.tableBooks} b
          INNER JOIN book_categories bc ON b.id = bc.book_id
          INNER JOIN ${StorageConstants.tableCategories} c ON bc.category_id = c.id
          WHERE c.id = ? OR c.parent_id = ?
        ''';
        args = [categoryId, categoryId];
      }

      query += ' ORDER BY b.title ASC';

      if (limit != null) {
        query += ' LIMIT $limit';
        if (offset != null) {
          query += ' OFFSET $offset';
        }
      }

      final maps = await db.rawQuery(query, args);
      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get books by category: ${e.toString()}');
    }
  }

  @override
  Future<List<CategoryModel>> searchCategories(String query) async {
    try {
      final db = await DatabaseConfig.instance.database;

      final maps = await db.query(
        StorageConstants.tableCategories,
        where: 'name LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );

      return maps.map((map) => CategoryModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to search categories: ${e.toString()}');
    }
  }

  @override
  Future<Collection> getCollectionById(String id) async {
    try {
      final db = await DatabaseConfig.instance.database;

      final maps = await db.rawQuery('''
        SELECT c.*, COUNT(cb.book_id) as book_count
        FROM ${StorageConstants.tableCollections} c
        LEFT JOIN collection_books cb ON c.id = cb.collection_id
        WHERE c.id = ?
        GROUP BY c.id
        LIMIT 1
      ''', [id]);

      if (maps.isEmpty) {
        throw app_exceptions.NotFoundException(
            'Collection not found with id: $id');
      }

      final map = maps.first;
      return Collection(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        userId: map['user_id'] as String?,
        isPublic: (map['is_public'] as int) == 1,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        bookCount: map['book_count'] as int,
      );
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to get collection: ${e.toString()}');
    }
  }

  @override
  Future<List<Collection>> getCollections(
      {int? limit, int? offset, bool publicOnly = false}) async {
    try {
      final db = await DatabaseConfig.instance.database;

      String query = '''
        SELECT c.*, COUNT(cb.book_id) as book_count
        FROM ${StorageConstants.tableCollections} c
        LEFT JOIN collection_books cb ON c.id = cb.collection_id
      ''';

      List<dynamic> args = [];

      if (publicOnly) {
        query += ' WHERE c.is_public = 1';
      }

      query += ' GROUP BY c.id ORDER BY c.name ASC';

      if (limit != null) {
        query += ' LIMIT $limit';
        if (offset != null) {
          query += ' OFFSET $offset';
        }
      }

      final maps = await db.rawQuery(query, args);

      return maps
          .map((map) => Collection(
                id: map['id'] as String,
                name: map['name'] as String,
                description: map['description'] as String?,
                userId: map['user_id'] as String?,
                isPublic: (map['is_public'] as int) == 1,
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                    map['created_at'] as int),
                updatedAt: DateTime.fromMillisecondsSinceEpoch(
                    map['updated_at'] as int),
                bookCount: map['book_count'] as int,
              ))
          .toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get collections: ${e.toString()}');
    }
  }

  @override
  Future<Collection> insertCollection(Collection collection) async {
    try {
      final db = await DatabaseConfig.instance.database;

      // Check if collection with same name already exists for the user
      final existing = await db.query(
        StorageConstants.tableCollections,
        where:
            'name = ? AND user_id ${collection.userId != null ? '= ?' : 'IS NULL'}',
        whereArgs: collection.userId != null
            ? [collection.name, collection.userId]
            : [collection.name],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw app_exceptions.DatabaseException(
            'Collection with name "${collection.name}" already exists');
      }

      final collectionMap = {
        'id': collection.id,
        'name': collection.name,
        'description': collection.description,
        'user_id': collection.userId,
        'is_public': collection.isPublic ? 1 : 0,
        'created_at': collection.createdAt.millisecondsSinceEpoch,
        'updated_at': collection.updatedAt.millisecondsSinceEpoch,
      };

      await db.insert(StorageConstants.tableCollections, collectionMap);
      return collection;
    } catch (e) {
      if (e is app_exceptions.DatabaseException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to insert collection: ${e.toString()}');
    }
  }

  @override
  Future<Collection> updateCollection(Collection collection) async {
    try {
      final db = await DatabaseConfig.instance.database;

      final collectionMap = {
        'id': collection.id,
        'name': collection.name,
        'description': collection.description,
        'user_id': collection.userId,
        'is_public': collection.isPublic ? 1 : 0,
        'created_at': collection.createdAt.millisecondsSinceEpoch,
        'updated_at': collection.updatedAt.millisecondsSinceEpoch,
      };

      final count = await db.update(
        StorageConstants.tableCollections,
        collectionMap,
        where: 'id = ?',
        whereArgs: [collection.id],
      );

      if (count == 0) {
        throw app_exceptions.NotFoundException(
            'Collection not found with id: ${collection.id}');
      }

      return collection;
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to update collection: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCollection(String id) async {
    try {
      final db = await DatabaseConfig.instance.database;

      // Check if collection exists
      final existing = await db.query(
        StorageConstants.tableCollections,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (existing.isEmpty) {
        throw app_exceptions.NotFoundException(
            'Collection not found with id: $id');
      }

      await db.delete(
        StorageConstants.tableCollections,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to delete collection: ${e.toString()}');
    }
  }

  @override
  Future<void> addBookToCollection(String collectionId, String bookId) async {
    try {
      final db = await DatabaseConfig.instance.database;

      // Check if collection exists
      final collectionExists = await db.query(
        StorageConstants.tableCollections,
        where: 'id = ?',
        whereArgs: [collectionId],
        limit: 1,
      );

      if (collectionExists.isEmpty) {
        throw app_exceptions.NotFoundException(
            'Collection not found with id: $collectionId');
      }

      // Check if book exists
      final bookExists = await db.query(
        StorageConstants.tableBooks,
        where: 'id = ?',
        whereArgs: [bookId],
        limit: 1,
      );

      if (bookExists.isEmpty) {
        throw app_exceptions.NotFoundException(
            'Book not found with id: $bookId');
      }

      // Check if relationship already exists
      final existing = await db.query(
        'collection_books',
        where: 'collection_id = ? AND book_id = ?',
        whereArgs: [collectionId, bookId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return; // Relationship already exists, no need to add
      }

      await db.insert('collection_books', {
        'collection_id': collectionId,
        'book_id': bookId,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to add book to collection: ${e.toString()}');
    }
  }

  @override
  Future<void> removeBookFromCollection(
      String collectionId, String bookId) async {
    try {
      final db = await DatabaseConfig.instance.database;

      await db.delete(
        'collection_books',
        where: 'collection_id = ? AND book_id = ?',
        whereArgs: [collectionId, bookId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to remove book from collection: ${e.toString()}');
    }
  }

  @override
  Future<List<BookModel>> getBooksInCollection(String collectionId,
      {int? limit, int? offset}) async {
    try {
      final db = await DatabaseConfig.instance.database;

      String query = '''
        SELECT b.* FROM ${StorageConstants.tableBooks} b
        INNER JOIN collection_books cb ON b.id = cb.book_id
        WHERE cb.collection_id = ?
        ORDER BY cb.added_at DESC
      ''';

      if (limit != null) {
        query += ' LIMIT $limit';
        if (offset != null) {
          query += ' OFFSET $offset';
        }
      }

      final maps = await db.rawQuery(query, [collectionId]);
      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get books in collection: ${e.toString()}');
    }
  }

  @override
  Future<void> addBookCategory(String bookId, String categoryId) async {
    try {
      final db = await DatabaseConfig.instance.database;

      // Check if book exists
      final bookExists = await db.query(
        StorageConstants.tableBooks,
        where: 'id = ?',
        whereArgs: [bookId],
        limit: 1,
      );

      if (bookExists.isEmpty) {
        throw app_exceptions.NotFoundException(
            'Book not found with id: $bookId');
      }

      // Check if category exists
      final categoryExists = await db.query(
        StorageConstants.tableCategories,
        where: 'id = ?',
        whereArgs: [categoryId],
        limit: 1,
      );

      if (categoryExists.isEmpty) {
        throw app_exceptions.NotFoundException(
            'Category not found with id: $categoryId');
      }

      // Check if relationship already exists
      final existing = await db.query(
        'book_categories',
        where: 'book_id = ? AND category_id = ?',
        whereArgs: [bookId, categoryId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return; // Relationship already exists, no need to add
      }

      await db.insert('book_categories', {
        'book_id': bookId,
        'category_id': categoryId,
      });
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException(
          'Failed to add book category: ${e.toString()}');
    }
  }

  @override
  Future<void> removeBookCategory(String bookId, String categoryId) async {
    try {
      final db = await DatabaseConfig.instance.database;

      await db.delete(
        'book_categories',
        where: 'book_id = ? AND category_id = ?',
        whereArgs: [bookId, categoryId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to remove book category: ${e.toString()}');
    }
  }

  @override
  Future<List<CategoryModel>> getBookCategories(String bookId) async {
    try {
      final db = await DatabaseConfig.instance.database;

      final maps = await db.rawQuery('''
        SELECT c.* FROM ${StorageConstants.tableCategories} c
        INNER JOIN book_categories bc ON c.id = bc.category_id
        WHERE bc.book_id = ?
        ORDER BY c.name ASC
      ''', [bookId]);

      return maps.map((map) => CategoryModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to get book categories: ${e.toString()}');
    }
  }

  // Additional library management functionality

  /// Advanced search with multiple filters
  Future<List<BookModel>> searchBooksAdvanced({
    String? query,
    List<String>? categoryIds,
    List<String>? authorIds,
    DateTime? publishedAfter,
    DateTime? publishedBefore,
    List<String>? languages,
    double? minRating,
    String? format,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _databaseConfig.database;

      List<String> conditions = [];
      List<dynamic> args = [];

      String sqlQuery = '''
        SELECT DISTINCT b.* FROM ${StorageConstants.tableBooks} b
        LEFT JOIN book_authors ba ON b.id = ba.book_id
        LEFT JOIN ${StorageConstants.tableAuthors} a ON ba.author_id = a.id
        LEFT JOIN book_categories bc ON b.id = bc.book_id
        LEFT JOIN ${StorageConstants.tableCategories} c ON bc.category_id = c.id
      ''';

      // Text search in title, description, or author names
      if (query != null && query.trim().isNotEmpty) {
        conditions.add('''
          (b.title LIKE ? OR 
           b.description LIKE ? OR 
           a.name LIKE ?)
        ''');
        String searchPattern = '%${query.trim()}%';
        args.addAll([searchPattern, searchPattern, searchPattern]);
      }

      // Category filter with subcategory inclusion
      if (categoryIds != null && categoryIds.isNotEmpty) {
        String categoryPlaceholders = categoryIds.map((_) => '?').join(',');
        conditions.add('bc.category_id IN ($categoryPlaceholders)');
        args.addAll(categoryIds);
      }

      // Author filter
      if (authorIds != null && authorIds.isNotEmpty) {
        String authorPlaceholders = authorIds.map((_) => '?').join(',');
        conditions.add('ba.author_id IN ($authorPlaceholders)');
        args.addAll(authorIds);
      }

      // Publication date range
      if (publishedAfter != null) {
        conditions.add('b.publication_date >= ?');
        args.add(publishedAfter.millisecondsSinceEpoch);
      }

      if (publishedBefore != null) {
        conditions.add('b.publication_date <= ?');
        args.add(publishedBefore.millisecondsSinceEpoch);
      }

      // Language filter
      if (languages != null && languages.isNotEmpty) {
        String languagePlaceholders = languages.map((_) => '?').join(',');
        conditions.add('b.language IN ($languagePlaceholders)');
        args.addAll(languages);
      }

      // Rating filter
      if (minRating != null) {
        conditions.add('b.rating >= ?');
        args.add(minRating);
      }

      // Format filter
      if (format != null && format.trim().isNotEmpty) {
        conditions.add('b.format = ?');
        args.add(format.trim());
      }

      if (conditions.isNotEmpty) {
        sqlQuery += ' WHERE ${conditions.join(' AND ')}';
      }

      sqlQuery += ' ORDER BY b.title ASC';

      if (limit != null) {
        sqlQuery += ' LIMIT $limit';
        if (offset != null) {
          sqlQuery += ' OFFSET $offset';
        }
      }

      final maps = await db.rawQuery(sqlQuery, args);
      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to search books: ${e.toString()}');
    }
  }

  /// Filter books by reading status and collections
  Future<List<BookModel>> getBooksByFilters({
    List<String>? categoryIds,
    List<String>? collectionIds,
    bool? isRead,
    bool? isFavorite,
    String? readingStatus,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _databaseConfig.database;

      List<String> conditions = [];
      List<dynamic> args = [];

      String sqlQuery = '''
        SELECT DISTINCT b.* FROM ${StorageConstants.tableBooks} b
        LEFT JOIN book_categories bc ON b.id = bc.book_id
        LEFT JOIN collection_books cb ON b.id = cb.book_id
      ''';

      // Category filter
      if (categoryIds != null && categoryIds.isNotEmpty) {
        String categoryPlaceholders = categoryIds.map((_) => '?').join(',');
        conditions.add('bc.category_id IN ($categoryPlaceholders)');
        args.addAll(categoryIds);
      }

      // Collection filter
      if (collectionIds != null && collectionIds.isNotEmpty) {
        String collectionPlaceholders = collectionIds.map((_) => '?').join(',');
        conditions.add('cb.collection_id IN ($collectionPlaceholders)');
        args.addAll(collectionIds);
      }

      // Reading status filters
      if (isRead != null) {
        conditions.add('b.is_read = ?');
        args.add(isRead ? 1 : 0);
      }

      if (isFavorite != null) {
        conditions.add('b.is_favorite = ?');
        args.add(isFavorite ? 1 : 0);
      }

      if (readingStatus != null) {
        conditions.add('b.reading_status = ?');
        args.add(readingStatus);
      }

      if (conditions.isNotEmpty) {
        sqlQuery += ' WHERE ${conditions.join(' AND ')}';
      }

      sqlQuery += ' ORDER BY b.title ASC';

      if (limit != null) {
        sqlQuery += ' LIMIT $limit';
        if (offset != null) {
          sqlQuery += ' OFFSET $offset';
        }
      }

      final maps = await db.rawQuery(sqlQuery, args);
      return maps.map((map) => BookModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to filter books: ${e.toString()}');
    }
  }

  /// Find potential duplicate books based on title and author similarity
  Future<List<List<BookModel>>> findDuplicateBooks(
      {double similarityThreshold = 0.8}) async {
    try {
      final db = await _databaseConfig.database;

      // Get all books with their authors
      final maps = await db.rawQuery('''
        SELECT b.*, GROUP_CONCAT(a.name, ';') as author_names
        FROM ${StorageConstants.tableBooks} b
        LEFT JOIN book_authors ba ON b.id = ba.book_id
        LEFT JOIN ${StorageConstants.tableAuthors} a ON ba.author_id = a.id
        GROUP BY b.id
        ORDER BY b.title ASC
      ''');

      List<BookModel> books = maps.map((map) {
        Map<String, dynamic> bookMap = Map<String, dynamic>.from(map);
        bookMap.remove(
            'author_names'); // Remove the concatenated author names for BookModel creation
        return BookModel.fromMap(bookMap);
      }).toList();

      List<List<BookModel>> duplicateGroups = [];
      Set<String> processedIds = {};

      for (int i = 0; i < books.length; i++) {
        if (processedIds.contains(books[i].id)) continue;

        List<BookModel> duplicates = [books[i]];
        processedIds.add(books[i].id);

        for (int j = i + 1; j < books.length; j++) {
          if (processedIds.contains(books[j].id)) continue;

          if (_areBooksLikelyDuplicates(
              books[i],
              books[j],
              maps[i]['author_names'] as String?,
              maps[j]['author_names'] as String?)) {
            duplicates.add(books[j]);
            processedIds.add(books[j].id);
          }
        }

        if (duplicates.length > 1) {
          duplicateGroups.add(duplicates);
        }
      }

      return duplicateGroups;
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to find duplicate books: ${e.toString()}');
    }
  }

  /// Helper method to determine if two books are likely duplicates
  bool _areBooksLikelyDuplicates(
      BookModel book1, BookModel book2, String? authors1, String? authors2) {
    // Normalize titles for comparison
    String title1 = _normalizeTitle(book1.title);
    String title2 = _normalizeTitle(book2.title);

    // Check title similarity
    double titleSimilarity = _calculateStringSimilarity(title1, title2);
    if (titleSimilarity < 0.7) return false;

    // Check author similarity if available
    if (authors1 != null && authors2 != null) {
      List<String> authorList1 =
          authors1.split(';').map((a) => a.trim().toLowerCase()).toList();
      List<String> authorList2 =
          authors2.split(';').map((a) => a.trim().toLowerCase()).toList();

      bool hasCommonAuthor = authorList1.any((author1) => authorList2.any(
          (author2) => _calculateStringSimilarity(author1, author2) > 0.8));

      if (!hasCommonAuthor) return false;
    }

    // Check ISBN similarity if available
    if (book1.isbn != null && book2.isbn != null && book1.isbn == book2.isbn) {
      return true;
    }

    // Additional checks for publication year proximity
    if (book1.publicationDate != null && book2.publicationDate != null) {
      int year1 = int.tryParse(book1.publicationDate!) ?? 0;
      int year2 = int.tryParse(book2.publicationDate!) ?? 0;
      if (year1 > 0 && year2 > 0 && (year1 - year2).abs() > 2) {
        return false; // Different editions should be within 2 years
      }
    }

    return titleSimilarity > 0.8;
  }

  /// Normalize book title for comparison
  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Calculate string similarity using Jaro-Winkler distance
  double _calculateStringSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Simple implementation - in production, use a proper string similarity library
    int maxLength = s1.length > s2.length ? s1.length : s2.length;
    int distance = _levenshteinDistance(s1, s2);
    return 1.0 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Export library data to JSON
  Future<Map<String, dynamic>> exportLibraryData({
    bool includeBooks = true,
    bool includeAuthors = true,
    bool includeCategories = true,
    bool includeCollections = true,
    List<String>? bookIds,
  }) async {
    try {
      final db = await _databaseConfig.database;
      Map<String, dynamic> exportData = {
        'exported_at': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      if (includeBooks) {
        String booksQuery = 'SELECT * FROM ${StorageConstants.tableBooks}';
        List<dynamic> booksArgs = [];

        if (bookIds != null && bookIds.isNotEmpty) {
          String placeholders = bookIds.map((_) => '?').join(',');
          booksQuery += ' WHERE id IN ($placeholders)';
          booksArgs = bookIds;
        }

        final bookMaps = await db.rawQuery(booksQuery, booksArgs);
        exportData['books'] = bookMaps;
      }

      if (includeAuthors) {
        final authorMaps = await db.query(StorageConstants.tableAuthors);
        exportData['authors'] = authorMaps;
      }

      if (includeCategories) {
        final categoryMaps = await db.query(StorageConstants.tableCategories);
        exportData['categories'] = categoryMaps;
      }

      if (includeCollections) {
        final collectionMaps =
            await db.query(StorageConstants.tableCollections);
        exportData['collections'] = collectionMaps;
      }

      // Export relationships
      final bookAuthorMaps = await db.query('book_authors');
      final bookCategoryMaps = await db.query('book_categories');
      final collectionBookMaps = await db.query('collection_books');

      exportData['relationships'] = {
        'book_authors': bookAuthorMaps,
        'book_categories': bookCategoryMaps,
        'collection_books': collectionBookMaps,
      };

      return exportData;
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to export library data: ${e.toString()}');
    }
  }

  /// Import library data from JSON
  Future<void> importLibraryData(Map<String, dynamic> data,
      {bool replaceExisting = false}) async {
    try {
      final db = await _databaseConfig.database;

      await db.transaction((txn) async {
        // Import books
        if (data['books'] != null) {
          for (Map<String, dynamic> bookMap in data['books']) {
            await txn.insert(
              StorageConstants.tableBooks,
              bookMap,
              conflictAlgorithm: replaceExisting
                  ? ConflictAlgorithm.replace
                  : ConflictAlgorithm.ignore,
            );
          }
        }

        // Import authors
        if (data['authors'] != null) {
          for (Map<String, dynamic> authorMap in data['authors']) {
            await txn.insert(
              StorageConstants.tableAuthors,
              authorMap,
              conflictAlgorithm: replaceExisting
                  ? ConflictAlgorithm.replace
                  : ConflictAlgorithm.ignore,
            );
          }
        }

        // Import categories
        if (data['categories'] != null) {
          for (Map<String, dynamic> categoryMap in data['categories']) {
            await txn.insert(
              StorageConstants.tableCategories,
              categoryMap,
              conflictAlgorithm: replaceExisting
                  ? ConflictAlgorithm.replace
                  : ConflictAlgorithm.ignore,
            );
          }
        }

        // Import collections
        if (data['collections'] != null) {
          for (Map<String, dynamic> collectionMap in data['collections']) {
            await txn.insert(
              StorageConstants.tableCollections,
              collectionMap,
              conflictAlgorithm: replaceExisting
                  ? ConflictAlgorithm.replace
                  : ConflictAlgorithm.ignore,
            );
          }
        }

        // Import relationships
        if (data['relationships'] != null) {
          final relationships = data['relationships'] as Map<String, dynamic>;

          if (relationships['book_authors'] != null) {
            for (Map<String, dynamic> relMap in relationships['book_authors']) {
              await txn.insert(
                'book_authors',
                relMap,
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }

          if (relationships['book_categories'] != null) {
            for (Map<String, dynamic> relMap
                in relationships['book_categories']) {
              await txn.insert(
                'book_categories',
                relMap,
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }

          if (relationships['collection_books'] != null) {
            for (Map<String, dynamic> relMap
                in relationships['collection_books']) {
              await txn.insert(
                'collection_books',
                relMap,
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
        }
      });
    } catch (e) {
      throw app_exceptions.DatabaseException(
          'Failed to import library data: ${e.toString()}');
    }
  }
}
