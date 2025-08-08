/// File management specific exceptions
///
/// Provides comprehensive error handling for file operations including
/// downloads, storage management, and file integrity verification.
class FileException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const FileException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'FileException: $message';
}

/// Exception thrown when file download operations fail
class DownloadException extends FileException {
  final String? url;
  final int? statusCode;

  const DownloadException({
    required super.message,
    this.url,
    this.statusCode,
    super.code,
    super.originalError,
  });

  @override
  String toString() =>
      'DownloadException: $message${url != null ? ' (URL: $url)' : ''}';
}

/// Exception thrown when storage operations fail
class StorageException extends FileException {
  final String? path;
  final StorageErrorType errorType;

  const StorageException({
    required super.message,
    required this.errorType,
    this.path,
    super.code,
    super.originalError,
  });

  @override
  String toString() =>
      'StorageException: $message${path != null ? ' (Path: $path)' : ''}';
}

/// Exception thrown when file permission operations fail
class PermissionException extends FileException {
  final String? requiredPermission;

  const PermissionException({
    required super.message,
    this.requiredPermission,
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'PermissionException: $message';
}

/// Exception thrown when file integrity verification fails
class FileIntegrityException extends FileException {
  final String? expectedHash;
  final String? actualHash;
  final String? filePath;

  const FileIntegrityException({
    required super.message,
    this.expectedHash,
    this.actualHash,
    this.filePath,
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'FileIntegrityException: $message';
}

/// Types of storage errors for better error handling
enum StorageErrorType {
  insufficientSpace,
  pathNotFound,
  accessDenied,
  fileNotFound,
  fileAlreadyExists,
  corruptedFile,
  invalidFormat,
  sizeLimitExceeded,
  unknown,
}

/// Exception thrown when file operations exceed size limits
class FileSizeException extends FileException {
  final int? actualSize;
  final int? maxAllowedSize;

  const FileSizeException({
    required super.message,
    this.actualSize,
    this.maxAllowedSize,
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'FileSizeException: $message';
}

/// Exception thrown when file format is not supported
class UnsupportedFormatException extends FileException {
  final String? fileExtension;
  final List<String>? supportedFormats;

  const UnsupportedFormatException({
    required super.message,
    this.fileExtension,
    this.supportedFormats,
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'UnsupportedFormatException: $message';
}
