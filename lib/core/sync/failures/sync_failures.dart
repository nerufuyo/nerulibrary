import '../../errors/failures.dart';

/// Base class for synchronization-related failures
abstract class SyncFailure extends Failure {
  const SyncFailure({required super.message, super.code});
}

/// Failed to establish connection to sync server
class SyncConnectionFailure extends SyncFailure {
  const SyncConnectionFailure(
      {required super.message, super.code = 'SYNC_CONNECTION_FAILED'});
}

/// Authentication failed during sync
class SyncAuthFailure extends SyncFailure {
  const SyncAuthFailure(
      {required super.message, super.code = 'SYNC_AUTH_FAILED'});
}

/// Sync data conflict detected
class SyncConflictFailure extends SyncFailure {
  final String entityType;
  final String entityId;
  final Map<String, dynamic> conflictData;

  const SyncConflictFailure({
    required super.message,
    required this.entityType,
    required this.entityId,
    required this.conflictData,
    super.code = 'SYNC_CONFLICT',
  });
}

/// Sync operation timeout
class SyncTimeoutFailure extends SyncFailure {
  const SyncTimeoutFailure(
      {required super.message, super.code = 'SYNC_TIMEOUT'});
}

/// Invalid sync data format
class SyncDataFailure extends SyncFailure {
  const SyncDataFailure(
      {required super.message, super.code = 'SYNC_DATA_INVALID'});
}

/// Sync quota exceeded
class SyncQuotaFailure extends SyncFailure {
  const SyncQuotaFailure(
      {required super.message, super.code = 'SYNC_QUOTA_EXCEEDED'});
}

/// Sync version mismatch
class SyncVersionFailure extends SyncFailure {
  const SyncVersionFailure(
      {required super.message, super.code = 'SYNC_VERSION_MISMATCH'});
}

/// Sync cancelled by user
class SyncCancelledFailure extends SyncFailure {
  const SyncCancelledFailure(
      {required super.message, super.code = 'SYNC_CANCELLED'});
}

/// Sync rate limit exceeded
class SyncRateLimitFailure extends SyncFailure {
  final Duration retryAfter;

  const SyncRateLimitFailure({
    required super.message,
    required this.retryAfter,
    super.code = 'SYNC_RATE_LIMIT',
  });
}

/// Sync permission denied
class SyncPermissionFailure extends SyncFailure {
  const SyncPermissionFailure(
      {required super.message, super.code = 'SYNC_PERMISSION_DENIED'});
}

/// Sync storage failure
class SyncStorageFailure extends SyncFailure {
  const SyncStorageFailure(
      {required super.message, super.code = 'SYNC_STORAGE_FAILED'});
}

/// Sync validation failure
class SyncValidationFailure extends SyncFailure {
  final List<String> validationErrors;

  const SyncValidationFailure({
    required super.message,
    required this.validationErrors,
    super.code = 'SYNC_VALIDATION_FAILED',
  });
}
