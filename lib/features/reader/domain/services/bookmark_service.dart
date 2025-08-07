import 'package:dartz/dartz.dart';

import '../entities/bookmark.dart';
import '../entities/reading_position.dart';
import '../failures/reader_failures.dart';

/// Service interface for bookmark and reading tools management
/// 
/// Provides methods for creating, managing, and syncing bookmarks,
/// highlights, notes, and reading progress across different book formats.
abstract class BookmarkService {
  /// Create a new bookmark
  Future<Either<ReaderFailure, Bookmark>> createBookmark({
    required String bookId,
    required BookmarkType type,
    required BookmarkLocation location,
    String? title,
    String? description,
  });

  /// Get all bookmarks for a book
  Future<Either<ReaderFailure, List<Bookmark>>> getBookmarksByBook(String bookId);

  /// Update an existing bookmark
  Future<Either<ReaderFailure, Bookmark>> updateBookmark(Bookmark bookmark);

  /// Delete a bookmark
  Future<Either<ReaderFailure, bool>> deleteBookmark(String bookmarkId);

  /// Save reading position
  Future<Either<ReaderFailure, bool>> saveReadingPosition({
    required String bookId,
    required ReadingPosition position,
  });

  /// Load reading position
  Future<Either<ReaderFailure, ReadingPosition?>> loadReadingPosition(String bookId);

  /// Stream of bookmark updates
  Stream<List<Bookmark>> getBookmarksStream(String bookId);
}
