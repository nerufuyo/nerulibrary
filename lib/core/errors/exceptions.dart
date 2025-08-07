/// Custom exceptions for the LiteraLib application
/// 
/// Defines specific exception types for differen/// Book-related exceptions
class BookException extends AppException {
  final String? bookId;
  final String? format;
  
  const BookException(
    super.message, {
    this.bookId,
    this.format,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'BookException: $message (bookId: $bookId, format: $format)';
}

/// Security-related exceptions
class SecurityException extends AppException {
  const SecurityException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'SecurityException: $message';
}
/// to enable proper error handling and user feedback.

/// Base exception class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  
  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() => 'AppException: $message';
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'DatabaseException: $message';
}

/// Not found exceptions for when entities are not found
class NotFoundException extends AppException {
  final String? entityType;
  final String? entityId;
  
  const NotFoundException(
    super.message, {
    this.entityType,
    this.entityId,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'NotFoundException: $message (Type: $entityType, ID: $entityId)';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'NetworkException: $message';
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'CacheException: $message';
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'AuthException: $message';
}

/// File system-related exceptions
class FileSystemException extends AppException {
  const FileSystemException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'FileSystemException: $message';
}

/// API-related exceptions
class ApiException extends AppException {
  final int? statusCode;
  final Map<String, dynamic>? responseData;
  
  const ApiException(
    super.message, {
    this.statusCode,
    this.responseData,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;
  
  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'ValidationException: $message';
}

/// Permission-related exceptions
class PermissionException extends AppException {
  final String? permission;
  
  const PermissionException(
    super.message, {
    this.permission,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'PermissionException: $message (Permission: $permission)';
}

/// Storage-related exceptions
class StorageException extends AppException {
  final String? path;
  
  const StorageException(
    super.message, {
    this.path,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'StorageException: $message (Path: $path)';
}

/// Sync-related exceptions
class SyncException extends AppException {
  final String? syncType;
  
  const SyncException(
    super.message, {
    this.syncType,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() => 'SyncException: $message (Type: $syncType)';
}
