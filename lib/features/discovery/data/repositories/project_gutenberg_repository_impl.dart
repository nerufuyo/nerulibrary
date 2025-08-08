import 'package:dartz/dartz.dart';

import '../../domain/entities/api_entities.dart';
import '../../domain/failures/api_failures.dart';
import '../../domain/repositories/book_discovery_repository.dart';
import '../datasources/project_gutenberg_data_source.dart';

/// Project Gutenberg implementation of BookDiscoveryRepository
/// 
/// This repository provides access to Project Gutenberg's collection of
/// public domain books through their API. It implements comprehensive
/// error handling, rate limiting, and data validation.
class ProjectGutenbergRepository implements BookDiscoveryRepository {
  final ProjectGutenbergDataSource _dataSource;

  const ProjectGutenbergRepository({
    required ProjectGutenbergDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  String get providerName => 'Project Gutenberg';

  @override
  String get baseUrl => 'https://www.gutenberg.org';

  @override
  Future<Either<ApiFailure, SearchResult>> searchBooks({
    required String query,
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // Validate input parameters
      if (query.trim().isEmpty) {
        return Left(ValidationApiFailure(
          message: 'Search query cannot be empty',
          validationErrors: ['Query is required'],
        ));
      }

      if (limit > 100) {
        return Left(ValidationApiFailure(
          message: 'Limit cannot exceed 100',
          validationErrors: ['Limit must be <= 100'],
        ));
      }

      if (page < 1) {
        return Left(ValidationApiFailure(
          message: 'Page number must be positive',
          validationErrors: ['Page must be >= 1'],
        ));
      }

      final responseData = await _dataSource.searchBooks(
        query: query.trim(),
        page: page,
        limit: limit,
      );

      final searchResult = _mapToSearchResult(responseData);
      return Right(searchResult);
    } on ApiFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownApiFailure(
        message: 'Unexpected error during search: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<ApiFailure, BookDetail>> getBookDetail(String bookId) async {
    try {
      // Validate book ID
      if (bookId.trim().isEmpty) {
        return Left(ValidationApiFailure(
          message: 'Book ID cannot be empty',
          validationErrors: ['Book ID is required'],
        ));
      }

      final responseData = await _dataSource.getBookMetadata(bookId.trim());
      final bookDetail = _mapToBookDetail(responseData);
      return Right(bookDetail);
    } on ApiFailure catch (e) {
      return Left(e);
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
    try {
      // Validate input parameters
      if (bookId.trim().isEmpty) {
        return Left(ValidationApiFailure(
          message: 'Book ID cannot be empty',
          validationErrors: ['Book ID is required'],
        ));
      }

      // Check if format is supported
      if (!_isSupportedFormat(format)) {
        return Left(InvalidFormatApiFailure(
          message: 'Format not supported by Project Gutenberg',
          requestedFormat: format.displayName,
          availableFormats: ['EPUB', 'PDF', 'Text'],
        ));
      }

      final responseData = await _dataSource.getDownloadInfo(
        bookId: bookId.trim(),
        format: format,
      );

      final downloadInfo = _mapToDownloadInfo(responseData);
      return Right(downloadInfo);
    } on ApiFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownApiFailure(
        message: 'Unexpected error getting download URL: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<ApiFailure, ApiStatus>> checkApiStatus() async {
    try {
      final responseData = await _dataSource.checkApiStatus();
      final apiStatus = _mapToApiStatus(responseData);
      return Right(apiStatus);
    } on ApiFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownApiFailure(
        message: 'Unexpected error checking API status: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<ApiFailure, BookAuthor>> getAuthorDetail(String authorId) async {
    // Project Gutenberg doesn't provide detailed author information
    return Left(ServiceUnavailableApiFailure(
      message: 'Author details not available in Project Gutenberg API',
      apiProvider: providerName,
    ));
  }

  @override
  Future<Either<ApiFailure, SearchResult>> getBooksByAuthor({
    required String authorId,
    int page = 1,
    int limit = 20,
  }) async {
    // Use search with author filter instead
    return searchBooks(
      query: 'author:"$authorId"',
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
    // Use search with subject filter
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
    try {
      final responseData = await _dataSource.getPopularBooks(
        page: page,
        limit: limit,
      );

      final searchResult = _mapToSearchResult(responseData);
      return Right(searchResult);
    } on ApiFailure catch (e) {
      return Left(e);
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
    // Project Gutenberg doesn't provide recent books API
    // Fall back to popular books
    return getPopularBooks(page: page, limit: limit);
  }

  @override
  Future<Either<ApiFailure, List<String>>> getAvailableSubjects() async {
    // Project Gutenberg doesn't provide a subjects list API
    // Return common subjects
    return Right([
      'Fiction',
      'History',
      'Biography',
      'Science',
      'Philosophy',
      'Religion',
      'Literature',
      'Poetry',
      'Drama',
      'Travel',
      'Children\'s Literature',
      'Reference',
    ]);
  }

  @override
  Future<Either<ApiFailure, List<String>>> getAvailableLanguages() async {
    // Common languages in Project Gutenberg
    return Right([
      'en', // English
      'fr', // French
      'de', // German
      'es', // Spanish
      'it', // Italian
      'pt', // Portuguese
      'nl', // Dutch
      'fi', // Finnish
      'sv', // Swedish
      'da', // Danish
      'no', // Norwegian
      'la', // Latin
      'gr', // Greek
    ]);
  }

  @override
  Future<Either<ApiFailure, List<String>>> getSearchSuggestions({
    required String partial,
    int limit = 10,
  }) async {
    // Project Gutenberg doesn't provide search suggestions
    // Return empty list
    return const Right([]);
  }

  @override
  bool supportsFeature(ApiFeature feature) {
    switch (feature) {
      case ApiFeature.fullTextSearch:
        return true;
      case ApiFeature.advancedFilters:
        return true;
      case ApiFeature.authorDetails:
        return false;
      case ApiFeature.ratingsAndReviews:
        return false;
      case ApiFeature.downloadStats:
        return true;
      case ApiFeature.multipleFormats:
        return true;
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
        return false;
    }
  }

  /// Check if the book format is supported by Project Gutenberg
  bool _isSupportedFormat(BookFormat format) {
    return format == BookFormat.epub ||
           format == BookFormat.pdf ||
           format == BookFormat.text;
  }

  /// Map response data to SearchResult entity
  SearchResult _mapToSearchResult(Map<String, dynamic> data) {
    final booksData = data['books'] as List<dynamic>;
    final books = booksData
        .map((bookData) => _mapToBookSearchItem(bookData as Map<String, dynamic>))
        .toList();

    return SearchResult(
      books: books,
      totalCount: data['totalCount'] as int,
      currentPage: data['currentPage'] as int,
      totalPages: data['totalPages'] as int,
      query: data['query'] as String,
      apiProvider: data['apiProvider'] as String,
      searchTime: DateTime.parse(data['searchTime'] as String),
    );
  }

  /// Map response data to BookSearchItem entity
  BookSearchItem _mapToBookSearchItem(Map<String, dynamic> data) {
    final authorsData = data['authors'] as List<dynamic>;
    final authors = authorsData.map((author) => author.toString()).toList();

    final subjectsData = data['subjects'] as List<dynamic>;
    final subjects = subjectsData.map((subject) => subject.toString()).toList();

    final formatsData = data['availableFormats'] as List<dynamic>;
    final availableFormats = formatsData
        .map((format) => BookFormat.fromString(format.toString()))
        .where((format) => format != null)
        .cast<BookFormat>()
        .toList();

    return BookSearchItem(
      id: data['id'] as String,
      title: data['title'] as String,
      authors: authors,
      description: data['description'] as String?,
      language: data['language'] as String?,
      subjects: subjects,
      publishDate: null, // Project Gutenberg rarely provides this
      coverUrl: data['coverUrl'] as String?,
      availableFormats: availableFormats,
      downloadCount: data['downloadCount'] as int?,
      rating: data['rating'] as double?,
      apiProvider: data['apiProvider'] as String,
      metadata: data['metadata'] as Map<String, dynamic>,
    );
  }

  /// Map response data to BookDetail entity
  BookDetail _mapToBookDetail(Map<String, dynamic> data) {
    final searchItem = _mapToBookSearchItem(data);

    // Convert authors to BookAuthor objects
    final authors = searchItem.authors
        .map((authorName) => BookAuthor(
              id: authorName.toLowerCase().replaceAll(' ', '_'),
              name: authorName,
              aliases: const [],
              metadata: const {},
            ))
        .toList();

    // Extract download URLs from metadata
    final downloadUrls = <BookFormat, String>{};
    final formatsData = data['metadata']['formats'] as Map<String, dynamic>? ?? {};
    
    for (final entry in formatsData.entries) {
      if (entry.key.contains('epub')) {
        downloadUrls[BookFormat.epub] = entry.value.toString();
      } else if (entry.key.contains('pdf')) {
        downloadUrls[BookFormat.pdf] = entry.value.toString();
      } else if (entry.key.contains('txt') || entry.key.contains('text')) {
        downloadUrls[BookFormat.text] = entry.value.toString();
      }
    }

    return BookDetail(
      id: searchItem.id,
      title: searchItem.title,
      authors: authors,
      description: searchItem.description,
      fullDescription: data['fullDescription'] as String?,
      language: searchItem.language,
      subjects: searchItem.subjects,
      genres: searchItem.subjects, // Use subjects as genres
      publishDate: searchItem.publishDate,
      publisher: data['publisher'] as String?,
      isbn: data['isbn'] as String?,
      coverUrls: searchItem.coverUrl != null ? [searchItem.coverUrl!] : [],
      availableFormats: searchItem.availableFormats,
      downloadUrls: downloadUrls,
      pageCount: data['pageCount'] as int?,
      downloadCount: searchItem.downloadCount,
      rating: searchItem.rating,
      ratingCount: null, // Not provided by Project Gutenberg
      apiProvider: searchItem.apiProvider,
      metadata: searchItem.metadata,
      fetchedAt: DateTime.parse(data['fetchedAt'] as String),
    );
  }

  /// Map response data to DownloadInfo entity
  DownloadInfo _mapToDownloadInfo(Map<String, dynamic> data) {
    final headersData = data['headers'] as Map<String, dynamic>;
    final headers = headersData.map((key, value) => MapEntry(key, value.toString()));

    return DownloadInfo(
      bookId: data['bookId'] as String,
      format: BookFormat.fromString(data['format'] as String)!,
      downloadUrl: data['downloadUrl'] as String,
      filename: data['filename'] as String?,
      fileSize: data['fileSize'] as int?,
      mimeType: data['mimeType'] as String?,
      expiresAt: null, // Project Gutenberg URLs don't expire
      headers: headers,
      apiProvider: data['apiProvider'] as String,
    );
  }

  /// Map response data to ApiStatus entity
  ApiStatus _mapToApiStatus(Map<String, dynamic> data) {
    return ApiStatus(
      provider: data['provider'] as String,
      isAvailable: data['isAvailable'] as bool,
      responseTime: Duration(milliseconds: data['responseTime'] as int),
      errorMessage: data['errorMessage'] as String?,
      rateLimitRemaining: data['rateLimitRemaining'] as int?,
      rateLimitReset: data['rateLimitReset'] != null 
          ? Duration(seconds: data['rateLimitReset'] as int)
          : null,
      version: data['version'] as String,
      checkedAt: DateTime.parse(data['checkedAt'] as String),
    );
  }
}
