import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/book.dart';
import '../entities/author.dart';
import '../entities/category.dart';
import '../entities/collection.dart';

/// Repository interface for book management operations
/// 
/// Defines all book-related data operations including CRUD operations,
/// search functionality, and relationship management with authors and categories.
abstract class BookRepository {
  // Book CRUD operations
  
  /// Get a book by its ID
  Future<Either<Failure, Book>> getBookById(String id);
  
  /// Get all books with optional filtering and sorting
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
  });
  
  /// Get books count with optional filtering
  Future<Either<Failure, int>> getBooksCount({
    String? search,
    BookFormat? format,
    BookSource? source,
    String? authorId,
    String? categoryId,
  });
  
  /// Save a new book or update existing book
  Future<Either<Failure, Book>> saveBook(Book book);
  
  /// Update book metadata
  Future<Either<Failure, Book>> updateBook(Book book);
  
  /// Delete a book by ID
  Future<Either<Failure, void>> deleteBook(String id);
  
  /// Delete multiple books by IDs
  Future<Either<Failure, int>> deleteBooks(List<String> ids);
  
  // Book search operations
  
  /// Search books by title, author, or description
  Future<Either<Failure, List<Book>>> searchBooks({
    required String query,
    int? limit,
    int? offset,
    List<BookFormat>? formats,
    List<BookSource>? sources,
  });
  
  /// Get recently opened books
  Future<Either<Failure, List<Book>>> getRecentBooks({
    int limit = 10,
  });
  
  /// Get downloaded books (available offline)
  Future<Either<Failure, List<Book>>> getDownloadedBooks({
    int? limit,
    int? offset,
  });
  
  /// Get books by format
  Future<Either<Failure, List<Book>>> getBooksByFormat(
    BookFormat format, {
    int? limit,
    int? offset,
  });
  
  /// Get books by source
  Future<Either<Failure, List<Book>>> getBooksBySource(
    BookSource source, {
    int? limit,
    int? offset,
  });
  
  // Author operations
  
  /// Get author by ID
  Future<Either<Failure, Author>> getAuthorById(String id);
  
  /// Get all authors
  Future<Either<Failure, List<Author>>> getAuthors({
    int? limit,
    int? offset,
    String? search,
  });
  
  /// Save author
  Future<Either<Failure, Author>> saveAuthor(Author author);
  
  /// Get books by author
  Future<Either<Failure, List<Book>>> getBooksByAuthor(
    String authorId, {
    int? limit,
    int? offset,
  });
  
  /// Search authors by name
  Future<Either<Failure, List<Author>>> searchAuthors(String query);
  
  // Category operations
  
  /// Get category by ID
  Future<Either<Failure, Category>> getCategoryById(String id);
  
  /// Get all categories
  Future<Either<Failure, List<Category>>> getCategories({
    String? parentId,
    bool includeChildCategories = true,
  });
  
  /// Save category
  Future<Either<Failure, Category>> saveCategory(Category category);
  
  /// Get books by category
  Future<Either<Failure, List<Book>>> getBooksByCategory(
    String categoryId, {
    int? limit,
    int? offset,
    bool includeSubcategories = false,
  });
  
  /// Search categories by name
  Future<Either<Failure, List<Category>>> searchCategories(String query);
  
  // Collection operations
  
  /// Get collection by ID
  Future<Either<Failure, Collection>> getCollectionById(String id);
  
  /// Get all collections
  Future<Either<Failure, List<Collection>>> getCollections({
    int? limit,
    int? offset,
    bool publicOnly = false,
  });
  
  /// Save collection
  Future<Either<Failure, Collection>> saveCollection(Collection collection);
  
  /// Delete collection
  Future<Either<Failure, void>> deleteCollection(String id);
  
  /// Add book to collection
  Future<Either<Failure, void>> addBookToCollection(
    String collectionId,
    String bookId,
  );
  
  /// Remove book from collection
  Future<Either<Failure, void>> removeBookFromCollection(
    String collectionId,
    String bookId,
  );
  
  /// Get books in collection
  Future<Either<Failure, List<Book>>> getBooksInCollection(
    String collectionId, {
    int? limit,
    int? offset,
  });
  
  // Relationship operations
  
  /// Associate book with author
  Future<Either<Failure, void>> addBookAuthor(
    String bookId,
    String authorId, {
    String role = 'author',
  });
  
  /// Remove book-author association
  Future<Either<Failure, void>> removeBookAuthor(
    String bookId,
    String authorId,
  );
  
  /// Associate book with category
  Future<Either<Failure, void>> addBookCategory(
    String bookId,
    String categoryId,
  );
  
  /// Remove book-category association
  Future<Either<Failure, void>> removeBookCategory(
    String bookId,
    String categoryId,
  );
  
  // File operations
  
  /// Update book file path after download
  Future<Either<Failure, Book>> updateBookFilePath(
    String bookId,
    String filePath,
  );
  
  /// Update book last opened timestamp
  Future<Either<Failure, void>> updateLastOpened(String bookId);
  
  /// Get total storage used by books
  Future<Either<Failure, int>> getTotalStorageUsed();
  
  /// Clean up orphaned files
  Future<Either<Failure, List<String>>> cleanupOrphanedFiles();
}

/// Book sorting options
enum BookSortBy {
  title('title'),
  createdAt('created_at'),
  updatedAt('updated_at'),
  lastOpenedAt('last_opened_at'),
  downloadedAt('downloaded_at'),
  publicationDate('publication_date'),
  fileSize('file_size'),
  author('author'),
  random('random');

  const BookSortBy(this.value);
  final String value;

  static BookSortBy fromString(String value) {
    switch (value.toLowerCase()) {
      case 'title':
        return BookSortBy.title;
      case 'created_at':
        return BookSortBy.createdAt;
      case 'updated_at':
        return BookSortBy.updatedAt;
      case 'last_opened_at':
        return BookSortBy.lastOpenedAt;
      case 'downloaded_at':
        return BookSortBy.downloadedAt;
      case 'publication_date':
        return BookSortBy.publicationDate;
      case 'file_size':
        return BookSortBy.fileSize;
      case 'author':
        return BookSortBy.author;
      case 'random':
        return BookSortBy.random;
      default:
        return BookSortBy.title;
    }
  }
}

/// Sort order options
enum SortOrder {
  asc('ASC'),
  desc('DESC');

  const SortOrder(this.value);
  final String value;

  static SortOrder fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ASC':
        return SortOrder.asc;
      case 'DESC':
        return SortOrder.desc;
      default:
        return SortOrder.asc;
    }
  }
}
