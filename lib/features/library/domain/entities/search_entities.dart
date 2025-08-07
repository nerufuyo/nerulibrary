import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Search result entity representing a single search match
class SearchResult extends Equatable {
  /// Unique identifier for the result
  final String id;
  
  /// Type of the search result
  final SearchResultType type;
  
  /// Title of the result
  final String title;
  
  /// Description or excerpt
  final String description;
  
  /// Relevance score (0.0 to 1.0)
  final double relevanceScore;
  
  /// Context information (chapter, page, etc.)
  final String? context;
  
  /// Position within the content
  final int? position;
  
  /// Highlighted text snippet
  final String? snippet;
  
  /// Associated book ID
  final String bookId;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.relevanceScore,
    required this.bookId,
    this.context,
    this.position,
    this.snippet,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        relevanceScore,
        context,
        position,
        snippet,
        bookId,
        metadata,
      ];

  /// Create a copy with modified properties
  SearchResult copyWith({
    String? id,
    SearchResultType? type,
    String? title,
    String? description,
    double? relevanceScore,
    String? context,
    int? position,
    String? snippet,
    String? bookId,
    Map<String, dynamic>? metadata,
  }) {
    return SearchResult(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      context: context ?? this.context,
      position: position ?? this.position,
      snippet: snippet ?? this.snippet,
      bookId: bookId ?? this.bookId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'description': description,
      'relevance_score': relevanceScore,
      'context': context,
      'position': position,
      'snippet': snippet,
      'book_id': bookId,
      'metadata': metadata,
    };
  }

  /// Create from map
  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      id: map['id'] as String,
      type: SearchResultType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => SearchResultType.content,
      ),
      title: map['title'] as String,
      description: map['description'] as String,
      relevanceScore: (map['relevance_score'] as num).toDouble(),
      context: map['context'] as String?,
      position: map['position'] as int?,
      snippet: map['snippet'] as String?,
      bookId: map['book_id'] as String,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Types of search results
enum SearchResultType {
  /// Book metadata (title, author, description)
  metadata,
  
  /// Book content (text within the book)
  content,
  
  /// Bookmark
  bookmark,
  
  /// Note/annotation
  note,
  
  /// Chapter or section title
  chapter,
  
  /// Table of contents entry
  tableOfContents,
}

/// Search query configuration
class SearchQuery extends Equatable {
  /// The search text
  final String query;
  
  /// Search filters
  final SearchFilters filters;
  
  /// Pagination configuration
  final SearchPagination pagination;
  
  /// Sorting configuration
  final SearchSort sort;

  const SearchQuery({
    required this.query,
    this.filters = const SearchFilters(),
    this.pagination = const SearchPagination(),
    this.sort = const SearchSort(),
  });

  @override
  List<Object?> get props => [query, filters, pagination, sort];

  /// Create a copy with modified properties
  SearchQuery copyWith({
    String? query,
    SearchFilters? filters,
    SearchPagination? pagination,
    SearchSort? sort,
  }) {
    return SearchQuery(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      pagination: pagination ?? this.pagination,
      sort: sort ?? this.sort,
    );
  }
}

/// Search filters configuration
class SearchFilters extends Equatable {
  /// Filter by book IDs
  final List<String>? bookIds;
  
  /// Filter by result types
  final List<SearchResultType>? resultTypes;
  
  /// Filter by authors
  final List<String>? authors;
  
  /// Filter by genres/categories
  final List<String>? genres;
  
  /// Minimum relevance score
  final double? minRelevanceScore;
  
  /// Date range filter
  final DateTimeRange? dateRange;

  const SearchFilters({
    this.bookIds,
    this.resultTypes,
    this.authors,
    this.genres,
    this.minRelevanceScore,
    this.dateRange,
  });

  @override
  List<Object?> get props => [
        bookIds,
        resultTypes,
        authors,
        genres,
        minRelevanceScore,
        dateRange,
      ];

  /// Create a copy with modified properties
  SearchFilters copyWith({
    List<String>? bookIds,
    List<SearchResultType>? resultTypes,
    List<String>? authors,
    List<String>? genres,
    double? minRelevanceScore,
    DateTimeRange? dateRange,
  }) {
    return SearchFilters(
      bookIds: bookIds ?? this.bookIds,
      resultTypes: resultTypes ?? this.resultTypes,
      authors: authors ?? this.authors,
      genres: genres ?? this.genres,
      minRelevanceScore: minRelevanceScore ?? this.minRelevanceScore,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

/// Search pagination configuration
class SearchPagination extends Equatable {
  /// Current page (0-based)
  final int page;
  
  /// Number of results per page
  final int limit;
  
  /// Offset for results
  final int offset;

  const SearchPagination({
    this.page = 0,
    this.limit = 20,
  }) : offset = page * limit;

  @override
  List<Object?> get props => [page, limit, offset];

  /// Create a copy with modified properties
  SearchPagination copyWith({
    int? page,
    int? limit,
  }) {
    return SearchPagination(
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

/// Search sorting configuration
class SearchSort extends Equatable {
  /// Sort field
  final SearchSortField field;
  
  /// Sort order
  final SearchSortOrder order;

  const SearchSort({
    this.field = SearchSortField.relevance,
    this.order = SearchSortOrder.descending,
  });

  @override
  List<Object?> get props => [field, order];

  /// Create a copy with modified properties
  SearchSort copyWith({
    SearchSortField? field,
    SearchSortOrder? order,
  }) {
    return SearchSort(
      field: field ?? this.field,
      order: order ?? this.order,
    );
  }
}

/// Search sort fields
enum SearchSortField {
  /// Sort by relevance score
  relevance,
  
  /// Sort by title
  title,
  
  /// Sort by date added
  dateAdded,
  
  /// Sort by date modified
  dateModified,
  
  /// Sort by position in book
  position,
}

/// Search sort order
enum SearchSortOrder {
  /// Ascending order
  ascending,
  
  /// Descending order
  descending,
}

/// Search response containing results and metadata
class SearchResponse extends Equatable {
  /// List of search results
  final List<SearchResult> results;
  
  /// Total number of matching results
  final int totalCount;
  
  /// Current page information
  final SearchPagination pagination;
  
  /// Search execution time in milliseconds
  final int executionTimeMs;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const SearchResponse({
    required this.results,
    required this.totalCount,
    required this.pagination,
    required this.executionTimeMs,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        results,
        totalCount,
        pagination,
        executionTimeMs,
        metadata,
      ];

  /// Whether there are more results available
  bool get hasMoreResults {
    final currentOffset = pagination.offset + results.length;
    return currentOffset < totalCount;
  }

  /// Whether this is the first page
  bool get isFirstPage => pagination.page == 0;

  /// Whether this is the last page
  bool get isLastPage => !hasMoreResults;

  /// Create a copy with modified properties
  SearchResponse copyWith({
    List<SearchResult>? results,
    int? totalCount,
    SearchPagination? pagination,
    int? executionTimeMs,
    Map<String, dynamic>? metadata,
  }) {
    return SearchResponse(
      results: results ?? this.results,
      totalCount: totalCount ?? this.totalCount,
      pagination: pagination ?? this.pagination,
      executionTimeMs: executionTimeMs ?? this.executionTimeMs,
      metadata: metadata ?? this.metadata,
    );
  }
}
