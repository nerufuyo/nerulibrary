import 'package:dartz/dartz.dart';

import '../entities/sync_entities.dart';
import '../failures/sync_failures.dart';

/// Conflict resolution service for handling synchronization conflicts
///
/// Provides intelligent conflict detection and resolution strategies
/// for different types of data conflicts during synchronization.
abstract class ConflictResolver {
  /// Detect conflict between local and remote data
  ///
  /// [localData] - local version of the data
  /// [remoteData] - remote version of the data
  /// [entityType] - type of entity being compared
  /// Returns [SyncConflict] if conflict detected, null otherwise.
  SyncConflict? detectConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    String entityType,
  );

  /// Resolve conflict automatically using specified strategy
  ///
  /// [conflict] - conflict to resolve
  /// [strategy] - resolution strategy to apply
  /// Returns resolved data or [SyncFailure] if resolution fails.
  Either<SyncFailure, Map<String, dynamic>> resolveConflict(
    SyncConflict conflict,
    ConflictResolution strategy,
  );

  /// Get recommended resolution strategy for a conflict
  ///
  /// [conflict] - conflict to analyze
  /// Returns recommended [ConflictResolution] strategy.
  ConflictResolution getRecommendedResolution(SyncConflict conflict);

  /// Check if conflict can be resolved automatically
  ///
  /// [conflict] - conflict to check
  /// Returns [true] if automatic resolution is possible.
  bool canResolveAutomatically(SyncConflict conflict);

  /// Merge local and remote data intelligently
  ///
  /// [localData] - local version of the data
  /// [remoteData] - remote version of the data
  /// [entityType] - type of entity being merged
  /// Returns merged data or [SyncFailure] if merge fails.
  Either<SyncFailure, Map<String, dynamic>> mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    String entityType,
  );
}

/// Default implementation of conflict resolver
class DefaultConflictResolver implements ConflictResolver {
  @override
  SyncConflict? detectConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    String entityType,
  ) {
    // Extract timestamps for comparison
    final localUpdatedAt = _extractTimestamp(localData, 'updatedAt') ??
        _extractTimestamp(localData, 'updated_at');
    final remoteUpdatedAt = _extractTimestamp(remoteData, 'updatedAt') ??
        _extractTimestamp(remoteData, 'updated_at');

    if (localUpdatedAt == null || remoteUpdatedAt == null) {
      // If we can't determine timestamps, assume no conflict
      return null;
    }

    // Check for concurrent modifications (within 1 second tolerance)
    final timeDifference = localUpdatedAt.difference(remoteUpdatedAt).abs();
    if (timeDifference.inSeconds <= 1) {
      // Times are very close, check for data differences
      if (_hasDataDifferences(localData, remoteData, entityType)) {
        return SyncConflict(
          id: '$entityType_${localData['id']}_${DateTime.now().millisecondsSinceEpoch}',
          entityType: entityType,
          entityId: localData['id']?.toString() ??
              remoteData['id']?.toString() ??
              'unknown',
          localData: localData,
          remoteData: remoteData,
          localUpdatedAt: localUpdatedAt,
          remoteUpdatedAt: remoteUpdatedAt,
          conflictDetectedAt: DateTime.now(),
        );
      }
    }

    return null;
  }

  @override
  Either<SyncFailure, Map<String, dynamic>> resolveConflict(
    SyncConflict conflict,
    ConflictResolution strategy,
  ) {
    try {
      switch (strategy) {
        case ConflictResolution.useLocal:
          return Right(Map<String, dynamic>.from(conflict.localData));

        case ConflictResolution.useRemote:
          return Right(Map<String, dynamic>.from(conflict.remoteData));

        case ConflictResolution.merge:
          return mergeData(
              conflict.localData, conflict.remoteData, conflict.entityType);

        case ConflictResolution.manual:
          return const Left(SyncConflictFailure(
            message: 'Manual resolution required',
            entityType: 'unknown',
            entityId: 'unknown',
            conflictData: {},
          ));
      }
    } catch (e) {
      return Left(SyncDataFailure(
          message: 'Failed to resolve conflict: ${e.toString()}'));
    }
  }

  @override
  ConflictResolution getRecommendedResolution(SyncConflict conflict) {
    // For reading progress, prefer the most recent
    if (conflict.entityType == 'reading_progress') {
      return conflict.remoteIsNewer
          ? ConflictResolution.useRemote
          : ConflictResolution.useLocal;
    }

    // For bookmarks and notes, try to merge
    if (conflict.entityType == 'bookmark' || conflict.entityType == 'note') {
      return ConflictResolution.merge;
    }

    // For books and metadata, prefer remote (assuming it's more authoritative)
    if (conflict.entityType == 'book' ||
        conflict.entityType == 'author' ||
        conflict.entityType == 'category') {
      return ConflictResolution.useRemote;
    }

    // For collections, prefer local (user's personal collections)
    if (conflict.entityType == 'collection') {
      return ConflictResolution.useLocal;
    }

    // Default to newer version
    return conflict.remoteIsNewer
        ? ConflictResolution.useRemote
        : ConflictResolution.useLocal;
  }

  @override
  bool canResolveAutomatically(SyncConflict conflict) {
    // Some entity types can be resolved automatically
    final autoResolvableTypes = [
      'reading_progress',
      'book',
      'author',
      'category',
    ];

    if (autoResolvableTypes.contains(conflict.entityType)) {
      return true;
    }

    // Check if one version is clearly newer (more than 5 minutes difference)
    final timeDifference =
        conflict.localUpdatedAt.difference(conflict.remoteUpdatedAt).abs();
    return timeDifference.inMinutes > 5;
  }

  @override
  Either<SyncFailure, Map<String, dynamic>> mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    String entityType,
  ) {
    try {
      switch (entityType) {
        case 'reading_progress':
          return _mergeReadingProgress(localData, remoteData);

        case 'bookmark':
          return _mergeBookmark(localData, remoteData);

        case 'note':
          return _mergeNote(localData, remoteData);

        case 'collection':
          return _mergeCollection(localData, remoteData);

        default:
          // For other types, use the newer version
          final localTime = _extractTimestamp(localData, 'updatedAt') ??
              _extractTimestamp(localData, 'updated_at');
          final remoteTime = _extractTimestamp(remoteData, 'updatedAt') ??
              _extractTimestamp(remoteData, 'updated_at');

          if (remoteTime != null &&
              (localTime == null || remoteTime.isAfter(localTime))) {
            return Right(Map<String, dynamic>.from(remoteData));
          } else {
            return Right(Map<String, dynamic>.from(localData));
          }
      }
    } catch (e) {
      return Left(
          SyncDataFailure(message: 'Failed to merge data: ${e.toString()}'));
    }
  }

  /// Extract timestamp from data map
  DateTime? _extractTimestamp(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;

    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);

    return null;
  }

  /// Check if there are meaningful data differences
  bool _hasDataDifferences(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    String entityType,
  ) {
    // Ignore timestamp fields for comparison
    final ignoreFields = [
      'updatedAt',
      'updated_at',
      'createdAt',
      'created_at',
      'lastSyncAt'
    ];

    for (final key in localData.keys) {
      if (ignoreFields.contains(key)) continue;

      if (!remoteData.containsKey(key) || localData[key] != remoteData[key]) {
        return true;
      }
    }

    for (final key in remoteData.keys) {
      if (ignoreFields.contains(key)) continue;

      if (!localData.containsKey(key)) {
        return true;
      }
    }

    return false;
  }

  /// Merge reading progress data
  Either<SyncFailure, Map<String, dynamic>> _mergeReadingProgress(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = Map<String, dynamic>.from(local);

    // Use the highest progress value
    final localProgress =
        (local['progressPercentage'] as num?)?.toDouble() ?? 0.0;
    final remoteProgress =
        (remote['progressPercentage'] as num?)?.toDouble() ?? 0.0;

    if (remoteProgress > localProgress) {
      merged['progressPercentage'] = remoteProgress;
      merged['currentPage'] = remote['currentPage'];
      merged['lastPosition'] = remote['lastPosition'];
    }

    // Sum reading times
    final localTime = (local['readingTimeMinutes'] as int?) ?? 0;
    final remoteTime = (remote['readingTimeMinutes'] as int?) ?? 0;
    merged['readingTimeMinutes'] = localTime + remoteTime;

    // Use latest timestamp
    final localUpdated = _extractTimestamp(local, 'updatedAt');
    final remoteUpdated = _extractTimestamp(remote, 'updatedAt');

    if (remoteUpdated != null &&
        (localUpdated == null || remoteUpdated.isAfter(localUpdated))) {
      merged['updatedAt'] = remoteUpdated.toIso8601String();
    }

    return Right(merged);
  }

  /// Merge bookmark data
  Either<SyncFailure, Map<String, dynamic>> _mergeBookmark(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // For bookmarks, prefer remote if it has more recent updates
    final localUpdated = _extractTimestamp(local, 'updatedAt');
    final remoteUpdated = _extractTimestamp(remote, 'updatedAt');

    if (remoteUpdated != null &&
        (localUpdated == null || remoteUpdated.isAfter(localUpdated))) {
      return Right(Map<String, dynamic>.from(remote));
    } else {
      return Right(Map<String, dynamic>.from(local));
    }
  }

  /// Merge note data
  Either<SyncFailure, Map<String, dynamic>> _mergeNote(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // For notes, prefer the version with more content
    final localContent = (local['content'] as String?) ?? '';
    final remoteContent = (remote['content'] as String?) ?? '';

    if (remoteContent.length > localContent.length) {
      return Right(Map<String, dynamic>.from(remote));
    } else {
      return Right(Map<String, dynamic>.from(local));
    }
  }

  /// Merge collection data
  Either<SyncFailure, Map<String, dynamic>> _mergeCollection(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = Map<String, dynamic>.from(local);

    // Merge collection metadata, preferring local for user collections
    if (remote['description'] != null &&
        (local['description'] == null ||
            (remote['description'] as String).isNotEmpty)) {
      merged['description'] = remote['description'];
    }

    // Use latest timestamp
    final localUpdated = _extractTimestamp(local, 'updatedAt');
    final remoteUpdated = _extractTimestamp(remote, 'updatedAt');

    if (remoteUpdated != null &&
        (localUpdated == null || remoteUpdated.isAfter(localUpdated))) {
      merged['updatedAt'] = remoteUpdated.toIso8601String();
    }

    return Right(merged);
  }
}
