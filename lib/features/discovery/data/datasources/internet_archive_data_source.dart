import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/api_entities.dart';
import '../../domain/failures/api_failures.dart';

/// Data source for Internet Archive Books API
/// 
/// This class handles direct communication with the Internet Archive API.
/// It implements rate limiting (100 requests/minute), error handling, 
/// and data validation according to the project specifications.
class InternetArchiveDataSource {
  final Dio _dio;
  DateTime? _lastRequestTime;
  int _requestCount = 0;
  static const Duration _rateWindowDuration = Duration(minutes: 1);
  static const int _maxRequestsPerWindow = ApiConstants.internetArchiveRequestsPerMinute;

  InternetArchiveDataSource({required Dio dio}) : _dio = dio {
    _dio.options.baseUrl = ApiConstants.internetArchiveBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Search books using Internet Archive search API
  Future<Map<String, dynamic>> searchBooks({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    await _enforceRateLimit();

    try {
      // Internet Archive advanced search for books
      final response = await _dio.get(
        ApiConstants.internetArchiveSearch,
        queryParameters: {
          'q': 'mediatype:texts AND ($query)',
          'output': ApiConstants.formatJson,
          'rows': limit,
          'page': page,
          'fl': [
            'identifier',
            'title',
            'creator',
            'description',
            'language',
            'subject',
            'date',
            'downloads',
            'avg_rating',
            'num_reviews',
          ].join(','),
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

  /// Get book metadata from Internet Archive
  Future<Map<String, dynamic>> getBookMetadata(String identifier) async {
    await _enforceRateLimit();

    try {
      final response = await _dio.get(
        ApiConstants.internetArchiveMetadata.replaceAll('{identifier}', identifier),
      );

      _validateResponse(response);
      return _processBookDetailResponse(response.data, identifier);
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
    required String identifier,
    required BookFormat format,
  }) async {
    await _enforceRateLimit();

    try {
      // First get metadata to find available files
      final metadataResponse = await _dio.get(
        ApiConstants.internetArchiveMetadata.replaceAll('{identifier}', identifier),
      );

      _validateResponse(metadataResponse);
      
      final metadata = metadataResponse.data as Map<String, dynamic>;
      final files = metadata['files'] as List<dynamic>? ?? [];
      
      String? filename;
      for (final file in files) {
        final fileData = file as Map<String, dynamic>;
        final fileName = fileData['name'] as String? ?? '';
        
        switch (format) {
          case BookFormat.epub:
            if (fileName.toLowerCase().endsWith('.epub')) {
              filename = fileName;
              break;
            }
            break;
          case BookFormat.pdf:
            if (fileName.toLowerCase().endsWith('.pdf')) {
              filename = fileName;
              break;
            }
            break;
          case BookFormat.text:
            if (fileName.toLowerCase().endsWith('.txt') || 
                fileName.toLowerCase().contains('_djvu.txt')) {
              filename = fileName;
              break;
            }
            break;
          default:
            continue;
        }
        
        if (filename != null) break;
      }

      if (filename == null) {
        throw InvalidFormatApiFailure(
          message: 'Requested format not available for this book',
          requestedFormat: format.displayName,
          availableFormats: _extractAvailableFormats(files),
        );
      }

      final downloadUrl = '${_dio.options.baseUrl}${ApiConstants.internetArchiveDownload}'
          .replaceAll('{identifier}', identifier)
          .replaceAll('{filename}', filename);

      // Get file size from metadata
      final fileInfo = files.firstWhere(
        (file) => (file as Map<String, dynamic>)['name'] == filename,
        orElse: () => <String, dynamic>{},
      ) as Map<String, dynamic>;

      return {
        'bookId': identifier,
        'format': format.name,
        'downloadUrl': downloadUrl,
        'filename': filename,
        'fileSize': _parseFileSize(fileInfo['size']),
        'mimeType': format.mimeType,
        'headers': <String, String>{},
        'apiProvider': 'Internet Archive',
      };
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
        '/services/search/v1/scrape',
        queryParameters: {
          'q': 'mediatype:texts',
          'count': 1,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final responseTime = DateTime.now().difference(startTime);
      final remainingRequests = _maxRequestsPerWindow - _requestCount;

      return {
        'provider': 'Internet Archive',
        'isAvailable': response.statusCode == 200,
        'responseTime': responseTime.inMilliseconds,
        'version': '1.0',
        'checkedAt': DateTime.now().toIso8601String(),
        'rateLimitRemaining': remainingRequests > 0 ? remainingRequests : 0,
        'rateLimitReset': _getResetTime(),
      };
    } on DioException catch (e) {
      final responseTime = DateTime.now().difference(startTime);
      
      return {
        'provider': 'Internet Archive',
        'isAvailable': false,
        'responseTime': responseTime.inMilliseconds,
        'errorMessage': e.message ?? 'Connection failed',
        'version': '1.0',
        'checkedAt': DateTime.now().toIso8601String(),
        'rateLimitRemaining': _maxRequestsPerWindow - _requestCount,
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
      final response = await _dio.get(
        ApiConstants.internetArchiveSearch,
        queryParameters: {
          'q': 'mediatype:texts',
          'output': ApiConstants.formatJson,
          'rows': limit,
          'page': page,
          'sort': 'downloads desc',
          'fl': [
            'identifier',
            'title',
            'creator',
            'description',
            'language',
            'subject',
            'date',
            'downloads',
            'avg_rating',
            'num_reviews',
          ].join(','),
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

  /// Get recently added books
  Future<Map<String, dynamic>> getRecentBooks({
    int page = 1,
    int limit = 20,
    int? days,
  }) async {
    await _enforceRateLimit();

    try {
      final dateFilter = days != null 
          ? 'addeddate:[${_formatDateFilter(days)} TO null]'
          : '';
      
      final query = dateFilter.isNotEmpty 
          ? 'mediatype:texts AND $dateFilter'
          : 'mediatype:texts';

      final response = await _dio.get(
        ApiConstants.internetArchiveSearch,
        queryParameters: {
          'q': query,
          'output': ApiConstants.formatJson,
          'rows': limit,
          'page': page,
          'sort': 'addeddate desc',
          'fl': [
            'identifier',
            'title',
            'creator',
            'description',
            'language',
            'subject',
            'date',
            'downloads',
            'avg_rating',
            'num_reviews',
            'addeddate',
          ].join(','),
        },
      );

      _validateResponse(response);
      return _processSearchResponse(response.data, 'recent', page);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw UnknownApiFailure(
        message: 'Unexpected error getting recent books: $e',
        originalError: e,
      );
    }
  }

  /// Enforce rate limiting (100 requests per minute)
  Future<void> _enforceRateLimit() async {
    final now = DateTime.now();
    
    // Reset counter if window has passed
    if (_lastRequestTime != null && 
        now.difference(_lastRequestTime!) >= _rateWindowDuration) {
      _requestCount = 0;
    }
    
    // Check if we've exceeded the rate limit
    if (_requestCount >= _maxRequestsPerWindow) {
      final waitTime = _getResetTime();
      if (waitTime > 0) {
        throw RateLimitApiFailure(
          message: 'Rate limit exceeded. Please wait before making more requests.',
          retryAfter: Duration(seconds: waitTime),
          apiProvider: 'Internet Archive',
        );
      } else {
        _requestCount = 0; // Reset if wait time has passed
      }
    }
    
    _requestCount++;
    _lastRequestTime = now;
  }

  /// Get time until rate limit reset in seconds
  int _getResetTime() {
    if (_lastRequestTime == null) return 0;
    
    final elapsed = DateTime.now().difference(_lastRequestTime!);
    final remaining = _rateWindowDuration - elapsed;
    
    return remaining.inSeconds > 0 ? remaining.inSeconds : 0;
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
          apiProvider: 'Internet Archive',
        );
      } else if (response.statusCode == 429) {
        throw RateLimitApiFailure(
          message: 'Rate limit exceeded',
          retryAfter: Duration(seconds: _getResetTime()),
          apiProvider: 'Internet Archive',
        );
      } else if (response.statusCode! >= 500) {
        throw ServiceUnavailableApiFailure(
          message: 'Server error: ${response.statusCode}',
          apiProvider: 'Internet Archive',
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

  /// Process search response from Internet Archive
  Map<String, dynamic> _processSearchResponse(
    dynamic data,
    String query,
    int page,
  ) {
    try {
      final Map<String, dynamic> responseData = data is Map<String, dynamic>
          ? data
          : json.decode(data.toString());

      final response = responseData['response'] as Map<String, dynamic>? ?? {};
      final docs = response['docs'] as List<dynamic>? ?? [];
      final numFound = response['numFound'] as int? ?? 0;

      final books = docs.map((docData) {
        return _processBookItem(docData as Map<String, dynamic>);
      }).toList();

      return {
        'books': books,
        'totalCount': numFound,
        'currentPage': page,
        'totalPages': (numFound / 20).ceil(),
        'query': query,
        'apiProvider': 'Internet Archive',
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
  Map<String, dynamic> _processBookItem(Map<String, dynamic> docData) {
    final identifier = docData['identifier']?.toString() ?? '';
    final title = docData['title']?.toString() ?? 'Unknown Title';
    
    // Handle creators (can be string or array)
    final creatorsData = docData['creator'];
    List<String> authors = [];
    if (creatorsData is List) {
      authors = creatorsData.map((creator) => creator.toString()).toList();
    } else if (creatorsData is String) {
      authors = [creatorsData];
    }

    // Handle subjects (can be string or array)
    final subjectsData = docData['subject'];
    List<String> subjects = [];
    if (subjectsData is List) {
      subjects = subjectsData.map((subject) => subject.toString()).toList();
    } else if (subjectsData is String) {
      subjects = [subjectsData];
    }

    // Handle language (can be string or array)
    final languageData = docData['language'];
    String? language;
    if (languageData is List && languageData.isNotEmpty) {
      language = languageData.first.toString();
    } else if (languageData is String) {
      language = languageData;
    }

    return {
      'id': identifier,
      'title': title,
      'authors': authors,
      'description': docData['description']?.toString(),
      'language': language,
      'subjects': subjects,
      'publishDate': _parseDate(docData['date']),
      'coverUrl': _generateCoverUrl(identifier),
      'availableFormats': ['epub', 'pdf', 'text'], // Internet Archive typically has multiple formats
      'downloadCount': _parseInt(docData['downloads']),
      'rating': _parseDouble(docData['avg_rating']),
      'apiProvider': 'Internet Archive',
      'metadata': docData,
    };
  }

  /// Process book detail response
  Map<String, dynamic> _processBookDetailResponse(
    dynamic data,
    String identifier,
  ) {
    try {
      final Map<String, dynamic> metadata = data is Map<String, dynamic>
          ? data
          : json.decode(data.toString());

      final metadataFields = metadata['metadata'] as Map<String, dynamic>? ?? {};
      
      // Convert metadata to book item format
      final bookItem = _processBookItem({
        'identifier': identifier,
        'title': metadataFields['title'],
        'creator': metadataFields['creator'],
        'description': metadataFields['description'],
        'language': metadataFields['language'],
        'subject': metadataFields['subject'],
        'date': metadataFields['date'],
        'downloads': metadata['item']?['downloads'],
        'avg_rating': metadata['reviews']?['avg_rating'],
      });
      
      // Add additional detail fields
      bookItem['fullDescription'] = metadataFields['description']?.toString();
      bookItem['publisher'] = metadataFields['publisher']?.toString();
      bookItem['isbn'] = metadataFields['isbn']?.toString();
      bookItem['pageCount'] = null; // Not typically provided
      bookItem['fetchedAt'] = DateTime.now().toIso8601String();
      
      return bookItem;
    } catch (e) {
      throw ParseApiFailure(
        message: 'Failed to parse book detail response: $e',
        originalData: data.toString(),
      );
    }
  }

  /// Extract available formats from files list
  List<String> _extractAvailableFormats(List<dynamic> files) {
    final formats = <String>[];
    
    for (final file in files) {
      final fileData = file as Map<String, dynamic>;
      final fileName = fileData['name'] as String? ?? '';
      
      if (fileName.toLowerCase().endsWith('.epub') && !formats.contains('EPUB')) {
        formats.add('EPUB');
      } else if (fileName.toLowerCase().endsWith('.pdf') && !formats.contains('PDF')) {
        formats.add('PDF');
      } else if ((fileName.toLowerCase().endsWith('.txt') || 
                 fileName.toLowerCase().contains('_djvu.txt')) && 
                !formats.contains('Text')) {
        formats.add('Text');
      }
    }
    
    return formats;
  }

  /// Generate cover image URL for Internet Archive item
  String _generateCoverUrl(String identifier) {
    return 'https://archive.org/services/img/$identifier';
  }

  /// Parse file size string to integer
  int? _parseFileSize(dynamic size) {
    if (size == null) return null;
    if (size is int) return size;
    if (size is String) return int.tryParse(size);
    return null;
  }

  /// Parse date string to ISO format
  String? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is String && date.isNotEmpty) {
      // Try to parse various date formats
      try {
        final parsed = DateTime.tryParse(date);
        return parsed?.toIso8601String();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Parse integer value
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Parse double value
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Format date filter for recent books query
  String _formatDateFilter(int days) {
    final date = DateTime.now().subtract(Duration(days: days));
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
            apiProvider: 'Internet Archive',
          );
        } else if (statusCode == 429) {
          return RateLimitApiFailure(
            message: 'Rate limit exceeded',
            retryAfter: Duration(seconds: _getResetTime()),
            apiProvider: 'Internet Archive',
          );
        } else if (statusCode >= 500) {
          return ServiceUnavailableApiFailure(
            message: 'Server error: $statusCode',
            apiProvider: 'Internet Archive',
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
