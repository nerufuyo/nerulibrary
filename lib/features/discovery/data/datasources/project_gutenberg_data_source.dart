import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/api_entities.dart';
import '../../domain/failures/api_failures.dart';

/// Data source for Project Gutenberg API
///
/// This class handles direct communication with the Project Gutenberg API.
/// It implements rate limiting, error handling, and data validation according
/// to the project specifications.
class ProjectGutenbergDataSource {
  final Dio _dio;
  DateTime? _lastRequestTime;
  static const Duration _rateLimitDelay = Duration(seconds: 1);

  ProjectGutenbergDataSource({required Dio dio}) : _dio = dio {
    _dio.options.baseUrl = ApiConstants.projectGutenbergBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Search books using Project Gutenberg search API
  Future<Map<String, dynamic>> searchBooks({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    await _enforceRateLimit();

    try {
      // Project Gutenberg search URL format
      final response = await _dio.get(
        ApiConstants.projectGutenbergSearch,
        queryParameters: {
          'query': query,
          'format': 'json',
          'start': ((page - 1) * limit) + 1,
          'limit': limit,
        },
      );

      _validateResponse(response);
      return _processSearchResponse(response.data, query, page);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw UnknownApiFailure(
        message: 'Unexpected error during search: $e',
        originalError: e,
      );
    }
  }

  /// Get book metadata from Project Gutenberg
  Future<Map<String, dynamic>> getBookMetadata(String bookId) async {
    await _enforceRateLimit();

    try {
      // Project Gutenberg metadata URL
      final response = await _dio.get('/ebooks/$bookId.json');

      _validateResponse(response);
      return _processBookDetailResponse(response.data, bookId);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw UnknownApiFailure(
        message: 'Unexpected error getting book metadata: $e',
        originalError: e,
      );
    }
  }

  /// Get download URLs for a specific book and format
  Future<Map<String, dynamic>> getDownloadInfo({
    required String bookId,
    required BookFormat format,
  }) async {
    await _enforceRateLimit();

    try {
      String endpoint;
      switch (format) {
        case BookFormat.epub:
          endpoint =
              ApiConstants.projectGutenbergEpub.replaceAll('{id}', bookId);
          break;
        case BookFormat.pdf:
          endpoint =
              ApiConstants.projectGutenbergPdf.replaceAll('{id}', bookId);
          break;
        case BookFormat.text:
          endpoint =
              ApiConstants.projectGutenbergText.replaceAll('{id}', bookId);
          break;
        default:
          throw InvalidFormatApiFailure(
            message: 'Format not supported by Project Gutenberg',
            requestedFormat: format.displayName,
            availableFormats: ['EPUB', 'PDF', 'Text'],
          );
      }

      // Check if the file exists by making a HEAD request
      final response = await _dio.head(endpoint);

      if (response.statusCode == 200) {
        return {
          'bookId': bookId,
          'format': format.name,
          'downloadUrl': '${_dio.options.baseUrl}$endpoint',
          'filename': 'pg$bookId${format.extension}',
          'fileSize': _extractContentLength(response.headers),
          'mimeType': format.mimeType,
          'headers': _extractHeaders(response.headers),
          'apiProvider': 'Project Gutenberg',
        };
      } else {
        throw BookNotFoundApiFailure(
          message: 'Book format not available',
          bookId: bookId,
          apiProvider: 'Project Gutenberg',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ApiFailure) rethrow;
      throw UnknownApiFailure(
        message: 'Unexpected error getting download info: $e',
        originalError: e,
      );
    }
  }

  /// Check API status and connectivity
  Future<Map<String, dynamic>> checkApiStatus() async {
    final startTime = DateTime.now();

    try {
      final response = await _dio.get(
        '/robots.txt',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final responseTime = DateTime.now().difference(startTime);

      return {
        'provider': 'Project Gutenberg',
        'isAvailable': response.statusCode == 200,
        'responseTime': responseTime.inMilliseconds,
        'version': '1.0',
        'checkedAt': DateTime.now().toIso8601String(),
        'rateLimitRemaining': null, // Project Gutenberg doesn't provide this
        'rateLimitReset': null,
      };
    } on DioException catch (e) {
      final responseTime = DateTime.now().difference(startTime);

      return {
        'provider': 'Project Gutenberg',
        'isAvailable': false,
        'responseTime': responseTime.inMilliseconds,
        'errorMessage': e.message ?? 'Connection failed',
        'version': '1.0',
        'checkedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get popular books (most downloaded)
  Future<Map<String, dynamic>> getPopularBooks({
    int page = 1,
    int limit = 20,
  }) async {
    await _enforceRateLimit();

    try {
      // Project Gutenberg popular books endpoint
      final response = await _dio.get(
        '/ebooks/search/',
        queryParameters: {
          'sort_order': 'downloads',
          'format': 'json',
          'start': ((page - 1) * limit) + 1,
          'limit': limit,
        },
      );

      _validateResponse(response);
      return _processSearchResponse(response.data, 'popular', page);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw UnknownApiFailure(
        message: 'Unexpected error getting popular books: $e',
        originalError: e,
      );
    }
  }

  /// Enforce rate limiting (1 request per second)
  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _rateLimitDelay) {
        final waitTime = _rateLimitDelay - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Validate HTTP response
  void _validateResponse(Response response) {
    if (response.statusCode == null) {
      throw NetworkApiFailure(message: 'No response received');
    }

    if (response.statusCode! >= 400) {
      if (response.statusCode == 404) {
        throw BookNotFoundApiFailure(
          message: 'Resource not found',
          bookId: 'unknown',
          apiProvider: 'Project Gutenberg',
        );
      } else if (response.statusCode == 429) {
        throw RateLimitApiFailure(
          message: 'Rate limit exceeded',
          retryAfter: const Duration(seconds: 60),
          apiProvider: 'Project Gutenberg',
        );
      } else if (response.statusCode! >= 500) {
        throw ServiceUnavailableApiFailure(
          message: 'Server error: ${response.statusCode}',
          apiProvider: 'Project Gutenberg',
        );
      } else {
        throw HttpApiFailure(
          message: 'HTTP error: ${response.statusCode}',
          statusCode: response.statusCode!,
          response: response.data,
        );
      }
    }

    if (response.data == null) {
      throw ParseApiFailure(
        message: 'Empty response data',
        originalData: '',
      );
    }
  }

  /// Process search response from Project Gutenberg
  Map<String, dynamic> _processSearchResponse(
    dynamic data,
    String query,
    int page,
  ) {
    try {
      final Map<String, dynamic> responseData =
          data is Map<String, dynamic> ? data : json.decode(data.toString());

      final results = responseData['results'] as List<dynamic>? ?? [];
      final totalCount = responseData['count'] as int? ?? 0;

      final books = results.map((bookData) {
        return _processBookItem(bookData as Map<String, dynamic>);
      }).toList();

      return {
        'books': books,
        'totalCount': totalCount,
        'currentPage': page,
        'totalPages': (totalCount / 20).ceil(),
        'query': query,
        'apiProvider': 'Project Gutenberg',
        'searchTime': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw ParseApiFailure(
        message: 'Failed to parse search response: $e',
        originalData: data.toString(),
      );
    }
  }

  /// Process individual book item from search results
  Map<String, dynamic> _processBookItem(Map<String, dynamic> bookData) {
    final id = bookData['id']?.toString() ?? '';
    final title = bookData['title']?.toString() ?? 'Unknown Title';
    final authorsData = bookData['authors'] as List<dynamic>? ?? [];
    final authors = authorsData
        .map((author) => author['name']?.toString() ?? 'Unknown Author')
        .toList();

    final subjectsData = bookData['subjects'] as List<dynamic>? ?? [];
    final subjects = subjectsData.map((subject) => subject.toString()).toList();

    final formatsData = bookData['formats'] as Map<String, dynamic>? ?? {};
    final availableFormats = <String>[];

    for (final format in formatsData.keys) {
      if (format.contains('epub')) availableFormats.add('epub');
      if (format.contains('pdf')) availableFormats.add('pdf');
      if (format.contains('txt') || format.contains('text'))
        availableFormats.add('text');
    }

    return {
      'id': id,
      'title': title,
      'authors': authors,
      'description': bookData['description']?.toString(),
      'language': _extractLanguage(bookData['languages'] as List<dynamic>?),
      'subjects': subjects,
      'publishDate': null, // Project Gutenberg doesn't always provide this
      'coverUrl': _extractCoverUrl(formatsData),
      'availableFormats': availableFormats,
      'downloadCount': bookData['download_count'] as int?,
      'rating': null, // Project Gutenberg doesn't provide ratings
      'apiProvider': 'Project Gutenberg',
      'metadata': bookData,
    };
  }

  /// Process book detail response
  Map<String, dynamic> _processBookDetailResponse(
    dynamic data,
    String bookId,
  ) {
    try {
      final Map<String, dynamic> bookData =
          data is Map<String, dynamic> ? data : json.decode(data.toString());

      final bookItem = _processBookItem(bookData);

      // Add additional detail fields
      bookItem['fullDescription'] = bookData['description']?.toString();
      bookItem['publisher'] = 'Project Gutenberg';
      bookItem['isbn'] =
          null; // Project Gutenberg books typically don't have ISBNs
      bookItem['pageCount'] = null; // Not provided by Project Gutenberg
      bookItem['fetchedAt'] = DateTime.now().toIso8601String();

      return bookItem;
    } catch (e) {
      throw ParseApiFailure(
        message: 'Failed to parse book detail response: $e',
        originalData: data.toString(),
      );
    }
  }

  /// Extract language from languages array
  String? _extractLanguage(List<dynamic>? languages) {
    if (languages == null || languages.isEmpty) return null;
    return languages.first.toString();
  }

  /// Extract cover URL from formats
  String? _extractCoverUrl(Map<String, dynamic> formats) {
    for (final entry in formats.entries) {
      if (entry.key.contains('cover') || entry.key.contains('image')) {
        return entry.value.toString();
      }
    }
    return null;
  }

  /// Extract content length from headers
  int? _extractContentLength(Headers headers) {
    final contentLength = headers.value('content-length');
    if (contentLength != null) {
      return int.tryParse(contentLength);
    }
    return null;
  }

  /// Extract relevant headers for download
  Map<String, String> _extractHeaders(Headers headers) {
    final result = <String, String>{};

    final contentType = headers.value('content-type');
    if (contentType != null) result['content-type'] = contentType;

    final contentLength = headers.value('content-length');
    if (contentLength != null) result['content-length'] = contentLength;

    final lastModified = headers.value('last-modified');
    if (lastModified != null) result['last-modified'] = lastModified;

    return result;
  }

  /// Handle Dio exceptions and convert to API failures
  ApiFailure _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutApiFailure(
          message: 'Request timeout: ${e.message}',
          timeout: const Duration(seconds: 30),
        );

      case DioExceptionType.connectionError:
        return NetworkApiFailure(
          message: 'Connection error: ${e.message}',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;

        if (statusCode == 404) {
          return BookNotFoundApiFailure(
            message: 'Resource not found',
            bookId: 'unknown',
            apiProvider: 'Project Gutenberg',
          );
        } else if (statusCode == 429) {
          return RateLimitApiFailure(
            message: 'Rate limit exceeded',
            retryAfter: const Duration(seconds: 60),
            apiProvider: 'Project Gutenberg',
          );
        } else if (statusCode >= 500) {
          return ServiceUnavailableApiFailure(
            message: 'Server error: $statusCode',
            apiProvider: 'Project Gutenberg',
          );
        } else {
          return HttpApiFailure(
            message: 'HTTP error: $statusCode',
            statusCode: statusCode,
            response: e.response?.data,
          );
        }

      case DioExceptionType.cancel:
        return NetworkApiFailure(
          message: 'Request was cancelled',
        );

      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return NetworkApiFailure(
            message: 'Network error: ${e.error}',
          );
        }
        return UnknownApiFailure(
          message: 'Unknown error: ${e.message}',
          originalError: e,
        );

      default:
        return UnknownApiFailure(
          message: 'Unexpected error: ${e.message}',
          originalError: e,
        );
    }
  }
}
