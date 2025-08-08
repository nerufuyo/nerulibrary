import 'package:dartz/dartz.dart';

import '../../domain/entities/api_entities.dart';
import '../../domain/failures/api_failures.dart';
import '../../domain/repositories/book_discovery_repository.dart';
import '../datasources/openlibrary_data_source.dart';

/// Repository implementation for OpenLibrary API
/// 
/// Provides book discovery capabilities using OpenLibrary's extensive database.
/// Implements caching, rate limiting, and comprehensive error handling.
class OpenLibraryRepository implements BookDiscoveryRepository, CacheableRepository {
  final OpenLibraryDataSource _dataSource;
  
  // Cache for storing recent results
  final Map<String, CachedResult<SearchResult>> _searchCache = {};
  final Map<String, CachedResult<BookDetail>> _detailCache = {};
  final Map<String, CachedResult<BookAuthor>> _authorCache = {};
  
  static const Duration _cacheTimeout = Duration(minutes: 10);

  OpenLibraryRepository({
    required OpenLibraryDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  String get baseUrl => 'https://openlibrary.org';

  @override
  String get providerName => 'OpenLibrary';

  @override
  bool supportsFeature(ApiFeature feature) {
    switch (feature) {
      case ApiFeature.fullTextSearch:
        return false; // OpenLibrary doesn't support full-text search
      case ApiFeature.advancedFilters:
        return true;
      case ApiFeature.authorDetails:
        return true;
      case ApiFeature.ratingsAndReviews:
        return true;
      case ApiFeature.downloadStats:
        return false; // OpenLibrary doesn't provide download stats
      case ApiFeature.multipleFormats:
        return false; // OpenLibrary doesn't provide direct downloads
      case ApiFeature.coverImages:
        return true;
      case ApiFeature.subjectBrowsing:
        return true;
      case ApiFeature.languageFiltering:
        return true;
      case ApiFeature.recentContent:
        return false;
      case ApiFeature.popularContent:
        return true;
      case ApiFeature.searchSuggestions:
        return false;
      case ApiFeature.pagination:
        return true;
      case ApiFeature.rateLimitInfo:
        return true;
    }
  }

  @override
  Future<Either<ApiFailure, SearchResult>> searchBooks({
    required String query,
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    final cacheKey = _buildCacheKey('search', {
      'query': query,
      'page': page.toString(),
      'limit': limit.toString(),
      'filters': filters?.toString() ?? '',
    });

    // Try to get cached result
    final cachedResult = _getCachedSearchResult(cacheKey);
    if (cachedResult != null) {
      return Right(cachedResult);
    }

    try {
      // Validate input parameters
      if (query.trim().isEmpty) {
        return const Left(ValidationApiFailure(
          message: 'Search query cannot be empty',
          validationErrors: ['empty_query'],
        ));
      }

      if (page < 1) {
        return const Left(ValidationApiFailure(
          message: 'Page number must be positive',
          validationErrors: ['invalid_page'],
        ));
      }

      if (limit < 1 || limit > 100) {
        return const Left(ValidationApiFailure(
          message: 'Limit must be between 1 and 100',
          validationErrors: ['invalid_limit'],
        ));
      }

      // Perform search
      final result = await _dataSource.searchBooks(
        query: query,
        page: page,
        limit: limit,
      );

      // Cache the result
      _cacheSearchResult(cacheKey, result);

      return Right(result);

    } on ApiFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(UnknownApiFailure(
        message: 'Unexpected error during search: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<ApiFailure, BookDetail>> getBookDetail(String bookId) async {
    final cacheKey = _buildCacheKey('book_detail', {'id': bookId});

    // Try to get cached result
    final cachedResult = _getCachedBookDetail(cacheKey);
    if (cachedResult != null) {
      return Right(cachedResult);
    }

    try {
      // Validate book ID
      if (bookId.trim().isEmpty) {
        return const Left(ValidationApiFailure(
          message: 'Book ID cannot be empty',
          validationErrors: ['empty_book_id'],
        ));
      }

      // Get book detail from OpenLibrary
      final result = await _dataSource.getWorkDetail(bookId);

      // Cache the result
      _cacheBookDetail(cacheKey, result);

      return Right(result);

    } on ApiFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(UnknownApiFailure(
        message: 'Unexpected error getting book detail: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<ApiFailure, DownloadInfo>> getDownloadUrl({
    required String bookId,
    required BookFormat format,
  }) async {
    // OpenLibrary doesn't provide direct downloads
    return const Left(ServiceUnavailableApiFailure(
      message: 'OpenLibrary does not provide direct book downloads',
      apiProvider: 'OpenLibrary',
    ));
  }

  @override
  Future<Either<ApiFailure, ApiStatus>> checkApiStatus() async {
    try {
      final statusData = await _dataSource.checkApiStatus();
      
      final status = ApiStatus(
        provider: 'OpenLibrary',
        isAvailable: statusData['status'] == 'available',
        responseTime: Duration(
          milliseconds: statusData['response_time_ms'] ?? 0,
        ),
        errorMessage: statusData['error'],
        rateLimitRemaining: statusData['rate_limit_remaining'],
        rateLimitReset: statusData['rate_limit_reset_in_seconds'] != null
            ? Duration(seconds: statusData['rate_limit_reset_in_seconds'])
            : null,
        version: '1.0',
        checkedAt: DateTime.parse(statusData['last_checked']),
      );

      return Right(status);

    } catch (e) {
      return Left(UnknownApiFailure(
        message: 'Failed to check API status: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<ApiFailure, BookAuthor>> getAuthorDetail(String authorId) async {
    final cacheKey = _buildCacheKey('author', {'id': authorId});

    // Try to get cached result
    final cachedResult = _getCachedAuthor(cacheKey);
    if (cachedResult != null) {
      return Right(cachedResult);
    }

    try {
      if (authorId.trim().isEmpty) {
        return const Left(ValidationApiFailure(
          message: 'Author ID cannot be empty',
          validationErrors: ['empty_author_id'],
        ));
      }

      final authorData = await _dataSource.getAuthorDetail(authorId);
      
      final author = BookAuthor(
        id: authorId,
        name: authorData['name']?.toString() ?? 'Unknown Author',
        birthDate: _parseDate(authorData['birth_date']),
        deathDate: _parseDate(authorData['death_date']),
        biography: authorData['bio'] is Map 
            ? (authorData['bio'] as Map)['value']?.toString()
            : authorData['bio']?.toString(),
        aliases: (authorData['alternate_names'] as List<dynamic>?)
            ?.map((name) => name.toString())
            .toList() ?? [],
        wikipediaUrl: authorData['wikipedia']?.toString(),
        metadata: {
          'openlibrary_key': authorData['key'],
          'type': authorData['type'],
          'photos': authorData['photos'],
          'links': authorData['links'],
        },
      );

      _cacheAuthor(cacheKey, author);
      return Right(author);

    } on ApiFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(UnknownApiFailure(
        message: 'Unexpected error getting author detail: $e',
        originalError: e,
      ));
    }
  }

  // Simplified implementations for required methods
  @override
  Future<Either<ApiFailure, SearchResult>> getBooksByAuthor({
    required String authorId,
    int page = 1,
    int limit = 20,
  }) async {
    return searchBooks(
      query: 'author:$authorId',
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Either<ApiFailure, SearchResult>> getBooksBySubject({
    required String subject,
    int page = 1,
    int limit = 20,
  }) async {
    return searchBooks(
      query: 'subject:"$subject"',
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Either<ApiFailure, SearchResult>> getPopularBooks({
    int page = 1,
    int limit = 20,
    String? timeframe,
  }) async {
    final cacheKey = _buildCacheKey('popular', {
      'page': page.toString(),
      'limit': limit.toString(),
      'timeframe': timeframe ?? '',
    });

    final cached = _getCachedSearchResult(cacheKey);
    if (cached != null) {
      return Right(cached);
    }

    try {
      final result = await _dataSource.getTrendingBooks(limit: limit);
      _cacheSearchResult(cacheKey, result);
      return Right(result);
    } on ApiFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(UnknownApiFailure(
        message: 'Unexpected error getting popular books: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<ApiFailure, SearchResult>> getRecentBooks({
    int page = 1,
    int limit = 20,
    int? days,
  }) async {
    // OpenLibrary doesn't have a dedicated recent books endpoint
    return const Left(ServiceUnavailableApiFailure(
      message: 'Recent books not available from OpenLibrary',
      apiProvider: 'OpenLibrary',
    ));
  }

  @override
  Future<Either<ApiFailure, List<String>>> getAvailableSubjects() async {
    // Return common OpenLibrary subjects
    return const Right([
      'Fiction',
      'History', 
      'Biography & Autobiography',
      'Science',
      'Philosophy',
      'Psychology',
      'Business & Economics',
      'Computers',
      'Education',
      'Health & Fitness',
      'Language Arts & Disciplines',
      'Literary Criticism',
      'Mathematics',
      'Medical',
      'Nature',
      'Political Science',
      'Religion',
      'Self-Help',
      'Technology & Engineering',
      'Travel',
    ]);
  }

  @override
  Future<Either<ApiFailure, List<String>>> getAvailableLanguages() async {
    // Return common languages supported by OpenLibrary
    return const Right([
      'en', // English
      'es', // Spanish
      'fr', // French
      'de', // German
      'it', // Italian
      'pt', // Portuguese
      'ru', // Russian
      'zh', // Chinese
      'ja', // Japanese
      'ar', // Arabic
      'hi', // Hindi
      'ko', // Korean
      'nl', // Dutch
      'sv', // Swedish
      'da', // Danish
      'no', // Norwegian
      'fi', // Finnish
      'pl', // Polish
      'cs', // Czech
      'hu', // Hungarian
    ]);
  }

  @override
  Future<Either<ApiFailure, List<String>>> getSearchSuggestions({
    required String partial,
    int limit = 10,
  }) async {
    // OpenLibrary doesn't provide search suggestions
    return const Left(ServiceUnavailableApiFailure(
      message: 'Search suggestions not available from OpenLibrary',
      apiProvider: 'OpenLibrary',
    ));
  }

  // CacheableRepository implementation
  @override
  Future<void> clearCache() async {
    _searchCache.clear();
    _detailCache.clear();
    _authorCache.clear();
  }

  @override
  Future<void> clearExpiredCache(Duration maxAge) async {
    final now = DateTime.now();
    _searchCache.removeWhere((key, value) => 
        now.difference(value.cachedAt) > maxAge);
    _detailCache.removeWhere((key, value) => 
        now.difference(value.cachedAt) > maxAge);
    _authorCache.removeWhere((key, value) => 
        now.difference(value.cachedAt) > maxAge);
  }

  @override
  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'searchCacheSize': _searchCache.length,
      'detailCacheSize': _detailCache.length,
      'authorCacheSize': _authorCache.length,
      'totalCacheSize': _searchCache.length + _detailCache.length + _authorCache.length,
      'cacheTimeout': _cacheTimeout.toString(),
    };
  }

  @override
  Future<void> warmUpCache() async {
    // Pre-load popular content
    try {
      await getPopularBooks(limit: 10);
    } catch (e) {
      // Ignore warm-up errors
    }
  }

  // Private helper methods
  SearchResult? _getCachedSearchResult(String key) {
    final cached = _searchCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _cacheTimeout) {
      return cached.data;
    }
    return null;
  }

  BookDetail? _getCachedBookDetail(String key) {
    final cached = _detailCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _cacheTimeout) {
      return cached.data;
    }
    return null;
  }

  BookAuthor? _getCachedAuthor(String key) {
    final cached = _authorCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _cacheTimeout) {
      return cached.data;
    }
    return null;
  }

  void _cacheSearchResult(String key, SearchResult result) {
    _searchCache[key] = CachedResult(data: result, cachedAt: DateTime.now());
  }

  void _cacheBookDetail(String key, BookDetail detail) {
    _detailCache[key] = CachedResult(data: detail, cachedAt: DateTime.now());
  }

  void _cacheAuthor(String key, BookAuthor author) {
    _authorCache[key] = CachedResult(data: author, cachedAt: DateTime.now());
  }

  /// Build cache key for consistent caching
  String _buildCacheKey(String operation, Map<String, String> params) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final paramString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return 'openlibrary_${operation}_$paramString';
  }

  /// Parse date string to DateTime
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      final dateStr = dateValue.toString();
      
      // Try various date formats used by OpenLibrary
      if (RegExp(r'^\d{4}$').hasMatch(dateStr)) {
        return DateTime(int.parse(dateStr));
      }
      
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
        return DateTime.parse(dateStr);
      }
      
      // Handle other date formats as needed
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Helper class for caching results
class CachedResult<T> {
  final T data;
  final DateTime cachedAt;

  CachedResult({
    required this.data,
    required this.cachedAt,
  });
}
