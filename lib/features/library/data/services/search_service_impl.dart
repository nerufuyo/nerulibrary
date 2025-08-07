import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/search_entities.dart';
import '../../domain/failures/search_failures.dart';
import '../../domain/services/search_service.dart';

/// SQLite FTS implementation of the search service
/// 
/// Provides comprehensive search functionality using SQLite's
/// Full-Text Search (FTS) capabilities for optimal performance.
class SearchServiceImpl implements SearchService {
  /// Database instance for search operations
  final Database _database;
  
  /// Cache for search suggestions
  final Map<String, List<String>> _suggestionsCache = {};
  
  /// Cache for recent searches
  List<String> _recentSearches = [];
  
  /// Search timeout duration
  static const Duration _searchTimeout = Duration(seconds: 30);
  
  /// Maximum number of suggestions to return
  static const int _maxSuggestions = 10;
  
  /// Maximum number of recent searches to keep
  static const int _maxRecentSearches = 50;

  SearchServiceImpl({required Database database}) : _database = database;

  @override
  Future<Either<Failure, void>> initializeSearchIndexes() async {
    try {
      await _createSearchTables();
      await _createFTSIndexes();
      await _loadRecentSearches();
      return const Right(null);
    } catch (e) {
      return Left(SearchIndexFailure.creationFailed(
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, SearchResponse>> search(SearchQuery query) async {
    try {
      final validationResult = _validateQuery(query);
      if (validationResult != null) {
        return Left(validationResult);
      }

      final startTime = DateTime.now();
      
      // Perform search across all content types
      final futures = <Future<List<SearchResult>>>[
        _searchInMetadata(query),
        _searchInContent(query),
        _searchInBookmarks(query),
        _searchInNotes(query),
      ];

      final results = await Future.wait(futures).timeout(_searchTimeout);
      
      // Combine and rank results
      final allResults = <SearchResult>[];
      for (final resultList in results) {
        allResults.addAll(resultList);
      }

      // Sort by relevance and apply pagination
      final sortedResults = _sortResults(allResults, query.sort);
      final paginatedResults = _applyPagination(sortedResults, query.pagination);
      
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      final response = SearchResponse(
        results: paginatedResults,
        totalCount: sortedResults.length,
        pagination: query.pagination,
        executionTimeMs: executionTime,
      );

      return Right(response);
    } on TimeoutException {
      return Left(SearchTimeoutFailure.defaultTimeout(query.query));
    } catch (e) {
      return Left(SearchDatabaseFailure.ftsQueryFailed(
        query: query.query,
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, SearchResponse>> searchMetadata(SearchQuery query) async {
    try {
      final validationResult = _validateQuery(query);
      if (validationResult != null) {
        return Left(validationResult);
      }

      final startTime = DateTime.now();
      final results = await _searchInMetadata(query);
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      final sortedResults = _sortResults(results, query.sort);
      final paginatedResults = _applyPagination(sortedResults, query.pagination);

      final response = SearchResponse(
        results: paginatedResults,
        totalCount: sortedResults.length,
        pagination: query.pagination,
        executionTimeMs: executionTime,
      );

      return Right(response);
    } catch (e) {
      return Left(SearchDatabaseFailure.ftsQueryFailed(
        query: query.query,
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, SearchResponse>> searchContent(SearchQuery query) async {
    try {
      final validationResult = _validateQuery(query);
      if (validationResult != null) {
        return Left(validationResult);
      }

      final startTime = DateTime.now();
      final results = await _searchInContent(query);
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      final sortedResults = _sortResults(results, query.sort);
      final paginatedResults = _applyPagination(sortedResults, query.pagination);

      final response = SearchResponse(
        results: paginatedResults,
        totalCount: sortedResults.length,
        pagination: query.pagination,
        executionTimeMs: executionTime,
      );

      return Right(response);
    } catch (e) {
      return Left(SearchDatabaseFailure.ftsQueryFailed(
        query: query.query,
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, SearchResponse>> searchBookmarks(SearchQuery query) async {
    try {
      final validationResult = _validateQuery(query);
      if (validationResult != null) {
        return Left(validationResult);
      }

      final startTime = DateTime.now();
      final results = await _searchInBookmarks(query);
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      final sortedResults = _sortResults(results, query.sort);
      final paginatedResults = _applyPagination(sortedResults, query.pagination);

      final response = SearchResponse(
        results: paginatedResults,
        totalCount: sortedResults.length,
        pagination: query.pagination,
        executionTimeMs: executionTime,
      );

      return Right(response);
    } catch (e) {
      return Left(SearchDatabaseFailure.ftsQueryFailed(
        query: query.query,
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, SearchResponse>> searchNotes(SearchQuery query) async {
    try {
      final validationResult = _validateQuery(query);
      if (validationResult != null) {
        return Left(validationResult);
      }

      final startTime = DateTime.now();
      final results = await _searchInNotes(query);
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      final sortedResults = _sortResults(results, query.sort);
      final paginatedResults = _applyPagination(sortedResults, query.pagination);

      final response = SearchResponse(
        results: paginatedResults,
        totalCount: sortedResults.length,
        pagination: query.pagination,
        executionTimeMs: executionTime,
      );

      return Right(response);
    } catch (e) {
      return Left(SearchDatabaseFailure.ftsQueryFailed(
        query: query.query,
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSearchSuggestions(String partialQuery) async {
    try {
      if (partialQuery.trim().isEmpty) {
        return const Right([]);
      }

      // Check cache first
      if (_suggestionsCache.containsKey(partialQuery)) {
        return Right(_suggestionsCache[partialQuery]!);
      }

      final suggestions = await _generateSuggestions(partialQuery);
      
      // Cache the results
      _suggestionsCache[partialQuery] = suggestions;
      
      return Right(suggestions);
    } catch (e) {
      return Left(SearchDatabaseFailure.ftsQueryFailed(
        query: partialQuery,
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getRecentSearches() async {
    try {
      return Right(List.from(_recentSearches));
    } catch (e) {
      return Left(SearchDatabaseFailure(
        message: 'Failed to get recent searches',
        operation: 'GET_RECENT_SEARCHES',
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> saveSearchToHistory(String query) async {
    try {
      if (query.trim().isEmpty) {
        return const Right(null);
      }

      // Remove existing instance if present
      _recentSearches.remove(query);
      
      // Add to the beginning
      _recentSearches.insert(0, query);
      
      // Limit the size
      if (_recentSearches.length > _maxRecentSearches) {
        _recentSearches = _recentSearches.take(_maxRecentSearches).toList();
      }

      // Save to database
      await _saveRecentSearches();
      
      return const Right(null);
    } catch (e) {
      return Left(SearchDatabaseFailure(
        message: 'Failed to save search to history',
        operation: 'SAVE_SEARCH_HISTORY',
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> clearSearchHistory() async {
    try {
      _recentSearches.clear();
      await _saveRecentSearches();
      return const Right(null);
    } catch (e) {
      return Left(SearchDatabaseFailure(
        message: 'Failed to clear search history',
        operation: 'CLEAR_SEARCH_HISTORY',
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> indexBook({
    required String bookId,
    required String filePath,
    required String format,
  }) async {
    try {
      // This is a placeholder for book indexing
      // In a real implementation, this would:
      // 1. Extract text content from the book file
      // 2. Process and clean the text
      // 3. Insert into FTS tables
      // 4. Extract metadata and index it
      
      // For now, we'll insert a placeholder entry
      await _database.insert(
        'search_content_fts',
        {
          'book_id': bookId,
          'content': 'Placeholder content for book $bookId',
          'chapter': 'Chapter 1',
          'position': 0,
          'indexed_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return const Right(null);
    } catch (e) {
      return Left(SearchDatabaseFailure(
        message: 'Failed to index book',
        operation: 'INDEX_BOOK',
        queryDetails: 'bookId: $bookId, format: $format',
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> removeBookFromIndex(String bookId) async {
    try {
      // Remove from all search tables
      await _database.delete(
        'search_metadata_fts',
        where: 'book_id = ?',
        whereArgs: [bookId],
      );
      
      await _database.delete(
        'search_content_fts',
        where: 'book_id = ?',
        whereArgs: [bookId],
      );

      return const Right(null);
    } catch (e) {
      return Left(SearchDatabaseFailure(
        message: 'Failed to remove book from index',
        operation: 'REMOVE_FROM_INDEX',
        queryDetails: 'bookId: $bookId',
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> updateBookIndex({
    required String bookId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (metadata != null) {
        await _database.update(
          'search_metadata_fts',
          {
            'title': metadata['title'],
            'author': metadata['author'],
            'description': metadata['description'],
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'book_id = ?',
          whereArgs: [bookId],
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(SearchDatabaseFailure(
        message: 'Failed to update book index',
        operation: 'UPDATE_INDEX',
        queryDetails: 'bookId: $bookId',
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> rebuildSearchIndexes() async {
    try {
      // Drop existing FTS tables
      await _database.execute('DROP TABLE IF EXISTS search_metadata_fts');
      await _database.execute('DROP TABLE IF EXISTS search_content_fts');
      await _database.execute('DROP TABLE IF EXISTS search_bookmarks_fts');
      await _database.execute('DROP TABLE IF EXISTS search_notes_fts');

      // Recreate FTS tables
      await _createFTSIndexes();

      return const Right(null);
    } catch (e) {
      return Left(SearchIndexFailure.creationFailed(
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSearchStatistics() async {
    try {
      final stats = <String, dynamic>{};

      // Count indexed books
      final metadataCount = await _database.rawQuery(
        'SELECT COUNT(DISTINCT book_id) as count FROM search_metadata_fts'
      );
      stats['indexed_books'] = metadataCount.first['count'] ?? 0;

      // Count content entries
      final contentCount = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM search_content_fts'
      );
      stats['content_entries'] = contentCount.first['count'] ?? 0;

      // Database size (simplified)
      stats['database_size_mb'] = 'N/A'; // Would require platform-specific code

      return Right(stats);
    } catch (e) {
      return Left(SearchDatabaseFailure(
        message: 'Failed to get search statistics',
        operation: 'GET_STATISTICS',
        errorCode: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> optimizeSearchIndexes() async {
    try {
      // Optimize FTS indexes
      await _database.execute('INSERT INTO search_metadata_fts(search_metadata_fts) VALUES(\'optimize\')');
      await _database.execute('INSERT INTO search_content_fts(search_content_fts) VALUES(\'optimize\')');
      await _database.execute('INSERT INTO search_bookmarks_fts(search_bookmarks_fts) VALUES(\'optimize\')');
      await _database.execute('INSERT INTO search_notes_fts(search_notes_fts) VALUES(\'optimize\')');

      return const Right(null);
    } catch (e) {
      return Left(SearchIndexFailure(
        message: 'Failed to optimize search indexes',
        errorType: SearchIndexErrorType.optimizationFailed,
        technicalDetails: e.toString(),
      ));
    }
  }

  // Private helper methods

  /// Create search-related tables
  Future<void> _createSearchTables() async {
    // Table for search history
    await _database.execute('''
      CREATE TABLE IF NOT EXISTS search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(query)
      )
    ''');

    // Table for search settings/preferences
    await _database.execute('''
      CREATE TABLE IF NOT EXISTS search_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Create FTS (Full-Text Search) indexes
  Future<void> _createFTSIndexes() async {
    // FTS table for book metadata
    await _database.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS search_metadata_fts USING fts5(
        book_id,
        title,
        author,
        description,
        genre,
        language,
        indexed_at,
        content='',
        content_rowid='rowid'
      )
    ''');

    // FTS table for book content
    await _database.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS search_content_fts USING fts5(
        book_id,
        content,
        chapter,
        position,
        page_number,
        indexed_at,
        content='',
        content_rowid='rowid'
      )
    ''');

    // FTS table for bookmarks
    await _database.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS search_bookmarks_fts USING fts5(
        book_id,
        bookmark_text,
        note,
        chapter,
        position,
        created_at,
        content='',
        content_rowid='rowid'
      )
    ''');

    // FTS table for notes
    await _database.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS search_notes_fts USING fts5(
        book_id,
        note_content,
        note_title,
        tags,
        chapter,
        position,
        created_at,
        content='',
        content_rowid='rowid'
      )
    ''');
  }

  /// Validate search query
  InvalidSearchQueryFailure? _validateQuery(SearchQuery query) {
    if (query.query.trim().isEmpty) {
      return InvalidSearchQueryFailure.emptyQuery();
    }

    if (query.query.trim().length < 2) {
      return InvalidSearchQueryFailure.queryTooShort(query.query);
    }

    return null;
  }

  /// Search in book metadata
  Future<List<SearchResult>> _searchInMetadata(SearchQuery query) async {
    final ftsQuery = _prepareFTSQuery(query.query);
    
    final List<Map<String, dynamic>> results = await _database.rawQuery('''
      SELECT 
        book_id,
        title,
        author,
        description,
        bm25(search_metadata_fts) as relevance_score
      FROM search_metadata_fts 
      WHERE search_metadata_fts MATCH ?
      ORDER BY bm25(search_metadata_fts)
    ''', [ftsQuery]);

    return results.map((row) => SearchResult(
      id: '${row['book_id']}_metadata',
      type: SearchResultType.metadata,
      title: row['title'] ?? '',
      description: row['description'] ?? '',
      relevanceScore: _normalizeRelevanceScore(row['relevance_score']),
      bookId: row['book_id'],
      context: 'Book metadata',
    )).toList();
  }

  /// Search in book content
  Future<List<SearchResult>> _searchInContent(SearchQuery query) async {
    final ftsQuery = _prepareFTSQuery(query.query);
    
    final List<Map<String, dynamic>> results = await _database.rawQuery('''
      SELECT 
        book_id,
        content,
        chapter,
        position,
        bm25(search_content_fts) as relevance_score
      FROM search_content_fts 
      WHERE search_content_fts MATCH ?
      ORDER BY bm25(search_content_fts)
    ''', [ftsQuery]);

    return results.map((row) => SearchResult(
      id: '${row['book_id']}_content_${row['position']}',
      type: SearchResultType.content,
      title: row['chapter'] ?? 'Content',
      description: _extractSnippet(row['content'], query.query),
      relevanceScore: _normalizeRelevanceScore(row['relevance_score']),
      bookId: row['book_id'],
      context: row['chapter'],
      position: row['position'],
      snippet: _extractSnippet(row['content'], query.query),
    )).toList();
  }

  /// Search in bookmarks
  Future<List<SearchResult>> _searchInBookmarks(SearchQuery query) async {
    final ftsQuery = _prepareFTSQuery(query.query);
    
    final List<Map<String, dynamic>> results = await _database.rawQuery('''
      SELECT 
        book_id,
        bookmark_text,
        note,
        chapter,
        position,
        bm25(search_bookmarks_fts) as relevance_score
      FROM search_bookmarks_fts 
      WHERE search_bookmarks_fts MATCH ?
      ORDER BY bm25(search_bookmarks_fts)
    ''', [ftsQuery]);

    return results.map((row) => SearchResult(
      id: '${row['book_id']}_bookmark_${row['position']}',
      type: SearchResultType.bookmark,
      title: 'Bookmark',
      description: row['note'] ?? row['bookmark_text'] ?? '',
      relevanceScore: _normalizeRelevanceScore(row['relevance_score']),
      bookId: row['book_id'],
      context: row['chapter'],
      position: row['position'],
    )).toList();
  }

  /// Search in notes
  Future<List<SearchResult>> _searchInNotes(SearchQuery query) async {
    final ftsQuery = _prepareFTSQuery(query.query);
    
    final List<Map<String, dynamic>> results = await _database.rawQuery('''
      SELECT 
        book_id,
        note_content,
        note_title,
        chapter,
        position,
        bm25(search_notes_fts) as relevance_score
      FROM search_notes_fts 
      WHERE search_notes_fts MATCH ?
      ORDER BY bm25(search_notes_fts)
    ''', [ftsQuery]);

    return results.map((row) => SearchResult(
      id: '${row['book_id']}_note_${row['position']}',
      type: SearchResultType.note,
      title: row['note_title'] ?? 'Note',
      description: row['note_content'] ?? '',
      relevanceScore: _normalizeRelevanceScore(row['relevance_score']),
      bookId: row['book_id'],
      context: row['chapter'],
      position: row['position'],
    )).toList();
  }

  /// Generate search suggestions
  Future<List<String>> _generateSuggestions(String partialQuery) async {
    // Get suggestions from recent searches
    final recentSuggestions = _recentSearches
        .where((search) => search.toLowerCase().contains(partialQuery.toLowerCase()))
        .take(_maxSuggestions ~/ 2)
        .toList();

    // Get suggestions from indexed content (simplified)
    final contentSuggestions = <String>[];
    
    final suggestions = <String>[];
    suggestions.addAll(recentSuggestions);
    suggestions.addAll(contentSuggestions);

    return suggestions.take(_maxSuggestions).toList();
  }

  /// Prepare FTS query with proper escaping
  String _prepareFTSQuery(String query) {
    // Escape special FTS characters and prepare query
    final escapedQuery = query.replaceAll('"', '""');
    return '"$escapedQuery"';
  }

  /// Normalize relevance score from BM25 to 0.0-1.0 range
  double _normalizeRelevanceScore(dynamic score) {
    if (score == null) return 0.0;
    
    final numScore = score is num ? score.toDouble() : 0.0;
    
    // BM25 scores are typically negative, with higher (less negative) scores being more relevant
    // Normalize to 0.0-1.0 range
    return (numScore + 10.0) / 10.0; // Simple normalization, adjust based on actual score ranges
  }

  /// Extract text snippet around search term
  String _extractSnippet(String content, String searchTerm) {
    const snippetLength = 150;
    
    if (content.length <= snippetLength) {
      return content;
    }

    final index = content.toLowerCase().indexOf(searchTerm.toLowerCase());
    if (index == -1) {
      return content.substring(0, snippetLength) + '...';
    }

    final start = (index - snippetLength ~/ 2).clamp(0, content.length);
    final end = (start + snippetLength).clamp(0, content.length);
    
    final snippet = content.substring(start, end);
    return '${start > 0 ? '...' : ''}$snippet${end < content.length ? '...' : ''}';
  }

  /// Sort search results based on sort configuration
  List<SearchResult> _sortResults(List<SearchResult> results, SearchSort sort) {
    switch (sort.field) {
      case SearchSortField.relevance:
        results.sort((a, b) => sort.order == SearchSortOrder.ascending
            ? a.relevanceScore.compareTo(b.relevanceScore)
            : b.relevanceScore.compareTo(a.relevanceScore));
        break;
      case SearchSortField.title:
        results.sort((a, b) => sort.order == SearchSortOrder.ascending
            ? a.title.compareTo(b.title)
            : b.title.compareTo(a.title));
        break;
      case SearchSortField.position:
        results.sort((a, b) {
          final aPos = a.position ?? 0;
          final bPos = b.position ?? 0;
          return sort.order == SearchSortOrder.ascending
              ? aPos.compareTo(bPos)
              : bPos.compareTo(aPos);
        });
        break;
      default:
        // Default to relevance
        results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    }

    return results;
  }

  /// Apply pagination to results
  List<SearchResult> _applyPagination(List<SearchResult> results, SearchPagination pagination) {
    final start = pagination.offset;
    final end = (start + pagination.limit).clamp(0, results.length);
    
    if (start >= results.length) {
      return [];
    }
    
    return results.sublist(start, end);
  }

  /// Load recent searches from database
  Future<void> _loadRecentSearches() async {
    try {
      final results = await _database.query(
        'search_history',
        orderBy: 'created_at DESC',
        limit: _maxRecentSearches,
      );

      _recentSearches = results
          .map((row) => row['query'] as String)
          .toList();
    } catch (e) {
      // If loading fails, start with empty list
      _recentSearches = [];
    }
  }

  /// Save recent searches to database
  Future<void> _saveRecentSearches() async {
    // Clear existing history
    await _database.delete('search_history');

    // Insert current history
    final batch = _database.batch();
    for (final query in _recentSearches) {
      batch.insert('search_history', {
        'query': query,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
  }
}
