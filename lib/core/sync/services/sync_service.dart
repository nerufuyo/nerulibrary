import 'package:dartz/dartz.dart';

import '../entities/sync_entities.dart';
import '../failures/sync_failures.dart';

/// Cloud synchronization service interface
/// 
/// Defines the contract for synchronizing data between local storage
/// and cloud backend (Supabase) with conflict resolution support.
abstract class SyncService {
  /// Start a full synchronization of all data
  /// 
  /// Returns [SyncSession] on success or [SyncFailure] on error.
  Future<Either<SyncFailure, SyncSession>> startFullSync();
  
  /// Start incremental synchronization (only changed data)
  /// 
  /// [lastSyncTime] - timestamp of last successful sync
  /// Returns [SyncSession] on success or [SyncFailure] on error.
  Future<Either<SyncFailure, SyncSession>> startIncrementalSync(DateTime lastSyncTime);
  
  /// Add item to sync queue
  /// 
  /// [item] - sync queue item to add
  /// Returns [true] on success or [SyncFailure] on error.
  Future<Either<SyncFailure, bool>> addToSyncQueue(SyncQueueItem item);
  
  /// Process sync queue
  /// 
  /// Processes all pending items in the sync queue.
  /// Returns [SyncSession] on success or [SyncFailure] on error.
  Future<Either<SyncFailure, SyncSession>> processSyncQueue();
  
  /// Get sync queue status
  /// 
  /// Returns list of pending sync items.
  Future<Either<SyncFailure, List<SyncQueueItem>>> getSyncQueue();
  
  /// Clear sync queue
  /// 
  /// Removes all items from sync queue.
  Future<Either<SyncFailure, bool>> clearSyncQueue();
  
  /// Get sync conflicts
  /// 
  /// Returns list of unresolved sync conflicts.
  Future<Either<SyncFailure, List<SyncConflict>>> getSyncConflicts();
  
  /// Resolve sync conflict
  /// 
  /// [conflictId] - ID of conflict to resolve
  /// [resolution] - resolution strategy to apply
  /// Returns [true] on success or [SyncFailure] on error.
  Future<Either<SyncFailure, bool>> resolveConflict(
    String conflictId,
    ConflictResolution resolution,
  );
  
  /// Get sync status
  /// 
  /// Returns current synchronization status and statistics.
  Future<Either<SyncFailure, SyncStatus>> getSyncStatus();
  
  /// Cancel ongoing sync operation
  /// 
  /// Returns [true] if cancelled successfully.
  Future<Either<SyncFailure, bool>> cancelSync();
  
  /// Check if sync is available
  /// 
  /// Checks network connectivity and server availability.
  Future<Either<SyncFailure, bool>> isSyncAvailable();
  
  /// Get last sync time
  /// 
  /// Returns timestamp of last successful sync.
  Future<Either<SyncFailure, DateTime?>> getLastSyncTime();
  
  /// Stream of sync status updates
  /// 
  /// Emits [SyncStatus] updates during sync operations.
  Stream<SyncStatus> get syncStatusStream;
  
  /// Stream of sync progress updates
  /// 
  /// Emits progress values (0.0 to 1.0) during sync operations.
  Stream<double> get syncProgressStream;
  
  /// Stream of sync conflicts
  /// 
  /// Emits new conflicts as they are detected.
  Stream<SyncConflict> get syncConflictStream;
}

/// Syncable entity service interface
/// 
/// Defines methods for individual entity type synchronization.
abstract class EntitySyncService<T extends Syncable> {
  /// Sync entity to cloud
  /// 
  /// [entity] - entity to sync
  /// Returns updated entity on success or [SyncFailure] on error.
  Future<Either<SyncFailure, T>> syncToCloud(T entity);
  
  /// Sync entity from cloud
  /// 
  /// [entityId] - ID of entity to sync from cloud
  /// Returns entity data on success or [SyncFailure] on error.
  Future<Either<SyncFailure, T>> syncFromCloud(String entityId);
  
  /// Get cloud changes since last sync
  /// 
  /// [lastSyncTime] - timestamp of last sync
  /// Returns list of changed entities.
  Future<Either<SyncFailure, List<T>>> getCloudChanges(DateTime lastSyncTime);
  
  /// Push local changes to cloud
  /// 
  /// [entities] - list of changed entities
  /// Returns number of successfully synced entities.
  Future<Either<SyncFailure, int>> pushChangesToCloud(List<T> entities);
  
  /// Pull remote changes from cloud
  /// 
  /// [lastSyncTime] - timestamp of last sync
  /// Returns list of remote changes.
  Future<Either<SyncFailure, List<T>>> pullChangesFromCloud(DateTime lastSyncTime);
  
  /// Detect conflicts between local and remote data
  /// 
  /// [localEntity] - local version of entity
  /// [remoteEntity] - remote version of entity
  /// Returns [SyncConflict] if conflict exists, null otherwise.
  SyncConflict? detectConflict(T localEntity, T remoteEntity);
  
  /// Resolve conflict automatically if possible
  /// 
  /// [conflict] - conflict to resolve
  /// [strategy] - resolution strategy
  /// Returns resolved entity or null if manual resolution required.
  T? resolveConflictAutomatically(SyncConflict conflict, ConflictResolution strategy);
  
  /// Validate entity before sync
  /// 
  /// [entity] - entity to validate
  /// Returns [true] if valid, [SyncFailure] if invalid.
  Either<SyncFailure, bool> validateEntity(T entity);
  
  /// Transform entity for cloud storage
  /// 
  /// [entity] - entity to transform
  /// Returns transformed data for cloud storage.
  Map<String, dynamic> transformForCloud(T entity);
  
  /// Transform cloud data to entity
  /// 
  /// [data] - cloud data to transform
  /// Returns entity created from cloud data.
  T transformFromCloud(Map<String, dynamic> data);
}
