import 'package:equatable/equatable.dart';

/// Synchronizable entity interface
/// 
/// Defines common synchronization properties that all syncable entities
/// must implement for cloud synchronization functionality.
abstract class Syncable {
  /// Unique identifier for the entity
  String get id;
  
  /// Last modified timestamp for conflict resolution
  DateTime get updatedAt;
  
  /// Whether this entity is synchronized with the cloud
  bool get isSynced;
  
  /// Whether this entity has pending changes to sync
  bool get hasChanges;
  
  /// User ID this entity belongs to (null for shared/public data)
  String? get userId;
  
  /// Convert entity to syncable JSON format
  Map<String, dynamic> toSyncJson();
  
  /// Create entity from synced JSON data
  // Note: This should be implemented as a static factory method in each entity
}

/// Sync operation types
enum SyncOperation {
  create('create'),
  update('update'),
  delete('delete');

  const SyncOperation(this.value);
  final String value;

  static SyncOperation fromString(String value) {
    switch (value) {
      case 'create':
        return SyncOperation.create;
      case 'update':
        return SyncOperation.update;
      case 'delete':
        return SyncOperation.delete;
      default:
        throw ArgumentError('Unknown sync operation: $value');
    }
  }
}

/// Sync type for different synchronization modes
enum SyncType {
  full('full'),
  incremental('incremental'),
  manual('manual');

  const SyncType(this.value);
  final String value;

  static SyncType fromString(String value) {
    switch (value) {
      case 'full':
        return SyncType.full;
      case 'incremental':
        return SyncType.incremental;
      case 'manual':
        return SyncType.manual;
      default:
        throw ArgumentError('Unknown sync type: $value');
    }
  }
}

/// Sync status for individual entities
enum SyncStatus {
  pending('pending'),
  syncing('syncing'),
  synced('synced'),
  failed('failed'),
  conflict('conflict'),
  idle('idle'),
  inProgress('inProgress'),
  completed('completed'),
  cancelled('cancelled');

  const SyncStatus(this.value);
  final String value;

  static SyncStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return SyncStatus.pending;
      case 'syncing':
        return SyncStatus.syncing;
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      case 'conflict':
        return SyncStatus.conflict;
      case 'idle':
        return SyncStatus.idle;
      case 'inProgress':
        return SyncStatus.inProgress;
      case 'completed':
        return SyncStatus.completed;
      case 'cancelled':
        return SyncStatus.cancelled;
      default:
        throw ArgumentError('Unknown sync status: $value');
    }
  }
}

/// Sync queue item representing a pending synchronization operation
class SyncQueueItem extends Equatable {
  final String id;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final SyncStatus status;
  final int priority;
  final int retryCount;
  final int maxRetries;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final String? errorMessage;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.status,
    this.priority = 0,
    this.retryCount = 0,
    this.maxRetries = 3,
    required this.createdAt,
    this.lastAttemptAt,
    this.errorMessage,
  });

  /// Create a copy with modified properties
  SyncQueueItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperation? operation,
    Map<String, dynamic>? data,
    SyncStatus? status,
    int? priority,
    int? retryCount,
    int? maxRetries,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    String? errorMessage,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if item should be retried
  bool get shouldRetry => retryCount < 3 && status == SyncStatus.failed;

  /// Get next retry delay
  Duration get retryDelay {
    // Exponential backoff: 1s, 4s, 16s
    final delaySeconds = [1, 4, 16];
    if (retryCount < delaySeconds.length) {
      return Duration(seconds: delaySeconds[retryCount]);
    }
    return const Duration(seconds: 60); // Max retry delay
  }

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        operation,
        data,
        status,
        priority,
        retryCount,
        maxRetries,
        createdAt,
        lastAttemptAt,
        errorMessage,
      ];
}

/// Sync conflict representation
class SyncConflict extends Equatable {
  final String id;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;
  final DateTime conflictDetectedAt;
  final ConflictResolution? resolution;

  const SyncConflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localData,
    required this.remoteData,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
    required this.conflictDetectedAt,
    this.resolution,
  });

  /// Check if conflict is resolved
  bool get isResolved => resolution != null;

  /// Check if local version is newer
  bool get localIsNewer => localUpdatedAt.isAfter(remoteUpdatedAt);

  /// Check if remote version is newer
  bool get remoteIsNewer => remoteUpdatedAt.isAfter(localUpdatedAt);

  /// Create SyncConflict from JSON
  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      localData: json['local_data'] as Map<String, dynamic>,
      remoteData: json['remote_data'] as Map<String, dynamic>,
      localUpdatedAt: DateTime.parse(json['local_updated_at'] as String),
      remoteUpdatedAt: DateTime.parse(json['remote_updated_at'] as String),
      conflictDetectedAt: DateTime.parse(json['conflict_detected_at'] as String),
      resolution: json['resolution'] != null 
          ? ConflictResolution.fromString(json['resolution'] as String)
          : null,
    );
  }

  /// Convert SyncConflict to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'local_data': localData,
      'remote_data': remoteData,
      'local_updated_at': localUpdatedAt.toIso8601String(),
      'remote_updated_at': remoteUpdatedAt.toIso8601String(),
      'conflict_detected_at': conflictDetectedAt.toIso8601String(),
      'resolution': resolution?.value,
    };
  }

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        localData,
        remoteData,
        localUpdatedAt,
        remoteUpdatedAt,
        conflictDetectedAt,
        resolution,
      ];
}

/// Conflict resolution strategies
enum ConflictResolution {
  useLocal('use_local'),
  useRemote('use_remote'),
  merge('merge'),
  manual('manual');

  const ConflictResolution(this.value);
  final String value;

  static ConflictResolution fromString(String value) {
    switch (value) {
      case 'use_local':
        return ConflictResolution.useLocal;
      case 'use_remote':
        return ConflictResolution.useRemote;
      case 'merge':
        return ConflictResolution.merge;
      case 'manual':
        return ConflictResolution.manual;
      default:
        throw ArgumentError('Unknown conflict resolution: $value');
    }
  }
}

/// Sync session representing a complete sync operation
class SyncSession extends Equatable {
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final SyncSessionStatus status;
  final int totalItems;
  final int processedItems;
  final int successfulItems;
  final int failedItems;
  final int conflictItems;
  final List<String> errors;
  final Map<String, dynamic> metadata;

  const SyncSession({
    required this.id,
    required this.startedAt,
    this.completedAt,
    required this.status,
    required this.totalItems,
    required this.processedItems,
    required this.successfulItems,
    required this.failedItems,
    required this.conflictItems,
    required this.errors,
    required this.metadata,
  });

  /// Simple constructor for sync service
  SyncSession.simple({
    required this.id,
    required this.startedAt,
    this.completedAt,
    required this.status,
  }) : totalItems = 0,
       processedItems = 0,
       successfulItems = 0,
       failedItems = 0,
       conflictItems = 0,
       errors = const [],
       metadata = const {};

  /// Calculate sync progress (0.0 to 1.0)
  double get progress {
    if (totalItems == 0) return 1.0;
    return processedItems / totalItems;
  }

  /// Get sync duration
  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  /// Check if sync completed successfully
  bool get isSuccessful => status == SyncSessionStatus.completed && failedItems == 0 && conflictItems == 0;

  /// Create a copy of SyncSession with updated fields
  SyncSession copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? completedAt,
    SyncSessionStatus? status,
    int? totalItems,
    int? processedItems,
    int? successfulItems,
    int? failedItems,
    int? conflictItems,
    List<String>? errors,
    Map<String, dynamic>? metadata,
    String? error,
    int? itemsProcessed,
    int? conflictsDetected,
  }) {
    return SyncSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? itemsProcessed ?? this.processedItems,
      successfulItems: successfulItems ?? this.successfulItems,
      failedItems: failedItems ?? this.failedItems,
      conflictItems: conflictItems ?? conflictsDetected ?? this.conflictItems,
      errors: errors ?? (error != null ? [...this.errors, error] : this.errors),
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        startedAt,
        completedAt,
        status,
        totalItems,
        processedItems,
        successfulItems,
        failedItems,
        conflictItems,
        errors,
        metadata,
      ];
}

/// Sync session status
enum SyncSessionStatus {
  starting('starting'),
  running('running'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const SyncSessionStatus(this.value);
  final String value;

  static SyncSessionStatus fromString(String value) {
    switch (value) {
      case 'starting':
        return SyncSessionStatus.starting;
      case 'running':
        return SyncSessionStatus.running;
      case 'completed':
        return SyncSessionStatus.completed;
      case 'failed':
        return SyncSessionStatus.failed;
      case 'cancelled':
        return SyncSessionStatus.cancelled;
      default:
        throw ArgumentError('Unknown sync session status: $value');
    }
  }
}

/// Device information for sync tracking
class DeviceInfo extends Equatable {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String appVersion;
  final DateTime lastSyncAt;
  final bool isActive;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
    required this.lastSyncAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        deviceId,
        deviceName,
        platform,
        appVersion,
        lastSyncAt,
        isActive,
      ];
}
