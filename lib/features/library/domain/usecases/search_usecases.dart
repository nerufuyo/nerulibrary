import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/search_entities.dart';
import '../repositories/search_repository.dart';

/// Use case for performing search operations
class SearchBooksUseCase {
  final SearchRepository _repository;

  const SearchBooksUseCase(this._repository);

  /// Execute search with the given query
  Future<Either<Failure, SearchResponse>> call(SearchQuery query) async {
    return await _repository.search(query);
  }
}

/// Use case for searching specifically in book metadata
class SearchMetadataUseCase {
  final SearchRepository _repository;

  const SearchMetadataUseCase(this._repository);

  /// Execute metadata search
  Future<Either<Failure, SearchResponse>> call(SearchQuery query) async {
    return await _repository.searchMetadata(query);
  }
}

/// Use case for searching in book content
class SearchContentUseCase {
  final SearchRepository _repository;

  const SearchContentUseCase(this._repository);

  /// Execute content search
  Future<Either<Failure, SearchResponse>> call(SearchQuery query) async {
    return await _repository.searchContent(query);
  }
}

/// Use case for searching in bookmarks
class SearchBookmarksUseCase {
  final SearchRepository _repository;

  const SearchBookmarksUseCase(this._repository);

  /// Execute bookmark search
  Future<Either<Failure, SearchResponse>> call(SearchQuery query) async {
    return await _repository.searchBookmarks(query);
  }
}

/// Use case for searching in notes
class SearchNotesUseCase {
  final SearchRepository _repository;

  const SearchNotesUseCase(this._repository);

  /// Execute notes search
  Future<Either<Failure, SearchResponse>> call(SearchQuery query) async {
    return await _repository.searchNotes(query);
  }
}

/// Use case for getting search suggestions
class GetSearchSuggestionsUseCase {
  final SearchRepository _repository;

  const GetSearchSuggestionsUseCase(this._repository);

  /// Get search suggestions for partial query
  Future<Either<Failure, List<String>>> call(String partialQuery) async {
    return await _repository.getSearchSuggestions(partialQuery);
  }
}

/// Use case for managing search history
class SearchHistoryUseCase {
  final SearchRepository _repository;

  const SearchHistoryUseCase(this._repository);

  /// Get recent searches
  Future<Either<Failure, List<String>>> getRecentSearches() async {
    return await _repository.getRecentSearches();
  }

  /// Save search to history
  Future<Either<Failure, void>> saveSearch(String query) async {
    return await _repository.saveSearchToHistory(query);
  }

  /// Clear search history
  Future<Either<Failure, void>> clearHistory() async {
    return await _repository.clearSearchHistory();
  }
}

/// Use case for search system management
class SearchManagementUseCase {
  final SearchRepository _repository;

  const SearchManagementUseCase(this._repository);

  /// Initialize search system
  Future<Either<Failure, void>> initializeSearch() async {
    return await _repository.initializeSearch();
  }

  /// Index a book for searching
  Future<Either<Failure, void>> indexBook({
    required String bookId,
    required String filePath,
    required String format,
  }) async {
    return await _repository.indexBook(
      bookId: bookId,
      filePath: filePath,
      format: format,
    );
  }

  /// Remove book from search index
  Future<Either<Failure, void>> removeBookFromIndex(String bookId) async {
    return await _repository.removeBookFromIndex(bookId);
  }

  /// Update book index
  Future<Either<Failure, void>> updateBookIndex({
    required String bookId,
    Map<String, dynamic>? metadata,
  }) async {
    return await _repository.updateBookIndex(
      bookId: bookId,
      metadata: metadata,
    );
  }

  /// Get search metrics
  Future<Either<Failure, Map<String, dynamic>>> getSearchMetrics() async {
    return await _repository.getSearchMetrics();
  }

  /// Optimize search performance
  Future<Either<Failure, void>> optimizeSearch() async {
    return await _repository.optimizeSearch();
  }
}
