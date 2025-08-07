import 'package:equatable/equatable.dart';

/// Abstract base class for all failures in the application
/// 
/// Represents different types of failures that can occur during
/// business logic operations. All failures extend this class.
abstract class Failure extends Equatable {
  /// Human-readable error message
  final String message;
  
  /// Optional error code for programmatic handling
  final String? code;
  
  /// Original error that caused this failure
  final dynamic originalError;
  
  /// Stack trace of the original error
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, code, originalError, stackTrace];
  
  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'NetworkFailure(message: $message, code: $code)';
}

/// Server-related failures  
class ServerFailure extends Failure {
  /// HTTP status code
  final int? statusCode;
  
  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  List<Object?> get props => [...super.props, statusCode];
  
  @override
  String toString() => 'ServerFailure(message: $message, code: $code, statusCode: $statusCode)';
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'CacheFailure(message: $message, code: $code)';
}

/// Authentication-related failures
class AuthenticationFailure extends Failure {
  /// Type of authentication failure
  final AuthFailureType type;
  
  const AuthenticationFailure({
    required super.message,
    required this.type,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  List<Object?> get props => [...super.props, type];
  
  @override
  String toString() => 'AuthenticationFailure(message: $message, type: $type, code: $code)';
}

/// Types of authentication failures
enum AuthFailureType {
  invalidCredentials,
  userNotFound,
  emailNotVerified,
  accountLocked,
  sessionExpired,
  weakPassword,
  emailAlreadyExists,
  invalidEmail,
  tooManyAttempts,
  providerError,
  unknown,
}

/// Validation-related failures
class ValidationFailure extends Failure {
  /// Field that failed validation
  final String? field;
  
  /// Validation error details
  final Map<String, String>? errors;
  
  const ValidationFailure({
    required super.message,
    this.field,
    this.errors,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  List<Object?> get props => [...super.props, field, errors];
  
  @override
  String toString() => 'ValidationFailure(message: $message, field: $field, errors: $errors)';
}

/// Database-related failures
class DatabaseFailure extends Failure {
  /// Database operation that failed
  final String? operation;
  
  const DatabaseFailure({
    required super.message,
    this.operation,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  List<Object?> get props => [...super.props, operation];
  
  @override
  String toString() => 'DatabaseFailure(message: $message, operation: $operation, code: $code)';
}

/// Not found failures for when entities are not found
class NotFoundFailure extends Failure {
  /// Type of entity that was not found
  final String? entityType;
  
  /// ID of the entity that was not found
  final String? entityId;
  
  const NotFoundFailure({
    required super.message,
    this.entityType,
    this.entityId,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  List<Object?> get props => [...super.props, entityType, entityId];
  
  @override
  String toString() => 'NotFoundFailure(message: $message, entityType: $entityType, entityId: $entityId)';
}

/// File system-related failures
class FileSystemFailure extends Failure {
  /// File path that caused the failure
  final String? path;
  
  /// File operation that failed
  final String? operation;
  
  const FileSystemFailure({
    required super.message,
    this.path,
    this.operation,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  List<Object?> get props => [...super.props, path, operation];
  
  @override
  String toString() => 'FileSystemFailure(message: $message, path: $path, operation: $operation)';
}

/// Permission-related failures
class PermissionFailure extends Failure {
  /// Permission that was denied
  final String? permission;
  
  const PermissionFailure({
    required super.message,
    this.permission,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  List<Object?> get props => [...super.props, permission];
  
  @override
  String toString() => 'PermissionFailure(message: $message, permission: $permission)';
}

/// Book-related failures
class BookFailure extends Failure {
  /// Book ID that caused the failure
  final String? bookId;
  
  /// Book format (epub, pdf, etc.)
  final String? format;
  
  const BookFailure({
    required super.message,
    this.bookId,
    this.format,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  List<Object?> get props => [...super.props, bookId, format];
  
  @override
  String toString() => 'BookFailure(message: $message, bookId: $bookId, format: $format)';
}

/// API-related failures
class ApiFailure extends Failure {
  /// API endpoint that failed
  final String? endpoint;
  
  /// HTTP status code
  final int? statusCode;
  
  /// API response data
  final Map<String, dynamic>? responseData;
  
  const ApiFailure({
    required super.message,
    this.endpoint,
    this.statusCode,
    this.responseData,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  List<Object?> get props => [...super.props, endpoint, statusCode, responseData];
  
  @override
  String toString() => 'ApiFailure(message: $message, endpoint: $endpoint, statusCode: $statusCode)';
}

/// Sync-related failures
class SyncFailure extends Failure {
  /// Type of sync that failed
  final String? syncType;
  
  /// Items that failed to sync
  final List<String>? failedItems;
  
  const SyncFailure({
    required super.message,
    this.syncType,
    this.failedItems,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  List<Object?> get props => [...super.props, syncType, failedItems];
  
  @override
  String toString() => 'SyncFailure(message: $message, syncType: $syncType, failedItems: $failedItems)';
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'UnknownFailure(message: $message, code: $code)';
}
