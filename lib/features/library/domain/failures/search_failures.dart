import '../../../../core/errors/failures.dart';

/// Base class for search-related failures
abstract class SearchFailure extends Failure {
  const SearchFailure({required super.message});
}

/// Failure when search query is invalid or malformed
class InvalidSearchQueryFailure extends SearchFailure {
  /// The invalid query that caused the failure
  final String query;
  
  /// Specific validation error details
  final String validationError;

  const InvalidSearchQueryFailure({
    required String message,
    required this.query,
    required this.validationError,
  }) : super(message: message);

  /// Factory constructor for empty query
  factory InvalidSearchQueryFailure.emptyQuery() {
    return const InvalidSearchQueryFailure(
      message: 'Search query cannot be empty',
      query: '',
      validationError: 'Query is empty or contains only whitespace',
    );
  }

  /// Factory constructor for query too short
  factory InvalidSearchQueryFailure.queryTooShort(String query) {
    return InvalidSearchQueryFailure(
      message: 'Search query is too short',
      query: query,
      validationError: 'Query must be at least 2 characters long',
    );
  }

  /// Factory constructor for invalid characters
  factory InvalidSearchQueryFailure.invalidCharacters(String query) {
    return InvalidSearchQueryFailure(
      message: 'Search query contains invalid characters',
      query: query,
      validationError: 'Query contains unsupported special characters',
    );
  }

  @override
  List<Object?> get props => [message, query, validationError];
}

/// Failure when search index is not initialized or corrupted
class SearchIndexFailure extends SearchFailure {
  /// The type of index problem
  final SearchIndexErrorType errorType;
  
  /// Additional technical details
  final String? technicalDetails;

  const SearchIndexFailure({
    required String message,
    required this.errorType,
    this.technicalDetails,
  }) : super(message: message);

  /// Factory constructor for uninitialized index
  factory SearchIndexFailure.notInitialized() {
    return const SearchIndexFailure(
      message: 'Search index has not been initialized',
      errorType: SearchIndexErrorType.notInitialized,
    );
  }

  /// Factory constructor for corrupted index
  factory SearchIndexFailure.corrupted({String? details}) {
    return SearchIndexFailure(
      message: 'Search index is corrupted and needs to be rebuilt',
      errorType: SearchIndexErrorType.corrupted,
      technicalDetails: details,
    );
  }

  /// Factory constructor for index creation failure
  factory SearchIndexFailure.creationFailed({String? details}) {
    return SearchIndexFailure(
      message: 'Failed to create search index',
      errorType: SearchIndexErrorType.creationFailed,
      technicalDetails: details,
    );
  }

  @override
  List<Object?> get props => [message, errorType, technicalDetails];
}

/// Types of search index errors
enum SearchIndexErrorType {
  /// Index has not been created or initialized
  notInitialized,
  
  /// Index exists but is corrupted
  corrupted,
  
  /// Failed to create or rebuild index
  creationFailed,
  
  /// Index update operation failed
  updateFailed,
  
  /// Index optimization failed
  optimizationFailed,
}

/// Failure when search operation times out
class SearchTimeoutFailure extends SearchFailure {
  /// The timeout duration that was exceeded
  final Duration timeoutDuration;
  
  /// The query that timed out
  final String query;

  const SearchTimeoutFailure({
    required String message,
    required this.timeoutDuration,
    required this.query,
  }) : super(message: message);

  /// Factory constructor for default timeout
  factory SearchTimeoutFailure.defaultTimeout(String query) {
    return SearchTimeoutFailure(
      message: 'Search operation timed out',
      timeoutDuration: const Duration(seconds: 30),
      query: query,
    );
  }

  @override
  List<Object?> get props => [message, timeoutDuration, query];
}

/// Failure when no search results are found
class NoSearchResultsFailure extends SearchFailure {
  /// The query that returned no results
  final String query;
  
  /// Applied filters
  final Map<String, dynamic>? filters;

  const NoSearchResultsFailure({
    required String message,
    required this.query,
    this.filters,
  }) : super(message: message);

  /// Factory constructor for no results
  factory NoSearchResultsFailure.noResults(String query) {
    return NoSearchResultsFailure(
      message: 'No search results found for the given query',
      query: query,
    );
  }

  /// Factory constructor for no results with filters
  factory NoSearchResultsFailure.noResultsWithFilters(
    String query,
    Map<String, dynamic> filters,
  ) {
    return NoSearchResultsFailure(
      message: 'No search results found for the given query and filters',
      query: query,
      filters: filters,
    );
  }

  @override
  List<Object?> get props => [message, query, filters];
}

/// Failure when search pagination is invalid
class SearchPaginationFailure extends SearchFailure {
  /// The invalid page number
  final int page;
  
  /// The limit per page
  final int limit;
  
  /// Maximum allowed page
  final int? maxPage;

  const SearchPaginationFailure({
    required String message,
    required this.page,
    required this.limit,
    this.maxPage,
  }) : super(message: message);

  /// Factory constructor for invalid page
  factory SearchPaginationFailure.invalidPage(int page, int maxPage) {
    return SearchPaginationFailure(
      message: 'Invalid page number requested',
      page: page,
      limit: 0,
      maxPage: maxPage,
    );
  }

  /// Factory constructor for invalid limit
  factory SearchPaginationFailure.invalidLimit(int limit) {
    return SearchPaginationFailure(
      message: 'Invalid page limit requested',
      page: 0,
      limit: limit,
    );
  }

  @override
  List<Object?> get props => [message, page, limit, maxPage];
}

/// Failure when search filter is invalid
class SearchFilterFailure extends SearchFailure {
  /// The invalid filter name
  final String filterName;
  
  /// The invalid filter value
  final dynamic filterValue;
  
  /// Expected filter format or values
  final String expectedFormat;

  const SearchFilterFailure({
    required String message,
    required this.filterName,
    required this.filterValue,
    required this.expectedFormat,
  }) : super(message: message);

  /// Factory constructor for invalid filter
  factory SearchFilterFailure.invalidFilter({
    required String filterName,
    required dynamic filterValue,
    required String expectedFormat,
  }) {
    return SearchFilterFailure(
      message: 'Invalid search filter applied',
      filterName: filterName,
      filterValue: filterValue,
      expectedFormat: expectedFormat,
    );
  }

  @override
  List<Object?> get props => [message, filterName, filterValue, expectedFormat];
}

/// Failure when search database operation fails
class SearchDatabaseFailure extends SearchFailure {
  /// The database operation that failed
  final String operation;
  
  /// The SQL query or operation details
  final String? queryDetails;
  
  /// Database error code if available
  final String? errorCode;

  const SearchDatabaseFailure({
    required String message,
    required this.operation,
    this.queryDetails,
    this.errorCode,
  }) : super(message: message);

  /// Factory constructor for FTS query failure
  factory SearchDatabaseFailure.ftsQueryFailed({
    required String query,
    String? errorCode,
  }) {
    return SearchDatabaseFailure(
      message: 'Full-text search query failed',
      operation: 'FTS_QUERY',
      queryDetails: query,
      errorCode: errorCode,
    );
  }

  /// Factory constructor for index creation failure
  factory SearchDatabaseFailure.indexCreationFailed({
    required String indexName,
    String? errorCode,
  }) {
    return SearchDatabaseFailure(
      message: 'Failed to create search index',
      operation: 'CREATE_INDEX',
      queryDetails: indexName,
      errorCode: errorCode,
    );
  }

  @override
  List<Object?> get props => [message, operation, queryDetails, errorCode];
}

/// Failure when search feature is not available or disabled
class SearchUnavailableFailure extends SearchFailure {
  /// Reason why search is unavailable
  final String reason;
  
  /// Whether this is a temporary issue
  final bool isTemporary;

  const SearchUnavailableFailure({
    required String message,
    required this.reason,
    this.isTemporary = false,
  }) : super(message: message);

  /// Factory constructor for feature disabled
  factory SearchUnavailableFailure.featureDisabled() {
    return const SearchUnavailableFailure(
      message: 'Search functionality is currently disabled',
      reason: 'Feature has been disabled in settings',
      isTemporary: false,
    );
  }

  /// Factory constructor for maintenance mode
  factory SearchUnavailableFailure.maintenanceMode() {
    return const SearchUnavailableFailure(
      message: 'Search is temporarily unavailable due to maintenance',
      reason: 'Search indexes are being rebuilt',
      isTemporary: true,
    );
  }

  @override
  List<Object?> get props => [message, reason, isTemporary];
}
