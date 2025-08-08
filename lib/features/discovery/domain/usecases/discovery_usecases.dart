import 'package:dartz/dartz.dart';

import '../entities/api_entities.dart';
import '../failures/api_failures.dart';
import '../repositories/book_discovery_repository.dart';

/// Use case for searching books across API providers
///
/// This use case handles book search requests with validation,
/// caching, and error handling. It can work with multiple
/// API providers and aggregate results.
class SearchBooksUseCase {
  final BookDiscoveryRepository _repository;

  const SearchBooksUseCase({
    required BookDiscoveryRepository repository,
  }) : _repository = repository;

  /// Execute book search
  ///
  /// Parameters:
  /// - [params]: Search parameters including query, pagination, and filters
  ///
  /// Returns [Either] containing [ApiFailure] on error or [SearchResult] on success.
  Future<Either<ApiFailure, SearchResult>> call(
      SearchBooksParams params) async {
    // Validate search parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Execute search
    return await _repository.searchBooks(
      query: params.query,
      page: params.page,
      limit: params.limit,
      filters: params.filters,
    );
  }

  /// Validate search parameters
  ValidationApiFailure? _validateParams(SearchBooksParams params) {
    final errors = <String>[];

    // Validate query
    if (params.query.trim().isEmpty) {
      errors.add('Search query cannot be empty');
    }

    if (params.query.length < 2) {
      errors.add('Search query must be at least 2 characters long');
    }

    if (params.query.length > 500) {
      errors.add('Search query cannot exceed 500 characters');
    }

    // Validate pagination
    if (params.page < 1) {
      errors.add('Page number must be positive');
    }

    if (params.limit < 1) {
      errors.add('Limit must be positive');
    }

    if (params.limit > 100) {
      errors.add('Limit cannot exceed 100');
    }

    if (errors.isNotEmpty) {
      return ValidationApiFailure(
        message: 'Invalid search parameters',
        validationErrors: errors,
      );
    }

    return null;
  }
}

/// Parameters for book search
class SearchBooksParams {
  final String query;
  final int page;
  final int limit;
  final Map<String, dynamic>? filters;

  const SearchBooksParams({
    required this.query,
    this.page = 1,
    this.limit = 20,
    this.filters,
  });

  SearchBooksParams copyWith({
    String? query,
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  }) {
    return SearchBooksParams(
      query: query ?? this.query,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      filters: filters ?? this.filters,
    );
  }

  @override
  String toString() {
    return 'SearchBooksParams(query: $query, page: $page, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchBooksParams &&
        other.query == query &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(query, page, limit);
  }
}

/// Use case for getting book details
class GetBookDetailUseCase {
  final BookDiscoveryRepository _repository;

  const GetBookDetailUseCase({
    required BookDiscoveryRepository repository,
  }) : _repository = repository;

  /// Execute get book detail
  ///
  /// Parameters:
  /// - [params]: Book detail parameters including book ID
  ///
  /// Returns [Either] containing [ApiFailure] on error or [BookDetail] on success.
  Future<Either<ApiFailure, BookDetail>> call(
      GetBookDetailParams params) async {
    // Validate parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    return await _repository.getBookDetail(params.bookId);
  }

  /// Validate get book detail parameters
  ValidationApiFailure? _validateParams(GetBookDetailParams params) {
    final errors = <String>[];

    if (params.bookId.trim().isEmpty) {
      errors.add('Book ID cannot be empty');
    }

    if (params.bookId.length > 100) {
      errors.add('Book ID cannot exceed 100 characters');
    }

    if (errors.isNotEmpty) {
      return ValidationApiFailure(
        message: 'Invalid book detail parameters',
        validationErrors: errors,
      );
    }

    return null;
  }
}

/// Parameters for getting book details
class GetBookDetailParams {
  final String bookId;

  const GetBookDetailParams({
    required this.bookId,
  });

  @override
  String toString() {
    return 'GetBookDetailParams(bookId: $bookId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetBookDetailParams && other.bookId == bookId;
  }

  @override
  int get hashCode => bookId.hashCode;
}

/// Use case for getting download information
class GetDownloadInfoUseCase {
  final BookDiscoveryRepository _repository;

  const GetDownloadInfoUseCase({
    required BookDiscoveryRepository repository,
  }) : _repository = repository;

  /// Execute get download info
  ///
  /// Parameters:
  /// - [params]: Download parameters including book ID and format
  ///
  /// Returns [Either] containing [ApiFailure] on error or [DownloadInfo] on success.
  Future<Either<ApiFailure, DownloadInfo>> call(
      GetDownloadInfoParams params) async {
    // Validate parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    return await _repository.getDownloadUrl(
      bookId: params.bookId,
      format: params.format,
    );
  }

  /// Validate download info parameters
  ValidationApiFailure? _validateParams(GetDownloadInfoParams params) {
    final errors = <String>[];

    if (params.bookId.trim().isEmpty) {
      errors.add('Book ID cannot be empty');
    }

    if (errors.isNotEmpty) {
      return ValidationApiFailure(
        message: 'Invalid download parameters',
        validationErrors: errors,
      );
    }

    return null;
  }
}

/// Parameters for getting download information
class GetDownloadInfoParams {
  final String bookId;
  final BookFormat format;

  const GetDownloadInfoParams({
    required this.bookId,
    required this.format,
  });

  @override
  String toString() {
    return 'GetDownloadInfoParams(bookId: $bookId, format: ${format.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetDownloadInfoParams &&
        other.bookId == bookId &&
        other.format == format;
  }

  @override
  int get hashCode => Object.hash(bookId, format);
}

/// Use case for getting popular books
class GetPopularBooksUseCase {
  final BookDiscoveryRepository _repository;

  const GetPopularBooksUseCase({
    required BookDiscoveryRepository repository,
  }) : _repository = repository;

  /// Execute get popular books
  ///
  /// Parameters:
  /// - [params]: Popular books parameters including pagination
  ///
  /// Returns [Either] containing [ApiFailure] on error or [SearchResult] on success.
  Future<Either<ApiFailure, SearchResult>> call(
      GetPopularBooksParams params) async {
    // Validate parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    return await _repository.getPopularBooks(
      page: params.page,
      limit: params.limit,
      timeframe: params.timeframe,
    );
  }

  /// Validate popular books parameters
  ValidationApiFailure? _validateParams(GetPopularBooksParams params) {
    final errors = <String>[];

    if (params.page < 1) {
      errors.add('Page number must be positive');
    }

    if (params.limit < 1) {
      errors.add('Limit must be positive');
    }

    if (params.limit > 100) {
      errors.add('Limit cannot exceed 100');
    }

    if (errors.isNotEmpty) {
      return ValidationApiFailure(
        message: 'Invalid popular books parameters',
        validationErrors: errors,
      );
    }

    return null;
  }
}

/// Parameters for getting popular books
class GetPopularBooksParams {
  final int page;
  final int limit;
  final String? timeframe;

  const GetPopularBooksParams({
    this.page = 1,
    this.limit = 20,
    this.timeframe,
  });

  GetPopularBooksParams copyWith({
    int? page,
    int? limit,
    String? timeframe,
  }) {
    return GetPopularBooksParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      timeframe: timeframe ?? this.timeframe,
    );
  }

  @override
  String toString() {
    return 'GetPopularBooksParams(page: $page, limit: $limit, timeframe: $timeframe)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetPopularBooksParams &&
        other.page == page &&
        other.limit == limit &&
        other.timeframe == timeframe;
  }

  @override
  int get hashCode {
    return Object.hash(page, limit, timeframe);
  }
}

/// Use case for checking API status
class CheckApiStatusUseCase {
  final BookDiscoveryRepository _repository;

  const CheckApiStatusUseCase({
    required BookDiscoveryRepository repository,
  }) : _repository = repository;

  /// Execute API status check
  ///
  /// Returns [Either] containing [ApiFailure] on error or [ApiStatus] on success.
  Future<Either<ApiFailure, ApiStatus>> call() async {
    return await _repository.checkApiStatus();
  }
}

/// Use case for getting books by subject
class GetBooksBySubjectUseCase {
  final BookDiscoveryRepository _repository;

  const GetBooksBySubjectUseCase({
    required BookDiscoveryRepository repository,
  }) : _repository = repository;

  /// Execute get books by subject
  ///
  /// Parameters:
  /// - [params]: Subject search parameters
  ///
  /// Returns [Either] containing [ApiFailure] on error or [SearchResult] on success.
  Future<Either<ApiFailure, SearchResult>> call(
      GetBooksBySubjectParams params) async {
    // Validate parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    return await _repository.getBooksBySubject(
      subject: params.subject,
      page: params.page,
      limit: params.limit,
    );
  }

  /// Validate subject search parameters
  ValidationApiFailure? _validateParams(GetBooksBySubjectParams params) {
    final errors = <String>[];

    if (params.subject.trim().isEmpty) {
      errors.add('Subject cannot be empty');
    }

    if (params.page < 1) {
      errors.add('Page number must be positive');
    }

    if (params.limit < 1) {
      errors.add('Limit must be positive');
    }

    if (params.limit > 100) {
      errors.add('Limit cannot exceed 100');
    }

    if (errors.isNotEmpty) {
      return ValidationApiFailure(
        message: 'Invalid subject search parameters',
        validationErrors: errors,
      );
    }

    return null;
  }
}

/// Parameters for getting books by subject
class GetBooksBySubjectParams {
  final String subject;
  final int page;
  final int limit;

  const GetBooksBySubjectParams({
    required this.subject,
    this.page = 1,
    this.limit = 20,
  });

  GetBooksBySubjectParams copyWith({
    String? subject,
    int? page,
    int? limit,
  }) {
    return GetBooksBySubjectParams(
      subject: subject ?? this.subject,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  String toString() {
    return 'GetBooksBySubjectParams(subject: $subject, page: $page, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetBooksBySubjectParams &&
        other.subject == subject &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(subject, page, limit);
  }
}
