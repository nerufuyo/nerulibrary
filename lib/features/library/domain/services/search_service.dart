import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/search_entities.dart';

/// Abstract search service for local book library search
/// 
/// Provides comprehensive search functionality across book metadata,
/// content, bookmarks, notes, and other library elements.
abstract class SearchService {
  /// Initialize search indexes
  /// 
  /// Sets up FTS (Full Text Search) indexes and prepares the search system.
  /// Should be called during app initialization.
  Future<Either<Failure, void>> initializeSearchIndexes();

  /// Search across the library
  /// 
  /// Performs a comprehensive search across all searchable content
  /// including book metadata, content, bookmarks, and notes.
  Future<Either<Failure, SearchResponse>> search(SearchQuery query);

  /// Search specifically in book metadata
  /// 
  /// Searches only in book titles, authors, descriptions, and other metadata.
  Future<Either<Failure, SearchResponse>> searchMetadata(SearchQuery query);

  /// Search within book content
  /// 
  /// Searches within the actual text content of books.
  Future<Either<Failure, SearchResponse>> searchContent(SearchQuery query);

  /// Search in bookmarks
  /// 
  /// Searches within user bookmarks and their associated notes.
  Future<Either<Failure, SearchResponse>> searchBookmarks(SearchQuery query);

  /// Search in notes and annotations
  /// 
  /// Searches within user-created notes and annotations.
  Future<Either<Failure, SearchResponse>> searchNotes(SearchQuery query);

  /// Get search suggestions
  /// 
  /// Returns search suggestions based on partial query input.
  Future<Either<Failure, List<String>>> getSearchSuggestions(String partialQuery);

  /// Get recent searches
  /// 
  /// Returns the user's recent search queries.
  Future<Either<Failure, List<String>>> getRecentSearches();

  /// Save search query to history
  /// 
  /// Saves a search query to the user's search history.
  Future<Either<Failure, void>> saveSearchToHistory(String query);

  /// Clear search history
  /// 
  /// Removes all saved search queries from history.
  Future<Either<Failure, void>> clearSearchHistory();

  /// Index book content for search
  /// 
  /// Indexes the content of a specific book for searching.
  /// Should be called when a book is added to the library.
  Future<Either<Failure, void>> indexBook({
    required String bookId,
    required String filePath,
    required String format,
  });

  /// Remove book from search index
  /// 
  /// Removes all search indexes related to a specific book.
  /// Should be called when a book is removed from the library.
  Future<Either<Failure, void>> removeBookFromIndex(String bookId);

  /// Update search index for book
  /// 
  /// Updates the search index when book metadata or content changes.
  Future<Either<Failure, void>> updateBookIndex({
    required String bookId,
    Map<String, dynamic>? metadata,
  });

  /// Rebuild all search indexes
  /// 
  /// Completely rebuilds all search indexes from scratch.
  /// Useful for maintenance or after significant database changes.
  Future<Either<Failure, void>> rebuildSearchIndexes();

  /// Get search statistics
  /// 
  /// Returns statistics about the search system such as indexed books count,
  /// index size, and performance metrics.
  Future<Either<Failure, Map<String, dynamic>>> getSearchStatistics();

  /// Optimize search indexes
  /// 
  /// Optimizes search indexes for better performance.
  /// Should be called periodically for maintenance.
  Future<Either<Failure, void>> optimizeSearchIndexes();
}
