import 'dart:async';
import 'dart:collection';

import 'package:sqflite/sqflite.dart';

import '../services/performance_service.dart';

/// Database query optimization and caching service
/// 
/// Provides intelligent query caching, batch operations,
/// and performance monitoring for database operations.
class DatabaseOptimizer {
  static DatabaseOptimizer? _instance;
  static DatabaseOptimizer get instance => _instance ??= DatabaseOptimizer._();
  
  DatabaseOptimizer._();
  
  // Query cache
  final LRUCache<String, dynamic> _queryCache = LRUCache<String, dynamic>(maxSize: 100);
  
  // Batch operation queue
  final List<BatchOperation> _batchQueue = [];
  Timer? _batchTimer;
  
  // Connection pool
  Database? _database;
  
  /// Initialize database optimizer
  Future<void> initialize(Database database) async {
    _database = database;
    _startBatchProcessor();
    await _createOptimizedIndexes();
  }
  
  /// Execute optimized query with caching
  Future<T> executeQuery<T>({
    required String sql,
    List<Object?>? arguments,
    required T Function(List<Map<String, Object?>>) parser,
    Duration? cacheTimeout,
    bool useCache = true,
  }) async {
    final cacheKey = _generateCacheKey(sql, arguments);
    
    // Check cache first
    if (useCache && _queryCache.containsKey(cacheKey)) {
      final cachedResult = _queryCache.get(cacheKey);
      if (cachedResult != null && !_isCacheExpired(cachedResult)) {
        PerformanceService.instance.recordMetric(PerformanceMetric(
          name: 'database_cache_hit',
          value: 1,
          unit: 'count',
          timestamp: DateTime.now(),
          metadata: {'query_type': _getQueryType(sql)},
        ));
        return cachedResult['data'] as T;
      }
    }
    
    // Execute query with performance monitoring
    PerformanceService.instance.startTiming('database_query');
    
    try {
      final stopwatch = Stopwatch()..start();
      final rawResult = await _database!.rawQuery(sql, arguments);
      stopwatch.stop();
      
      final result = parser(rawResult);
      
      // Cache result if enabled
      if (useCache) {
        _queryCache.put(cacheKey, {
          'data': result,
          'timestamp': DateTime.now(),
          'timeout': cacheTimeout ?? const Duration(minutes: 5),
        });
      }
      
      // Record performance metrics
      PerformanceService.instance.stopTiming('database_query', metadata: {
        'query_type': _getQueryType(sql),
        'execution_time_ms': stopwatch.elapsedMilliseconds,
        'result_count': rawResult.length,
        'cache_used': false,
      });
      
      return result;
      
    } catch (error) {
      PerformanceService.instance.stopTiming('database_query', metadata: {
        'query_type': _getQueryType(sql),
        'error': error.toString(),
      });
      rethrow;
    }
  }
  
  /// Add operation to batch queue
  void addToBatch(BatchOperation operation) {
    _batchQueue.add(operation);
    
    // Execute batch if queue is full
    if (_batchQueue.length >= 50) {
      _executeBatch();
    }
  }
  
  /// Execute all queued batch operations
  Future<void> _executeBatch() async {
    if (_batchQueue.isEmpty || _database == null) return;
    
    PerformanceService.instance.startTiming('batch_operations');
    
    final operations = List<BatchOperation>.from(_batchQueue);
    _batchQueue.clear();
    
    try {
      await _database!.transaction((txn) async {
        final batch = txn.batch();
        
        for (final operation in operations) {
          switch (operation.type) {
            case BatchOperationType.insert:
              batch.insert(operation.table, operation.data!);
              break;
            case BatchOperationType.update:
              batch.update(
                operation.table,
                operation.data!,
                where: operation.where,
                whereArgs: operation.whereArgs,
              );
              break;
            case BatchOperationType.delete:
              batch.delete(
                operation.table,
                where: operation.where,
                whereArgs: operation.whereArgs,
              );
              break;
          }
        }
        
        await batch.commit(noResult: true);
      });
      
      PerformanceService.instance.stopTiming('batch_operations', metadata: {
        'operation_count': operations.length,
        'success': true,
      });
      
    } catch (error) {
      PerformanceService.instance.stopTiming('batch_operations', metadata: {
        'operation_count': operations.length,
        'error': error.toString(),
        'success': false,
      });
      rethrow;
    }
  }
  
  /// Start batch processor timer
  void _startBatchProcessor() {
    _batchTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _executeBatch(),
    );
  }
  
  /// Create optimized database indexes
  Future<void> _createOptimizedIndexes() async {
    if (_database == null) return;
    
    PerformanceService.instance.startTiming('index_creation');
    
    try {
      // Book indexes for faster searches
      await _database!.execute(
        'CREATE INDEX IF NOT EXISTS idx_books_title ON books(title)',
      );
      await _database!.execute(
        'CREATE INDEX IF NOT EXISTS idx_books_author ON books(author)',
      );
      await _database!.execute(
        'CREATE INDEX IF NOT EXISTS idx_books_category ON books(category_id)',
      );
      await _database!.execute(
        'CREATE INDEX IF NOT EXISTS idx_books_updated ON books(updated_at)',
      );
      
      // Reading progress indexes
      await _database!.execute(
        'CREATE INDEX IF NOT EXISTS idx_reading_progress_book ON reading_progress(book_id)',
      );
      await _database!.execute(
        'CREATE INDEX IF NOT EXISTS idx_reading_progress_updated ON reading_progress(updated_at)',
      );
      
      // Bookmark indexes
      await _database!.execute(
        'CREATE INDEX IF NOT EXISTS idx_bookmarks_book ON bookmarks(book_id)',
      );
      await _database!.execute(
        'CREATE INDEX IF NOT EXISTS idx_bookmarks_type ON bookmarks(type)',
      );
      
      // Search indexes for full-text search
      await _database!.execute(
        'CREATE INDEX IF NOT EXISTS idx_books_fts ON books_fts(title, author, description)',
      );
      
      PerformanceService.instance.stopTiming('index_creation', metadata: {
        'indexes_created': 8,
        'success': true,
      });
      
    } catch (error) {
      PerformanceService.instance.stopTiming('index_creation', metadata: {
        'error': error.toString(),
        'success': false,
      });
      // Don't rethrow - indexes are optimization, not critical
    }
  }
  
  /// Clear query cache
  void clearCache() {
    _queryCache.clear();
    PerformanceService.instance.recordMetric(PerformanceMetric(
      name: 'database_cache_cleared',
      value: 1,
      unit: 'count',
      timestamp: DateTime.now(),
      metadata: {},
    ));
  }
  
  /// Get cache statistics
  CacheStatistics getCacheStatistics() {
    return CacheStatistics(
      size: _queryCache.length,
      maxSize: _queryCache.maxSize,
      hitRate: _queryCache.hitRate,
      missRate: _queryCache.missRate,
    );
  }
  
  /// Generate cache key for query
  String _generateCacheKey(String sql, List<Object?>? arguments) {
    final args = arguments?.join(',') ?? '';
    return '${sql.hashCode}_${args.hashCode}';
  }
  
  /// Check if cached result is expired
  bool _isCacheExpired(Map<String, dynamic> cachedResult) {
    final timestamp = cachedResult['timestamp'] as DateTime;
    final timeout = cachedResult['timeout'] as Duration;
    return DateTime.now().difference(timestamp) > timeout;
  }
  
  /// Get query type from SQL
  String _getQueryType(String sql) {
    final normalizedSql = sql.trim().toLowerCase();
    if (normalizedSql.startsWith('select')) return 'select';
    if (normalizedSql.startsWith('insert')) return 'insert';
    if (normalizedSql.startsWith('update')) return 'update';
    if (normalizedSql.startsWith('delete')) return 'delete';
    return 'other';
  }
  
  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _queryCache.clear();
    _batchQueue.clear();
  }
}

/// LRU Cache implementation for query caching
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();
  int _hits = 0;
  int _misses = 0;
  
  LRUCache({required this.maxSize});
  
  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
      _hits++;
      return value;
    }
    _misses++;
    return null;
  }
  
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }
  
  bool containsKey(K key) => _cache.containsKey(key);
  
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }
  
  int get length => _cache.length;
  
  double get hitRate {
    final total = _hits + _misses;
    return total > 0 ? _hits / total : 0.0;
  }
  
  double get missRate {
    final total = _hits + _misses;
    return total > 0 ? _misses / total : 0.0;
  }
}

/// Batch operation for database optimization
class BatchOperation {
  final BatchOperationType type;
  final String table;
  final Map<String, Object?>? data;
  final String? where;
  final List<Object?>? whereArgs;
  
  const BatchOperation({
    required this.type,
    required this.table,
    this.data,
    this.where,
    this.whereArgs,
  });
}

/// Batch operation types
enum BatchOperationType {
  insert,
  update,
  delete,
}

/// Cache statistics
class CacheStatistics {
  final int size;
  final int maxSize;
  final double hitRate;
  final double missRate;
  
  const CacheStatistics({
    required this.size,
    required this.maxSize,
    required this.hitRate,
    required this.missRate,
  });
  
  @override
  String toString() {
    return '''
Cache Statistics:
- Size: $size/$maxSize
- Hit Rate: ${(hitRate * 100).toStringAsFixed(1)}%
- Miss Rate: ${(missRate * 100).toStringAsFixed(1)}%
''';
  }
}
