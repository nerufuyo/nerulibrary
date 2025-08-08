import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart' as app_exceptions;
import '../../domain/entities/book.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/collection.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_local_datasource.dart';
import '../models/book_model.dart';
import '../models/author_model.dart';
import '../models/category_model.dart';

/// Implementation of BookRepository
/// 
/// Handles all book-related operations using local data source
/// with proper error handling and data transformation.
class BookRepositoryImpl implements BookRepository {
  final BookLocalDataSource _localDataSource;
  
  const BookRepositoryImpl({
    required BookLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, Book>> getBookById(String id) async {
    try {
      final bookModel = await _localDataSource.getBookById(id);
      
      // Load authors and categories for the book
      final authors = await _localDataSource.getBookAuthors(id);
      final categories = await _localDataSource.getBookCategories(id);
      
      final book = bookModel.toEntity().copyWith(
        authors: authors.map((author) => author.toEntity()).toList(),
        categories: categories.map((category) => category.toEntity()).toList(),
      );
      
      return Right(book);
    } on app_exceptions.NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Book>>> getBooks({
    int? limit,
    int? offset,
    String? search,
    BookFormat? format,
    BookSource? source,
    String? authorId,
    String? categoryId,
    BookSortBy? sortBy,
    SortOrder? sortOrder,
  }) async {
    try {
      final bookModels = await _localDataSource.getBooks(
        limit: limit,
        offset: offset,
        search: search,
        format: format?.value,
        source: source?.value,
        authorId: authorId,
        categoryId: categoryId,
        sortBy: sortBy?.value,
        sortOrder: sortOrder?.value,
      );
      
      // Convert to entities and load relationships
      final books = <Book>[];
      for (final bookModel in bookModels) {
        final authors = await _localDataSource.getBookAuthors(bookModel.id);
        final categories = await _localDataSource.getBookCategories(bookModel.id);
        
        final book = bookModel.toEntity().copyWith(
          authors: authors.map((author) => author.toEntity()).toList(),
          categories: categories.map((category) => category.toEntity()).toList(),
        );
        
        books.add(book);
      }
      
      return Right(books);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getBooksCount({
    String? search,
    BookFormat? format,
    BookSource? source,
    String? authorId,
    String? categoryId,
  }) async {
    try {
      final count = await _localDataSource.getBooksCount(
        search: search,
        format: format?.value,
        source: source?.value,
        authorId: authorId,
        categoryId: categoryId,
      );
      
      return Right(count);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Book>> saveBook(Book book) async {
    try {
      // Save book
      final bookModel = BookModel.fromEntity(book);
      final savedBookModel = await _localDataSource.insertBook(bookModel);
      
      // Save authors and create relationships
      for (final author in book.authors) {
        final authorModel = AuthorModel.fromEntity(author);
        await _localDataSource.insertAuthor(authorModel);
        await _localDataSource.addBookAuthor(book.id, author.id);
      }
      
      // Save categories and create relationships
      for (final category in book.categories) {
        // Note: Category operations are stubbed for now
        await _localDataSource.addBookCategory(book.id, category.id);
      }
      
      return Right(savedBookModel.toEntity().copyWith(
        authors: book.authors,
        categories: book.categories,
      ));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Book>> updateBook(Book book) async {
    try {
      final bookModel = BookModel.fromEntity(book);
      final updatedBookModel = await _localDataSource.updateBook(bookModel);
      
      // Load current relationships
      final authors = await _localDataSource.getBookAuthors(book.id);
      final categories = await _localDataSource.getBookCategories(book.id);
      
      return Right(updatedBookModel.toEntity().copyWith(
        authors: authors.map((author) => author.toEntity()).toList(),
        categories: categories.map((category) => category.toEntity()).toList(),
      ));
    } on app_exceptions.NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBook(String id) async {
    try {
      await _localDataSource.deleteBook(id);
      return const Right(null);
    } on app_exceptions.NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> deleteBooks(List<String> ids) async {
    try {
      final count = await _localDataSource.deleteBooks(ids);
      return Right(count);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Book>>> searchBooks({
    required String query,
    int? limit,
    int? offset,
    List<BookFormat>? formats,
    List<BookSource>? sources,
  }) async {
    try {
      final bookModels = await _localDataSource.searchBooks(
        query: query,
        limit: limit,
        offset: offset,
        formats: formats?.map((f) => f.value).toList(),
        sources: sources?.map((s) => s.value).toList(),
      );
      
      // Convert to entities with relationships
      final books = <Book>[];
      for (final bookModel in bookModels) {
        final authors = await _localDataSource.getBookAuthors(bookModel.id);
        final categories = await _localDataSource.getBookCategories(bookModel.id);
        
        final book = bookModel.toEntity().copyWith(
          authors: authors.map((author) => author.toEntity()).toList(),
          categories: categories.map((category) => category.toEntity()).toList(),
        );
        
        books.add(book);
      }
      
      return Right(books);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Book>>> getRecentBooks({int limit = 10}) async {
    try {
      final bookModels = await _localDataSource.getRecentBooks(limit: limit);
      
      // Convert to entities with relationships
      final books = <Book>[];
      for (final bookModel in bookModels) {
        final authors = await _localDataSource.getBookAuthors(bookModel.id);
        final categories = await _localDataSource.getBookCategories(bookModel.id);
        
        final book = bookModel.toEntity().copyWith(
          authors: authors.map((author) => author.toEntity()).toList(),
          categories: categories.map((category) => category.toEntity()).toList(),
        );
        
        books.add(book);
      }
      
      return Right(books);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Book>>> getDownloadedBooks({int? limit, int? offset}) async {
    try {
      final bookModels = await _localDataSource.getDownloadedBooks(
        limit: limit,
        offset: offset,
      );
      
      // Convert to entities with relationships
      final books = <Book>[];
      for (final bookModel in bookModels) {
        final authors = await _localDataSource.getBookAuthors(bookModel.id);
        final categories = await _localDataSource.getBookCategories(bookModel.id);
        
        final book = bookModel.toEntity().copyWith(
          authors: authors.map((author) => author.toEntity()).toList(),
          categories: categories.map((category) => category.toEntity()).toList(),
        );
        
        books.add(book);
      }
      
      return Right(books);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Book>>> getBooksByFormat(BookFormat format, {int? limit, int? offset}) async {
    try {
      final bookModels = await _localDataSource.getBooksByFormat(
        format.value,
        limit: limit,
        offset: offset,
      );
      
      // Convert to entities with relationships
      final books = <Book>[];
      for (final bookModel in bookModels) {
        final authors = await _localDataSource.getBookAuthors(bookModel.id);
        final categories = await _localDataSource.getBookCategories(bookModel.id);
        
        final book = bookModel.toEntity().copyWith(
          authors: authors.map((author) => author.toEntity()).toList(),
          categories: categories.map((category) => category.toEntity()).toList(),
        );
        
        books.add(book);
      }
      
      return Right(books);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Book>>> getBooksBySource(BookSource source, {int? limit, int? offset}) async {
    try {
      final bookModels = await _localDataSource.getBooksBySource(
        source.value,
        limit: limit,
        offset: offset,
      );
      
      // Convert to entities with relationships
      final books = <Book>[];
      for (final bookModel in bookModels) {
        final authors = await _localDataSource.getBookAuthors(bookModel.id);
        final categories = await _localDataSource.getBookCategories(bookModel.id);
        
        final book = bookModel.toEntity().copyWith(
          authors: authors.map((author) => author.toEntity()).toList(),
          categories: categories.map((category) => category.toEntity()).toList(),
        );
        
        books.add(book);
      }
      
      return Right(books);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Author>> getAuthorById(String id) async {
    try {
      final authorModel = await _localDataSource.getAuthorById(id);
      return Right(authorModel.toEntity());
    } on app_exceptions.NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Author>>> getAuthors({int? limit, int? offset, String? search}) async {
    try {
      final authorModels = await _localDataSource.getAuthors(
        limit: limit,
        offset: offset,
        search: search,
      );
      
      final authors = authorModels.map((model) => model.toEntity()).toList();
      return Right(authors);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Author>> saveAuthor(Author author) async {
    try {
      final authorModel = AuthorModel.fromEntity(author);
      final savedAuthorModel = await _localDataSource.insertAuthor(authorModel);
      return Right(savedAuthorModel.toEntity());
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Book>>> getBooksByAuthor(String authorId, {int? limit, int? offset}) async {
    try {
      final bookModels = await _localDataSource.getBooksByAuthor(
        authorId,
        limit: limit,
        offset: offset,
      );
      
      // Convert to entities with relationships
      final books = <Book>[];
      for (final bookModel in bookModels) {
        final authors = await _localDataSource.getBookAuthors(bookModel.id);
        final categories = await _localDataSource.getBookCategories(bookModel.id);
        
        final book = bookModel.toEntity().copyWith(
          authors: authors.map((author) => author.toEntity()).toList(),
          categories: categories.map((category) => category.toEntity()).toList(),
        );
        
        books.add(book);
      }
      
      return Right(books);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Author>>> searchAuthors(String query) async {
    try {
      final authorModels = await _localDataSource.searchAuthors(query);
      final authors = authorModels.map((model) => model.toEntity()).toList();
      return Right(authors);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Book>> updateBookFilePath(String bookId, String filePath) async {
    try {
      final bookModel = await _localDataSource.updateBookFilePath(bookId, filePath);
      
      // Load relationships
      final authors = await _localDataSource.getBookAuthors(bookId);
      final categories = await _localDataSource.getBookCategories(bookId);
      
      final book = bookModel.toEntity().copyWith(
        authors: authors.map((author) => author.toEntity()).toList(),
        categories: categories.map((category) => category.toEntity()).toList(),
      );
      
      return Right(book);
    } on app_exceptions.NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastOpened(String bookId) async {
    try {
      await _localDataSource.updateLastOpened(bookId);
      return const Right(null);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getTotalStorageUsed() async {
    try {
      final total = await _localDataSource.getTotalStorageUsed();
      return Right(total);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> cleanupOrphanedFiles() async {
    try {
      final orphanedFiles = await _localDataSource.getOrphanedFiles();
      return Right(orphanedFiles);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // Relationship operations
  
  @override
  Future<Either<Failure, void>> addBookAuthor(String bookId, String authorId, {String role = 'author'}) async {
    try {
      await _localDataSource.addBookAuthor(bookId, authorId, role: role);
      return const Right(null);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeBookAuthor(String bookId, String authorId) async {
    try {
      await _localDataSource.removeBookAuthor(bookId, authorId);
      return const Right(null);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // Stubbed implementations for unsupported operations
  
  @override
  Future<Either<Failure, Category>> getCategoryById(String id) async {
    try {
      final categoryModel = await _localDataSource.getCategoryById(id);
      final category = categoryModel.toEntity();
      return Right(category);
    } on app_exceptions.NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories({String? parentId, bool includeChildCategories = true}) async {
    try {
      final categoryModels = await _localDataSource.getCategories(
        parentId: parentId,
        includeChildCategories: includeChildCategories,
      );
      final categories = categoryModels.map((model) => model.toEntity()).toList();
      return Right(categories);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> saveCategory(Category category) async {
    try {
      final categoryModel = CategoryModel.fromEntity(category);
      
      // Check if category exists
      try {
        await _localDataSource.getCategoryById(category.id);
        // If it exists, update it
        final updatedModel = await _localDataSource.updateCategory(categoryModel);
        return Right(updatedModel.toEntity());
      } on app_exceptions.NotFoundException {
        // If it doesn't exist, insert it
        final insertedModel = await _localDataSource.insertCategory(categoryModel);
        return Right(insertedModel.toEntity());
      }
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Book>>> getBooksByCategory(String categoryId, {int? limit, int? offset, bool includeSubcategories = false}) async {
    try {
      final bookModels = await _localDataSource.getBooksByCategory(
        categoryId,
        limit: limit,
        offset: offset,
        includeSubcategories: includeSubcategories,
      );
      
      // Convert to entities with relationships
      final books = <Book>[];
      for (final bookModel in bookModels) {
        final authors = await _localDataSource.getBookAuthors(bookModel.id);
        final categories = await _localDataSource.getBookCategories(bookModel.id);
        
        final book = bookModel.toEntity().copyWith(
          authors: authors.map((author) => author.toEntity()).toList(),
          categories: categories.map((category) => category.toEntity()).toList(),
        );
        
        books.add(book);
      }
      
      return Right(books);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> searchCategories(String query) async {
    try {
      final categoryModels = await _localDataSource.searchCategories(query);
      final categories = categoryModels.map((model) => model.toEntity()).toList();
      return Right(categories);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Collection>> getCollectionById(String id) async {
    try {
      final collection = await _localDataSource.getCollectionById(id);
      return Right(collection);
    } on app_exceptions.NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Collection>>> getCollections({int? limit, int? offset, bool publicOnly = false}) async {
    try {
      final collections = await _localDataSource.getCollections(
        limit: limit,
        offset: offset,
        publicOnly: publicOnly,
      );
      return Right(collections);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Collection>> saveCollection(Collection collection) async {
    try {
      // Check if collection exists
      try {
        await _localDataSource.getCollectionById(collection.id);
        // If it exists, update it
        final updatedCollection = await _localDataSource.updateCollection(collection);
        return Right(updatedCollection);
      } on app_exceptions.NotFoundException {
        // If it doesn't exist, insert it
        final insertedCollection = await _localDataSource.insertCollection(collection);
        return Right(insertedCollection);
      }
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCollection(String id) async {
    try {
      await _localDataSource.deleteCollection(id);
      return const Right(null);
    } on app_exceptions.NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addBookToCollection(String collectionId, String bookId) async {
    try {
      await _localDataSource.addBookToCollection(collectionId, bookId);
      return const Right(null);
    } on app_exceptions.NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeBookFromCollection(String collectionId, String bookId) async {
    try {
      await _localDataSource.removeBookFromCollection(collectionId, bookId);
      return const Right(null);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Book>>> getBooksInCollection(String collectionId, {int? limit, int? offset}) async {
    try {
      final bookModels = await _localDataSource.getBooksInCollection(
        collectionId,
        limit: limit,
        offset: offset,
      );
      
      // Convert to entities with relationships
      final books = <Book>[];
      for (final bookModel in bookModels) {
        final authors = await _localDataSource.getBookAuthors(bookModel.id);
        final categories = await _localDataSource.getBookCategories(bookModel.id);
        
        final book = bookModel.toEntity().copyWith(
          authors: authors.map((author) => author.toEntity()).toList(),
          categories: categories.map((category) => category.toEntity()).toList(),
        );
        
        books.add(book);
      }
      
      return Right(books);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addBookCategory(String bookId, String categoryId) async {
    return Left(UnknownFailure(message: 'Category operations not yet implemented'));
  }

  @override
  Future<Either<Failure, void>> removeBookCategory(String bookId, String categoryId) async {
    return Left(UnknownFailure(message: 'Category operations not yet implemented'));
  }
}
