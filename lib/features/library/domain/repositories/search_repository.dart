import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/search_entities.dart';

/// Repository interface for search functionality
/// 
/// Provides high-level search operations and coordinates between
/// different search data sources and services.
abstract class SearchRepository {
  /// Perform a comprehensive search across all library content
  /// 
  /// This is the main search method that coordinates searches across
  /// multiple data sources and returns unified results.
  Future<Either<Failure, SearchResponse>> search(SearchQuery query);

  /// Search specifically in book metadata
  /// 
  /// Returns results from book titles, authors, descriptions, etc.
  Future<Either<Failure, SearchResponse>> searchMetadata(SearchQuery query);

  /// Search within book content (full text search)
  /// 
  /// Returns results from within the actual content of books.
  Future<Either<Failure, SearchResponse>> searchContent(SearchQuery query);

  /// Search in user bookmarks
  /// 
  /// Returns results from user's saved bookmarks and associated notes.
  Future<Either<Failure, SearchResponse>> searchBookmarks(SearchQuery query);

  /// Search in user notes and annotations
  /// 
  /// Returns results from user-created notes and annotations.
  Future<Either<Failure, SearchResponse>> searchNotes(SearchQuery query);

  /// Get autocomplete suggestions for search
  /// 
  /// Returns suggested search terms based on partial input.
  Future<Either<Failure, List<String>>> getSearchSuggestions(String partialQuery);

  /// Get user's recent search queries
  /// 
  /// Returns a list of recently performed searches.
  Future<Either<Failure, List<String>>> getRecentSearches();

  /// Save a search query to history
  /// 
  /// Stores a search query in the user's search history.
  Future<Either<Failure, void>> saveSearchToHistory(String query);

  /// Clear the search history
  /// 
  /// Removes all entries from the user's search history.
  Future<Either<Failure, void>> clearSearchHistory();

  /// Initialize search system
  /// 
  /// Sets up search indexes and prepares the search functionality.
  Future<Either<Failure, void>> initializeSearch();

  /// Index a book for searching
  /// 
  /// Adds a book's content and metadata to the search index.
  Future<Either<Failure, void>> indexBook({
    required String bookId,
    required String filePath,
    required String format,
  });

  /// Remove a book from search indexes
  /// 
  /// Removes all search data related to a specific book.
  Future<Either<Failure, void>> removeBookFromIndex(String bookId);

  /// Update search index for a book
  /// 
  /// Updates the search data when book information changes.
  Future<Either<Failure, void>> updateBookIndex({
    required String bookId,
    Map<String, dynamic>? metadata,
  });

  /// Get search performance metrics
  /// 
  /// Returns statistics about search performance and index status.
  Future<Either<Failure, Map<String, dynamic>>> getSearchMetrics();

  /// Optimize search performance
  /// 
  /// Performs maintenance operations to improve search speed.
  Future<Either<Failure, void>> optimizeSearch();
}
