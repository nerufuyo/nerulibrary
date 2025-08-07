import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/search_entities.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/services/search_service.dart';

/// Implementation of the search repository
/// 
/// Coordinates search operations across different services and
/// provides a unified interface for search functionality.
class SearchRepositoryImpl implements SearchRepository {
  /// Search service for database operations
  final SearchService _searchService;

  const SearchRepositoryImpl({
    required SearchService searchService,
  }) : _searchService = searchService;

  @override
  Future<Either<Failure, SearchResponse>> search(SearchQuery query) async {
    return await _searchService.search(query);
  }

  @override
  Future<Either<Failure, SearchResponse>> searchMetadata(SearchQuery query) async {
    return await _searchService.searchMetadata(query);
  }

  @override
  Future<Either<Failure, SearchResponse>> searchContent(SearchQuery query) async {
    return await _searchService.searchContent(query);
  }

  @override
  Future<Either<Failure, SearchResponse>> searchBookmarks(SearchQuery query) async {
    return await _searchService.searchBookmarks(query);
  }

  @override
  Future<Either<Failure, SearchResponse>> searchNotes(SearchQuery query) async {
    return await _searchService.searchNotes(query);
  }

  @override
  Future<Either<Failure, List<String>>> getSearchSuggestions(String partialQuery) async {
    return await _searchService.getSearchSuggestions(partialQuery);
  }

  @override
  Future<Either<Failure, List<String>>> getRecentSearches() async {
    return await _searchService.getRecentSearches();
  }

  @override
  Future<Either<Failure, void>> saveSearchToHistory(String query) async {
    return await _searchService.saveSearchToHistory(query);
  }

  @override
  Future<Either<Failure, void>> clearSearchHistory() async {
    return await _searchService.clearSearchHistory();
  }

  @override
  Future<Either<Failure, void>> initializeSearch() async {
    return await _searchService.initializeSearchIndexes();
  }

  @override
  Future<Either<Failure, void>> indexBook({
    required String bookId,
    required String filePath,
    required String format,
  }) async {
    return await _searchService.indexBook(
      bookId: bookId,
      filePath: filePath,
      format: format,
    );
  }

  @override
  Future<Either<Failure, void>> removeBookFromIndex(String bookId) async {
    return await _searchService.removeBookFromIndex(bookId);
  }

  @override
  Future<Either<Failure, void>> updateBookIndex({
    required String bookId,
    Map<String, dynamic>? metadata,
  }) async {
    return await _searchService.updateBookIndex(
      bookId: bookId,
      metadata: metadata,
    );
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSearchMetrics() async {
    return await _searchService.getSearchStatistics();
  }

  @override
  Future<Either<Failure, void>> optimizeSearch() async {
    return await _searchService.optimizeSearchIndexes();
  }
}
