import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/project_gutenberg_data_source.dart';
import '../../data/repositories/project_gutenberg_repository_impl.dart';
import '../../domain/entities/api_entities.dart';
import '../../domain/repositories/book_discovery_repository.dart';
import '../../domain/usecases/discovery_usecases.dart';

/// Provider for Dio HTTP client
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  // Configure Dio with default settings
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.sendTimeout = const Duration(seconds: 30);

  // Add request/response interceptors for logging in debug mode
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      requestHeader: false,
      responseHeader: false,
    ));
  }

  return dio;
});

/// Provider for Project Gutenberg data source
final projectGutenbergDataSourceProvider =
    Provider<ProjectGutenbergDataSource>((ref) {
  final dio = ref.read(dioProvider);
  return ProjectGutenbergDataSource(dio: dio);
});

/// Provider for Project Gutenberg repository
final projectGutenbergRepositoryProvider =
    Provider<BookDiscoveryRepository>((ref) {
  final dataSource = ref.read(projectGutenbergDataSourceProvider);
  return ProjectGutenbergRepository(dataSource: dataSource);
});

/// Provider for search books use case
final searchBooksUseCaseProvider = Provider<SearchBooksUseCase>((ref) {
  final repository = ref.read(projectGutenbergRepositoryProvider);
  return SearchBooksUseCase(repository: repository);
});

/// Provider for get book detail use case
final getBookDetailUseCaseProvider = Provider<GetBookDetailUseCase>((ref) {
  final repository = ref.read(projectGutenbergRepositoryProvider);
  return GetBookDetailUseCase(repository: repository);
});

/// Provider for get download info use case
final getDownloadInfoUseCaseProvider = Provider<GetDownloadInfoUseCase>((ref) {
  final repository = ref.read(projectGutenbergRepositoryProvider);
  return GetDownloadInfoUseCase(repository: repository);
});

/// Provider for get popular books use case
final getPopularBooksUseCaseProvider = Provider<GetPopularBooksUseCase>((ref) {
  final repository = ref.read(projectGutenbergRepositoryProvider);
  return GetPopularBooksUseCase(repository: repository);
});

/// Provider for check API status use case
final checkApiStatusUseCaseProvider = Provider<CheckApiStatusUseCase>((ref) {
  final repository = ref.read(projectGutenbergRepositoryProvider);
  return CheckApiStatusUseCase(repository: repository);
});

/// Provider for get books by subject use case
final getBooksBySubjectUseCaseProvider =
    Provider<GetBooksBySubjectUseCase>((ref) {
  final repository = ref.read(projectGutenbergRepositoryProvider);
  return GetBooksBySubjectUseCase(repository: repository);
});

/// State notifier for book search
class BookSearchNotifier extends StateNotifier<AsyncValue<SearchResult?>> {
  final SearchBooksUseCase _searchBooksUseCase;

  BookSearchNotifier(this._searchBooksUseCase)
      : super(const AsyncValue.data(null));

  /// Search books with the given query
  Future<void> searchBooks({
    required String query,
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    // Don't show loading for pagination requests
    if (page == 1) {
      state = const AsyncValue.loading();
    }

    final params = SearchBooksParams(
      query: query,
      page: page,
      limit: limit,
      filters: filters,
    );

    final result = await _searchBooksUseCase(params);

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (searchResult) {
        // For pagination, append results to existing ones
        if (page > 1 && state.value != null) {
          final existingResult = state.value!;
          final combinedBooks = [
            ...existingResult.books,
            ...searchResult.books
          ];
          final updatedResult = searchResult.copyWith(books: combinedBooks);
          state = AsyncValue.data(updatedResult);
        } else {
          state = AsyncValue.data(searchResult);
        }
      },
    );
  }

  /// Clear search results
  void clearResults() {
    state = const AsyncValue.data(null);
  }

  /// Load next page of results
  Future<void> loadNextPage() async {
    final currentResult = state.value;
    if (currentResult != null && currentResult.hasNextPage) {
      await searchBooks(
        query: currentResult.query,
        page: currentResult.currentPage + 1,
        limit: 20,
      );
    }
  }
}

/// Provider for book search state notifier
final bookSearchProvider =
    StateNotifierProvider<BookSearchNotifier, AsyncValue<SearchResult?>>((ref) {
  final searchUseCase = ref.read(searchBooksUseCaseProvider);
  return BookSearchNotifier(searchUseCase);
});

/// State notifier for book details
class BookDetailNotifier extends StateNotifier<AsyncValue<BookDetail?>> {
  final GetBookDetailUseCase _getBookDetailUseCase;

  BookDetailNotifier(this._getBookDetailUseCase)
      : super(const AsyncValue.data(null));

  /// Get book details for the given book ID
  Future<void> getBookDetail(String bookId) async {
    state = const AsyncValue.loading();

    final params = GetBookDetailParams(bookId: bookId);
    final result = await _getBookDetailUseCase(params);

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (bookDetail) => state = AsyncValue.data(bookDetail),
    );
  }

  /// Clear book details
  void clearDetails() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for book detail state notifier
final bookDetailProvider =
    StateNotifierProvider<BookDetailNotifier, AsyncValue<BookDetail?>>((ref) {
  final getDetailUseCase = ref.read(getBookDetailUseCaseProvider);
  return BookDetailNotifier(getDetailUseCase);
});

/// State notifier for popular books
class PopularBooksNotifier extends StateNotifier<AsyncValue<SearchResult?>> {
  final GetPopularBooksUseCase _getPopularBooksUseCase;

  PopularBooksNotifier(this._getPopularBooksUseCase)
      : super(const AsyncValue.data(null));

  /// Load popular books
  Future<void> loadPopularBooks({
    int page = 1,
    int limit = 20,
    String? timeframe,
  }) async {
    if (page == 1) {
      state = const AsyncValue.loading();
    }

    final params = GetPopularBooksParams(
      page: page,
      limit: limit,
      timeframe: timeframe,
    );

    final result = await _getPopularBooksUseCase(params);

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (searchResult) {
        // For pagination, append results to existing ones
        if (page > 1 && state.value != null) {
          final existingResult = state.value!;
          final combinedBooks = [
            ...existingResult.books,
            ...searchResult.books
          ];
          final updatedResult = searchResult.copyWith(books: combinedBooks);
          state = AsyncValue.data(updatedResult);
        } else {
          state = AsyncValue.data(searchResult);
        }
      },
    );
  }

  /// Load next page of popular books
  Future<void> loadNextPage() async {
    final currentResult = state.value;
    if (currentResult != null && currentResult.hasNextPage) {
      await loadPopularBooks(page: currentResult.currentPage + 1);
    }
  }

  /// Refresh popular books
  Future<void> refresh() async {
    await loadPopularBooks(page: 1);
  }
}

/// Provider for popular books state notifier
final popularBooksProvider =
    StateNotifierProvider<PopularBooksNotifier, AsyncValue<SearchResult?>>(
        (ref) {
  final getPopularUseCase = ref.read(getPopularBooksUseCaseProvider);
  return PopularBooksNotifier(getPopularUseCase);
});

/// Provider for API status
final apiStatusProvider = FutureProvider<ApiStatus>((ref) async {
  final checkStatusUseCase = ref.read(checkApiStatusUseCaseProvider);
  final result = await checkStatusUseCase();

  return result.fold(
    (failure) => throw failure,
    (status) => status,
  );
});

/// Provider for download info
final downloadInfoProvider =
    FutureProvider.family<DownloadInfo, GetDownloadInfoParams>(
        (ref, params) async {
  final getDownloadUseCase = ref.read(getDownloadInfoUseCaseProvider);
  final result = await getDownloadUseCase(params);

  return result.fold(
    (failure) => throw failure,
    (downloadInfo) => downloadInfo,
  );
});

/// Provider for books by subject
final booksBySubjectProvider =
    FutureProvider.family<SearchResult, GetBooksBySubjectParams>(
        (ref, params) async {
  final getBySubjectUseCase = ref.read(getBooksBySubjectUseCaseProvider);
  final result = await getBySubjectUseCase(params);

  return result.fold(
    (failure) => throw failure,
    (searchResult) => searchResult,
  );
});

/// State notifier for search query
class SearchQueryNotifier extends StateNotifier<String> {
  SearchQueryNotifier() : super('');

  void updateQuery(String query) {
    state = query;
  }

  void clearQuery() {
    state = '';
  }
}

/// Provider for search query state
final searchQueryProvider =
    StateNotifierProvider<SearchQueryNotifier, String>((ref) {
  return SearchQueryNotifier();
});

/// State notifier for search filters
class SearchFiltersNotifier extends StateNotifier<Map<String, dynamic>> {
  SearchFiltersNotifier() : super(const {});

  void updateFilter(String key, dynamic value) {
    state = {...state, key: value};
  }

  void removeFilter(String key) {
    final newState = Map<String, dynamic>.from(state);
    newState.remove(key);
    state = newState;
  }

  void clearFilters() {
    state = const {};
  }

  void setFilters(Map<String, dynamic> filters) {
    state = filters;
  }
}

/// Provider for search filters state
final searchFiltersProvider =
    StateNotifierProvider<SearchFiltersNotifier, Map<String, dynamic>>((ref) {
  return SearchFiltersNotifier();
});

/// Provider for checking if app is in debug mode
/// This is used for logging and debug features
final kDebugModeProvider = Provider<bool>((ref) {
  // In a real implementation, this would check the actual debug mode
  // For now, we'll assume it's always true during development
  return true;
});

/// Extension to add debug mode constant
/// This is a workaround since we can't import foundation directly
const bool kDebugMode = true;
