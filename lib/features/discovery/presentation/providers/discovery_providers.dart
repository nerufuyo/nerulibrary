import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/api_entities.dart';

/// Search query notifier for managing search state
class SearchQueryNotifier extends StateNotifier<String> {
  SearchQueryNotifier() : super('');

  void updateQuery(String query) {
    state = query;
  }

  void clearQuery() {
    state = '';
  }
}

/// Book search provider notifier
class BookSearchNotifier extends AsyncNotifier<SearchResult?> {
  @override
  Future<SearchResult?> build() async {
    return null; // Initially no search results
  }

  Future<void> searchBooks({required String query}) async {
    if (query.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock search results using proper types
      final books = List.generate(10, (index) => BookSearchItem(
        id: 'book_${query}_$index',
        title: 'Sample Book $index for "$query"',
        authors: ['Author $index'],
        subjects: ['Subject $index'],
        coverUrl: null,
        availableFormats: const [BookFormat.epub, BookFormat.pdf],
        downloadCount: index * 10,
        apiProvider: 'Mock API',
        metadata: {'source': 'mock'},
      ));
      
      final result = SearchResult(
        books: books,
        totalCount: 50,
        currentPage: 1,
        totalPages: 5,
        query: query,
        apiProvider: 'Mock API',
        searchTime: DateTime.now(),
      );
      
      state = AsyncValue.data(result);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || !current.hasNextPage) return;

    try {
      // Simulate loading more results
      await Future.delayed(const Duration(milliseconds: 300));
      
      final newBooks = List.generate(10, (index) => BookSearchItem(
        id: 'book_next_$index',
        title: 'Next Page Book $index',
        authors: ['Author ${current.books.length + index}'],
        subjects: ['Subject ${current.books.length + index}'],
        coverUrl: null,
        availableFormats: const [BookFormat.epub, BookFormat.pdf],
        downloadCount: (current.books.length + index) * 10,
        apiProvider: 'Mock API',
        metadata: {'source': 'mock'},
      ));
      
      final updatedResult = SearchResult(
        books: [...current.books, ...newBooks],
        totalCount: current.totalCount,
        currentPage: current.currentPage + 1,
        totalPages: current.totalPages,
        query: current.query,
        apiProvider: current.apiProvider,
        searchTime: current.searchTime,
      );
      
      state = AsyncValue.data(updatedResult);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  void clearResults() {
    state = const AsyncValue.data(null);
  }
}

/// Popular books provider notifier
class PopularBooksNotifier extends AsyncNotifier<SearchResult?> {
  @override
  Future<SearchResult?> build() async {
    return await loadPopularBooks();
  }

  Future<SearchResult?> loadPopularBooks() async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Mock popular books using proper types
      final books = List.generate(15, (index) => BookSearchItem(
        id: 'popular_$index',
        title: 'Popular Book ${index + 1}',
        authors: ['Popular Author ${index + 1}'],
        subjects: ['Popular Subject ${index + 1}'],
        coverUrl: null,
        availableFormats: const [BookFormat.epub, BookFormat.pdf],
        downloadCount: (15 - index) * 100,
        apiProvider: 'Mock API',
        metadata: {'source': 'popular'},
      ));
      
      return SearchResult(
        books: books,
        totalCount: 30,
        currentPage: 1,
        totalPages: 2,
        query: 'popular',
        apiProvider: 'Mock API',
        searchTime: DateTime.now(),
      );
    } catch (error) {
      throw Exception('Failed to load popular books: $error');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final result = await loadPopularBooks();
      state = AsyncValue.data(result);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || !current.hasNextPage) return;

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final newBooks = List.generate(10, (index) => BookSearchItem(
        id: 'popular_next_$index',
        title: 'Popular Next ${current.books.length + index + 1}',
        authors: ['Popular Author ${current.books.length + index + 1}'],
        subjects: ['Popular Subject ${current.books.length + index + 1}'],
        coverUrl: null,
        availableFormats: const [BookFormat.epub, BookFormat.pdf],
        downloadCount: (current.books.length + index + 1) * 50,
        apiProvider: 'Mock API',
        metadata: {'source': 'popular'},
      ));
      
      final updatedResult = SearchResult(
        books: [...current.books, ...newBooks],
        totalCount: current.totalCount,
        currentPage: current.currentPage + 1,
        totalPages: current.totalPages,
        query: current.query,
        apiProvider: current.apiProvider,
        searchTime: current.searchTime,
      );
      
      state = AsyncValue.data(updatedResult);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
}

/// API status provider notifier
class ApiStatusNotifier extends AsyncNotifier<ApiStatus> {
  @override
  Future<ApiStatus> build() async {
    return await checkApiStatus();
  }

  Future<ApiStatus> checkApiStatus() async {
    try {
      // Simulate API status check delay
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Create mock API status using proper type
      return ApiStatus(
        provider: 'Mock API Service',
        isAvailable: true,
        responseTime: const Duration(milliseconds: 120),
        errorMessage: null,
        version: '1.0.0',
        checkedAt: DateTime.now(),
      );
    } catch (error) {
      throw Exception('Failed to check API status: $error');
    }
  }
}

/// Provider instances
final searchQueryProvider = StateNotifierProvider<SearchQueryNotifier, String>(
  (ref) => SearchQueryNotifier(),
);

final bookSearchProvider = AsyncNotifierProvider<BookSearchNotifier, SearchResult?>(
  () => BookSearchNotifier(),
);

final popularBooksProvider = AsyncNotifierProvider<PopularBooksNotifier, SearchResult?>(
  () => PopularBooksNotifier(),
);

final apiStatusProvider = AsyncNotifierProvider<ApiStatusNotifier, ApiStatus>(
  () => ApiStatusNotifier(),
);
