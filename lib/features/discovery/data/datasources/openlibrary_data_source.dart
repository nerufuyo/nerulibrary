import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/api_entities.dart';
import '../../domain/failures/api_failures.dart';

/// OpenLibrary API data source for book discovery
///
/// Provides access to OpenLibrary's extensive book database with
/// comprehensive metadata, author information, and cover images.
/// Implements rate limiting of 100 requests per minute as per API guidelines.
abstract class OpenLibraryDataSource {
  /// Search for books using OpenLibrary's search API
  ///
  /// [query] - Search terms (title, author, ISBN, etc.)
  /// [page] - Page number for pagination (1-based)
  /// [limit] - Number of results per page (max 100)
  ///
  /// Returns [SearchResult] with book listings and metadata
  Future<SearchResult> searchBooks({
    required String query,
    int page = 1,
    int limit = 20,
  });

  /// Get detailed information about a specific work
  ///
  /// [workId] - OpenLibrary work identifier (e.g., "OL82563W")
  ///
  /// Returns [BookDetail] with comprehensive book information
  Future<BookDetail> getWorkDetail(String workId);

  /// Get book information by ISBN or other identifiers
  ///
  /// [identifiers] - List of book identifiers (ISBN, OCLC, etc.)
  ///
  /// Returns [List<BookDetail>] with book details
  Future<List<BookDetail>> getBooksByIdentifiers(List<String> identifiers);

  /// Get author information
  ///
  /// [authorId] - OpenLibrary author identifier (e.g., "OL23919A")
  ///
  /// Returns author details as Map
  Future<Map<String, dynamic>> getAuthorDetail(String authorId);

  /// Get book cover image URLs
  ///
  /// [coverId] - OpenLibrary cover identifier
  /// [size] - Cover size ('S', 'M', 'L')
  ///
  /// Returns cover image URL
  Future<String?> getCoverImageUrl(String coverId, {String size = 'M'});

  /// Get trending/popular books
  ///
  /// [subject] - Optional subject filter
  /// [limit] - Number of results (max 50)
  ///
  /// Returns [SearchResult] with popular books
  Future<SearchResult> getTrendingBooks({
    String? subject,
    int limit = 20,
  });

  /// Check API status and rate limits
  Future<Map<String, dynamic>> checkApiStatus();
}

/// Implementation of OpenLibrary data source
class OpenLibraryDataSourceImpl implements OpenLibraryDataSource {
  final DioClient _dioClient;

  // API Configuration
  static const String _baseUrl = 'https://openlibrary.org';
  static const String _coversBaseUrl = 'https://covers.openlibrary.org/b';
  static const Duration _requestTimeout = Duration(seconds: 30);

  // Rate limiting: 100 requests per minute
  static const int _maxRequestsPerMinute = 100;
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  // Rate limiting tracking
  final List<DateTime> _requestTimestamps = [];

  OpenLibraryDataSourceImpl({
    required DioClient dioClient,
  }) : _dioClient = dioClient;

  @override
  Future<SearchResult> searchBooks({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    await _enforceRateLimit();

    try {
      // Validate parameters
      if (query.trim().isEmpty) {
        throw const ValidationApiFailure(
          message: 'Search query cannot be empty',
          validationErrors: ['query_empty'],
        );
      }

      if (limit < 1 || limit > 100) {
        throw const ValidationApiFailure(
          message: 'Limit must be between 1 and 100',
          validationErrors: ['invalid_limit'],
        );
      }

      if (page < 1) {
        throw const ValidationApiFailure(
          message: 'Page must be greater than 0',
          validationErrors: ['invalid_page'],
        );
      }

      // Calculate offset for pagination
      final offset = (page - 1) * limit;

      final response = await _dioClient.get(
        '$_baseUrl/search.json',
        queryParameters: {
          'q': query.trim(),
          'limit': limit,
          'offset': offset,
          'fields': [
            'key',
            'title',
            'author_name',
            'author_key',
            'first_publish_year',
            'isbn',
            'cover_i',
            'subject',
            'publisher',
            'language',
            'number_of_pages_median',
            'ratings_average',
            'ratings_count',
            'want_to_read_count',
            'currently_reading_count',
            'already_read_count',
          ].join(','),
        },
        options: Options(
          receiveTimeout: _requestTimeout,
          sendTimeout: _requestTimeout,
        ),
      );

      _trackRequest();

      if (response.statusCode != 200) {
        throw HttpApiFailure(
          message: 'OpenLibrary search failed',
          statusCode: response.statusCode ?? 0,
        );
      }

      final data = response.data as Map<String, dynamic>;

      // Validate response structure
      if (!data.containsKey('docs') || !data.containsKey('numFound')) {
        throw const ParseApiFailure(
          message: 'Invalid search response format',
          originalData: 'Missing docs or numFound fields',
        );
      }

      return _parseSearchResponse(data, query, page, limit);
    } on DioException catch (e) {
      throw _handleDioException(e, 'search books');
    } catch (e) {
      if (e is ApiFailure) rethrow;
      throw UnknownApiFailure(
        message: 'Unexpected error during book search: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<BookDetail> getWorkDetail(String workId) async {
    await _enforceRateLimit();

    try {
      // Validate work ID format
      if (workId.trim().isEmpty) {
        throw const ValidationApiFailure(
          message: 'Work ID cannot be empty',
          validationErrors: ['work_id_empty'],
        );
      }

      if (!workId.startsWith('OL') || !workId.endsWith('W')) {
        throw const ValidationApiFailure(
          message: 'Invalid OpenLibrary work ID format',
          validationErrors: ['invalid_work_id_format'],
        );
      }

      final response = await _dioClient.get(
        '$_baseUrl/works/$workId.json',
        options: Options(
          receiveTimeout: _requestTimeout,
          sendTimeout: _requestTimeout,
        ),
      );

      _trackRequest();

      if (response.statusCode == 404) {
        throw BookNotFoundApiFailure(
          message: 'Work not found',
          bookId: workId,
          apiProvider: 'OpenLibrary',
        );
      }

      if (response.statusCode != 200) {
        throw HttpApiFailure(
          message: 'Failed to get work detail',
          statusCode: response.statusCode ?? 0,
        );
      }

      final data = response.data as Map<String, dynamic>;

      // Get additional edition information
      final editionsResponse = await _dioClient.get(
        '$_baseUrl/works/$workId/editions.json',
        queryParameters: {'limit': 10},
        options: Options(
          receiveTimeout: _requestTimeout,
          sendTimeout: _requestTimeout,
        ),
      );

      _trackRequest();

      Map<String, dynamic>? editionsData;
      if (editionsResponse.statusCode == 200) {
        editionsData = editionsResponse.data as Map<String, dynamic>;
      }

      return _parseWorkDetail(data, editionsData);
    } on DioException catch (e) {
      throw _handleDioException(e, 'get work detail');
    } catch (e) {
      if (e is ApiFailure) rethrow;
      throw UnknownApiFailure(
        message: 'Unexpected error getting work detail: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<List<BookDetail>> getBooksByIdentifiers(
      List<String> identifiers) async {
    await _enforceRateLimit();

    try {
      if (identifiers.isEmpty) {
        throw const ValidationApiFailure(
          message: 'Identifiers list cannot be empty',
          validationErrors: ['identifiers_empty'],
        );
      }

      if (identifiers.length > 100) {
        throw const ValidationApiFailure(
          message: 'Too many identifiers (max 100)',
          validationErrors: ['too_many_identifiers'],
        );
      }

      // Clean and validate identifiers
      final cleanIdentifiers = identifiers
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .take(100)
          .toList();

      if (cleanIdentifiers.isEmpty) {
        throw const ValidationApiFailure(
          message: 'No valid identifiers provided',
          validationErrors: ['no_valid_identifiers'],
        );
      }

      final bibkeys = cleanIdentifiers.join(',');

      final response = await _dioClient.get(
        '$_baseUrl/api/books',
        queryParameters: {
          'bibkeys': bibkeys,
          'format': 'json',
          'jscmd': 'data',
        },
        options: Options(
          receiveTimeout: _requestTimeout,
          sendTimeout: _requestTimeout,
        ),
      );

      _trackRequest();

      if (response.statusCode != 200) {
        throw HttpApiFailure(
          message: 'Failed to get books by identifiers',
          statusCode: response.statusCode ?? 0,
        );
      }

      final data = response.data as Map<String, dynamic>;
      return _parseBooksByIdentifiers(data);
    } on DioException catch (e) {
      throw _handleDioException(e, 'get books by identifiers');
    } catch (e) {
      if (e is ApiFailure) rethrow;
      throw UnknownApiFailure(
        message: 'Unexpected error getting books by identifiers: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getAuthorDetail(String authorId) async {
    await _enforceRateLimit();

    try {
      if (authorId.trim().isEmpty) {
        throw const ValidationApiFailure(
          message: 'Author ID cannot be empty',
          validationErrors: ['author_id_empty'],
        );
      }

      if (!authorId.startsWith('OL') || !authorId.endsWith('A')) {
        throw const ValidationApiFailure(
          message: 'Invalid OpenLibrary author ID format',
          validationErrors: ['invalid_author_id_format'],
        );
      }

      final response = await _dioClient.get(
        '$_baseUrl/authors/$authorId.json',
        options: Options(
          receiveTimeout: _requestTimeout,
          sendTimeout: _requestTimeout,
        ),
      );

      _trackRequest();

      if (response.statusCode == 404) {
        throw BookNotFoundApiFailure(
          message: 'Author not found',
          bookId: authorId,
          apiProvider: 'OpenLibrary',
        );
      }

      if (response.statusCode != 200) {
        throw HttpApiFailure(
          message: 'Failed to get author detail',
          statusCode: response.statusCode ?? 0,
        );
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioException(e, 'get author detail');
    } catch (e) {
      if (e is ApiFailure) rethrow;
      throw UnknownApiFailure(
        message: 'Unexpected error getting author detail: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<String?> getCoverImageUrl(String coverId, {String size = 'M'}) async {
    try {
      if (coverId.trim().isEmpty) {
        return null;
      }

      if (!['S', 'M', 'L'].contains(size)) {
        size = 'M'; // Default to medium
      }

      // OpenLibrary covers URL format
      return '$_coversBaseUrl/id/$coverId-$size.jpg';
    } catch (e) {
      // Don't throw for cover image URLs, just return null
      return null;
    }
  }

  @override
  Future<SearchResult> getTrendingBooks({
    String? subject,
    int limit = 20,
  }) async {
    await _enforceRateLimit();

    try {
      if (limit < 1 || limit > 50) {
        throw const ValidationApiFailure(
          message: 'Limit must be between 1 and 50',
          validationErrors: ['invalid_limit'],
        );
      }

      // Use OpenLibrary's trending endpoint or search with high ratings
      String query = 'ratings_average:[4 TO *]';
      if (subject != null && subject.trim().isNotEmpty) {
        query += ' AND subject:"${subject.trim()}"';
      }

      final response = await _dioClient.get(
        '$_baseUrl/search.json',
        queryParameters: {
          'q': query,
          'limit': limit,
          'sort': 'rating desc',
          'fields': [
            'key',
            'title',
            'author_name',
            'author_key',
            'first_publish_year',
            'isbn',
            'cover_i',
            'subject',
            'publisher',
            'language',
            'number_of_pages_median',
            'ratings_average',
            'ratings_count',
            'want_to_read_count',
          ].join(','),
        },
        options: Options(
          receiveTimeout: _requestTimeout,
          sendTimeout: _requestTimeout,
        ),
      );

      _trackRequest();

      if (response.statusCode != 200) {
        throw HttpApiFailure(
          message: 'Failed to get trending books',
          statusCode: response.statusCode ?? 0,
        );
      }

      final data = response.data as Map<String, dynamic>;
      return _parseSearchResponse(data, 'trending', 1, limit);
    } on DioException catch (e) {
      throw _handleDioException(e, 'get trending books');
    } catch (e) {
      if (e is ApiFailure) rethrow;
      throw UnknownApiFailure(
        message: 'Unexpected error getting trending books: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> checkApiStatus() async {
    try {
      final response = await _dioClient.get(
        '$_baseUrl/search.json',
        queryParameters: {
          'q': 'test',
          'limit': 1,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final currentTime = DateTime.now();
      final recentRequests = _requestTimestamps
          .where((timestamp) =>
              currentTime.difference(timestamp) < _rateLimitWindow)
          .length;

      return {
        'status': response.statusCode == 200 ? 'available' : 'error',
        'response_time_ms':
            response.extra['request_duration']?.inMilliseconds ?? 0,
        'rate_limit_remaining': _maxRequestsPerMinute - recentRequests,
        'rate_limit_reset_in_seconds': _getRateLimitResetTime(),
        'last_checked': currentTime.toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'last_checked': DateTime.now().toIso8601String(),
      };
    }
  }

  // Helper Methods

  /// Enforce rate limiting (100 requests per minute)
  Future<void> _enforceRateLimit() async {
    final now = DateTime.now();

    // Remove timestamps older than the window
    _requestTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp) >= _rateLimitWindow,
    );

    // Check if we're at the limit
    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      final oldestRequest = _requestTimestamps.first;
      final waitTime = _rateLimitWindow - now.difference(oldestRequest);

      if (waitTime.inMilliseconds > 0) {
        await Future.delayed(waitTime);
      }
    }
  }

  /// Track request timestamp for rate limiting
  void _trackRequest() {
    _requestTimestamps.add(DateTime.now());
  }

  /// Get seconds until rate limit resets
  int _getRateLimitResetTime() {
    if (_requestTimestamps.isEmpty) return 0;

    final oldestRequest = _requestTimestamps.first;
    final resetTime = oldestRequest.add(_rateLimitWindow);
    final now = DateTime.now();

    if (resetTime.isAfter(now)) {
      return resetTime.difference(now).inSeconds;
    }

    return 0;
  }

  /// Parse search response into SearchResult
  SearchResult _parseSearchResponse(
    Map<String, dynamic> data,
    String query,
    int page,
    int limit,
  ) {
    try {
      final docs = data['docs'] as List<dynamic>;
      final totalResults = data['numFound'] as int;

      final books = docs.map((doc) => _parseSearchResultBook(doc)).toList();

      final totalPages = (totalResults / limit).ceil();

      return SearchResult(
        books: books,
        totalCount: totalResults,
        currentPage: page,
        totalPages: totalPages,
        query: query,
        apiProvider: 'OpenLibrary',
        searchTime: DateTime.now(),
      );
    } catch (e) {
      throw ParseApiFailure(
        message: 'Failed to parse search response: $e',
        originalData: data.toString(),
      );
    }
  }

  /// Parse individual search result book
  BookSearchItem _parseSearchResultBook(Map<String, dynamic> doc) {
    try {
      final workKey = doc['key'] as String? ?? '';
      final workId = workKey.replaceFirst('/works/', '');

      final authorNames = (doc['author_name'] as List<dynamic>?)
              ?.map((name) => name.toString())
              .toList() ??
          [];

      final subjects = (doc['subject'] as List<dynamic>?)
              ?.map((subject) => subject.toString())
              .take(10) // Limit subjects to avoid huge lists
              .toList() ??
          [];

      String? coverUrl;
      final coverId = doc['cover_i'];
      if (coverId != null) {
        coverUrl = '$_coversBaseUrl/id/$coverId-M.jpg';
      }

      // Determine available formats (OpenLibrary doesn't provide direct downloads)
      final availableFormats = <BookFormat>[];

      // Parse publication date
      DateTime? publishDate;
      final year = doc['first_publish_year'];
      if (year != null) {
        try {
          publishDate = DateTime(year as int);
        } catch (e) {
          // Ignore invalid dates
        }
      }

      return BookSearchItem(
        id: workId,
        title: doc['title']?.toString() ?? 'Unknown Title',
        authors: authorNames,
        description: null, // Not available in search results
        language: (doc['language'] as List<dynamic>?)?.isNotEmpty == true
            ? (doc['language'] as List<dynamic>).first.toString()
            : null,
        subjects: subjects,
        publishDate: publishDate,
        coverUrl: coverUrl,
        availableFormats: availableFormats,
        downloadCount: doc['want_to_read_count'] as int?,
        rating: (doc['ratings_average'] as num?)?.toDouble(),
        apiProvider: 'OpenLibrary',
        metadata: {
          'work_key': workKey,
          'want_to_read_count': doc['want_to_read_count'],
          'currently_reading_count': doc['currently_reading_count'],
          'already_read_count': doc['already_read_count'],
          'ratings_count': doc['ratings_count'],
          'number_of_pages_median': doc['number_of_pages_median'],
        },
      );
    } catch (e) {
      throw ParseApiFailure(
        message: 'Failed to parse search result book: $e',
        originalData: doc.toString(),
      );
    }
  }

  /// Parse work detail response
  BookDetail _parseWorkDetail(
    Map<String, dynamic> workData,
    Map<String, dynamic>? editionsData,
  ) {
    try {
      final key = workData['key'] as String? ?? '';
      final workId = key.replaceFirst('/works/', '');

      final title = workData['title']?.toString() ?? 'Unknown Title';

      // Parse description
      String? description;
      final descValue = workData['description'];
      if (descValue is Map && descValue.containsKey('value')) {
        description = descValue['value'].toString();
      } else if (descValue is String) {
        description = descValue;
      }

      // Parse authors
      final authors = <BookAuthor>[];
      final authorEntries = workData['authors'] as List<dynamic>? ?? [];
      for (final authorEntry in authorEntries) {
        if (authorEntry is Map<String, dynamic>) {
          final authorKey = authorEntry['author']?['key']?.toString() ?? '';
          final authorId = authorKey.replaceFirst('/authors/', '');
          authors.add(BookAuthor(
            id: authorId,
            name: 'Unknown Author', // Will be resolved by repository
            aliases: [],
            metadata: {'key': authorKey},
          ));
        }
      }

      // Parse subjects
      final subjects = (workData['subjects'] as List<dynamic>?)
              ?.map((subject) => subject.toString())
              .take(20)
              .toList() ??
          [];

      // Parse covers
      final coverUrls = <String>[];
      final covers = workData['covers'] as List<dynamic>?;
      if (covers != null && covers.isNotEmpty) {
        final coverId = covers.first;
        coverUrls.add('$_coversBaseUrl/id/$coverId-L.jpg');
      }

      // Extract publication info from editions
      DateTime? publishDate;
      String? publisher;
      String? language;
      int? pageCount;
      String? isbn;

      if (editionsData != null) {
        final entries = editionsData['entries'] as List<dynamic>? ?? [];
        if (entries.isNotEmpty) {
          final firstEdition = entries.first as Map<String, dynamic>;

          final publishDateStr = firstEdition['publish_date']?.toString();
          if (publishDateStr != null) {
            try {
              // Try to parse various date formats
              if (RegExp(r'^\d{4}$').hasMatch(publishDateStr)) {
                publishDate = DateTime(int.parse(publishDateStr));
              }
            } catch (e) {
              // Ignore invalid dates
            }
          }

          final publishers = firstEdition['publishers'] as List<dynamic>?;
          if (publishers != null && publishers.isNotEmpty) {
            publisher = publishers.first.toString();
          }

          final languages = firstEdition['languages'] as List<dynamic>?;
          if (languages != null && languages.isNotEmpty) {
            final langEntry = languages.first;
            if (langEntry is Map && langEntry.containsKey('key')) {
              language =
                  langEntry['key'].toString().replaceFirst('/languages/', '');
            }
          }

          pageCount = firstEdition['number_of_pages'] as int?;

          final isbns = [
            ...(firstEdition['isbn_10'] as List<dynamic>? ?? []),
            ...(firstEdition['isbn_13'] as List<dynamic>? ?? []),
          ];
          if (isbns.isNotEmpty) {
            isbn = isbns.first.toString();
          }
        }
      }

      return BookDetail(
        id: workId,
        title: title,
        authors: authors,
        description: description,
        fullDescription: description,
        language: language,
        subjects: subjects,
        genres: subjects, // Use subjects as genres for OpenLibrary
        publishDate: publishDate,
        publisher: publisher,
        isbn: isbn,
        coverUrls: coverUrls,
        availableFormats: [], // OpenLibrary doesn't provide direct downloads
        downloadUrls: {},
        pageCount: pageCount,
        downloadCount: null,
        rating: null, // Not available in work detail
        ratingCount: null,
        apiProvider: 'OpenLibrary',
        metadata: {
          'work_key': key,
          'revision': workData['revision'],
          'type': workData['type']?['key'],
          'created': workData['created']?['value'],
          'covers': workData['covers'],
          'links': workData['links'],
          'editions_count': editionsData?['size'],
        },
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      throw ParseApiFailure(
        message: 'Failed to parse work detail: $e',
        originalData: workData.toString(),
      );
    }
  }

  /// Parse books by identifiers response
  List<BookDetail> _parseBooksByIdentifiers(Map<String, dynamic> data) {
    try {
      final books = <BookDetail>[];

      for (final entry in data.entries) {
        final identifier = entry.key;
        final bookData = entry.value as Map<String, dynamic>;

        // Extract basic information
        final title = bookData['title']?.toString() ?? 'Unknown Title';

        final authors = <BookAuthor>[];
        final authorList = bookData['authors'] as List<dynamic>? ?? [];
        for (final author in authorList) {
          if (author is Map<String, dynamic>) {
            authors.add(BookAuthor(
              id: '', // Not provided in this endpoint
              name: author['name']?.toString() ?? 'Unknown Author',
              aliases: [],
              metadata: {},
            ));
          }
        }

        final publishers = (bookData['publishers'] as List<dynamic>?)
                ?.map((pub) => pub['name']?.toString() ?? pub.toString())
                .toList() ??
            [];

        final subjects = (bookData['subjects'] as List<dynamic>?)
                ?.map((subject) =>
                    subject['name']?.toString() ?? subject.toString())
                .take(10)
                .toList() ??
            [];

        final coverUrls = <String>[];
        final cover = bookData['cover'];
        if (cover is Map && cover.containsKey('medium')) {
          coverUrls.add(cover['medium'].toString());
        }

        final identifierObj =
            bookData['identifiers'] as Map<String, dynamic>? ?? {};
        String? isbn;
        if (identifierObj.containsKey('isbn_13')) {
          final isbn13List = identifierObj['isbn_13'] as List<dynamic>?;
          if (isbn13List != null && isbn13List.isNotEmpty) {
            isbn = isbn13List.first.toString();
          }
        } else if (identifierObj.containsKey('isbn_10')) {
          final isbn10List = identifierObj['isbn_10'] as List<dynamic>?;
          if (isbn10List != null && isbn10List.isNotEmpty) {
            isbn = isbn10List.first.toString();
          }
        }

        books.add(BookDetail(
          id: identifier,
          title: title,
          authors: authors,
          description: bookData['excerpt']?.toString(),
          fullDescription: bookData['excerpt']?.toString(),
          language: null, // Not provided in this response
          subjects: subjects,
          genres: subjects,
          publishDate: null, // TODO: Parse publish_date if available
          publisher: publishers.isNotEmpty ? publishers.first : null,
          isbn: isbn,
          coverUrls: coverUrls,
          availableFormats: [],
          downloadUrls: {},
          pageCount: bookData['number_of_pages'] as int?,
          downloadCount: null,
          rating: null,
          ratingCount: null,
          apiProvider: 'OpenLibrary',
          metadata: {
            'identifier': identifier,
            'identifiers': identifierObj,
            'all_publishers': publishers,
            'all_subjects': subjects,
          },
          fetchedAt: DateTime.now(),
        ));
      }

      return books;
    } catch (e) {
      throw ParseApiFailure(
        message: 'Failed to parse books by identifiers: $e',
        originalData: data.toString(),
      );
    }
  }

  /// Handle Dio exceptions and convert to appropriate app exceptions
  ApiFailure _handleDioException(DioException e, String operation) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutApiFailure(
          message: 'Timeout during $operation: ${e.message}',
          timeout: const Duration(seconds: 30),
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            return const ValidationApiFailure(
              message: 'Bad request to OpenLibrary API',
              validationErrors: ['bad_request'],
            );
          case 401:
            return const AuthenticationApiFailure(
              message: 'Unauthorized access to OpenLibrary',
              apiProvider: 'OpenLibrary',
            );
          case 403:
            return const AuthenticationApiFailure(
              message: 'Forbidden access to OpenLibrary',
              apiProvider: 'OpenLibrary',
            );
          case 404:
            return const BookNotFoundApiFailure(
              message: 'Resource not found on OpenLibrary',
              bookId: '',
              apiProvider: 'OpenLibrary',
            );
          case 429:
            return const RateLimitApiFailure(
              message: 'Rate limit exceeded for OpenLibrary API',
              retryAfter: Duration(minutes: 1),
              apiProvider: 'OpenLibrary',
            );
          case 500:
          case 502:
          case 503:
          case 504:
            return HttpApiFailure(
              message: 'OpenLibrary server error: $statusCode',
              statusCode: statusCode ?? 0,
            );
          default:
            return HttpApiFailure(
              message: 'HTTP error during $operation: $statusCode',
              statusCode: statusCode ?? 0,
            );
        }

      case DioExceptionType.cancel:
        return const NetworkApiFailure(message: 'Request was cancelled');

      case DioExceptionType.badCertificate:
        return const NetworkApiFailure(message: 'SSL certificate error');

      case DioExceptionType.connectionError:
        return const NetworkApiFailure(
            message: 'Connection error during OpenLibrary request');

      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return const NetworkApiFailure(message: 'No internet connection');
        }
        return NetworkApiFailure(
            message: 'Unknown error during $operation: ${e.message}');
    }
  }
}
