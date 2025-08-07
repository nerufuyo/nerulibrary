import '../models/book_model.dart';
import '../models/author_model.dart';
import '../models/category_model.dart';
import '../../domain/entities/collection.dart';

/// Local data source interface for database operations
/// 
/// Defines all database operations for books, authors, categories,
/// and their relationships using SQLite through the sqflite package.
abstract class BookLocalDataSource {
  // Book operations
  Future<BookModel> getBookById(String id);
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
  });
  Future<int> getBooksCount({
    String? search,
    String? format,
    String? source,
    String? authorId,
    String? categoryId,
  });
  Future<BookModel> insertBook(BookModel book);
  Future<BookModel> updateBook(BookModel book);
  Future<void> deleteBook(String id);
  Future<int> deleteBooks(List<String> ids);
  
  // Search operations
  Future<List<BookModel>> searchBooks({
    required String query,
    int? limit,
    int? offset,
    List<String>? formats,
    List<String>? sources,
  });
  Future<List<BookModel>> getRecentBooks({int limit = 10});
  Future<List<BookModel>> getDownloadedBooks({int? limit, int? offset});
  Future<List<BookModel>> getBooksByFormat(String format, {int? limit, int? offset});
  Future<List<BookModel>> getBooksBySource(String source, {int? limit, int? offset});
  
  // Author operations
  Future<AuthorModel> getAuthorById(String id);
  Future<List<AuthorModel>> getAuthors({int? limit, int? offset, String? search});
  Future<AuthorModel> insertAuthor(AuthorModel author);
  Future<AuthorModel> updateAuthor(AuthorModel author);
  Future<void> deleteAuthor(String id);
  Future<List<BookModel>> getBooksByAuthor(String authorId, {int? limit, int? offset});
  Future<List<AuthorModel>> searchAuthors(String query);
  
  // Category operations
  Future<CategoryModel> getCategoryById(String id);
  Future<List<CategoryModel>> getCategories({String? parentId, bool includeChildCategories = true});
  Future<CategoryModel> insertCategory(CategoryModel category);
  Future<CategoryModel> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
  Future<List<BookModel>> getBooksByCategory(String categoryId, {int? limit, int? offset, bool includeSubcategories = false});
  Future<List<CategoryModel>> searchCategories(String query);
  
  // Collection operations
  Future<Collection> getCollectionById(String id);
  Future<List<Collection>> getCollections({int? limit, int? offset, bool publicOnly = false});
  Future<Collection> insertCollection(Collection collection);
  Future<Collection> updateCollection(Collection collection);
  Future<void> deleteCollection(String id);
  Future<void> addBookToCollection(String collectionId, String bookId);
  Future<void> removeBookFromCollection(String collectionId, String bookId);
  Future<List<BookModel>> getBooksInCollection(String collectionId, {int? limit, int? offset});
  
  // Relationship operations
  Future<void> addBookAuthor(String bookId, String authorId, {String role = 'author'});
  Future<void> removeBookAuthor(String bookId, String authorId);
  Future<void> addBookCategory(String bookId, String categoryId);
  Future<void> removeBookCategory(String bookId, String categoryId);
  Future<List<AuthorModel>> getBookAuthors(String bookId);
  Future<List<CategoryModel>> getBookCategories(String bookId);
  
  // File operations
  Future<BookModel> updateBookFilePath(String bookId, String filePath);
  Future<void> updateLastOpened(String bookId);
  Future<int> getTotalStorageUsed();
  Future<List<String>> getOrphanedFiles();
}
