import 'failures.dart';

/// Base class for file management failures
abstract class FileFailure extends Failure {
  const FileFailure({required super.message});
}

/// Failure when file download operations fail
class DownloadFailure extends FileFailure {
  final String? url;
  final int? statusCode;
  final String? errorCode;

  const DownloadFailure({
    required super.message,
    this.url,
    this.statusCode,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, url, statusCode, errorCode];

  @override
  String toString() => 'DownloadFailure: $message';
}

/// Failure when storage operations fail
class StorageFailure extends FileFailure {
  final String? path;
  final StorageErrorType? errorType;

  const StorageFailure({
    required super.message,
    this.path,
    this.errorType,
  });

  @override
  List<Object?> get props => [message, path, errorType];

  @override
  String toString() => 'StorageFailure: $message';
}

/// Failure when file permission operations fail
class PermissionFailure extends FileFailure {
  final String? requiredPermission;
  final PermissionStatus? currentStatus;

  const PermissionFailure({
    required super.message,
    this.requiredPermission,
    this.currentStatus,
  });

  @override
  List<Object?> get props => [message, requiredPermission, currentStatus];

  @override
  String toString() => 'PermissionFailure: $message';
}

/// Failure when file integrity verification fails
class FileIntegrityFailure extends FileFailure {
  final String? expectedHash;
  final String? actualHash;
  final String? filePath;

  const FileIntegrityFailure({
    required super.message,
    this.expectedHash,
    this.actualHash,
    this.filePath,
  });

  @override
  List<Object?> get props => [message, expectedHash, actualHash, filePath];

  @override
  String toString() => 'FileIntegrityFailure: $message';
}

/// Failure when file size exceeds limits
class FileSizeFailure extends FileFailure {
  final int? actualSize;
  final int? maxAllowedSize;

  const FileSizeFailure({
    required super.message,
    this.actualSize,
    this.maxAllowedSize,
  });

  @override
  List<Object?> get props => [message, actualSize, maxAllowedSize];

  @override
  String toString() => 'FileSizeFailure: $message';
}

/// Failure when file format is not supported
class UnsupportedFormatFailure extends FileFailure {
  final String? fileExtension;
  final List<String>? supportedFormats;

  const UnsupportedFormatFailure({
    required super.message,
    this.fileExtension,
    this.supportedFormats,
  });

  @override
  List<Object?> get props => [message, fileExtension, supportedFormats];

  @override
  String toString() => 'UnsupportedFormatFailure: $message';
}

/// Failure when network operations fail during file operations
class NetworkFileFailure extends FileFailure {
  final String? url;
  final NetworkErrorType errorType;

  const NetworkFileFailure({
    required super.message,
    required this.errorType,
    this.url,
  });

  @override
  List<Object?> get props => [message, url, errorType];

  @override
  String toString() => 'NetworkFileFailure: $message';
}

/// Failure when file cleanup operations fail
class CleanupFailure extends FileFailure {
  final String? targetPath;
  final List<String>? failedPaths;

  const CleanupFailure({
    required super.message,
    this.targetPath,
    this.failedPaths,
  });

  @override
  List<Object?> get props => [message, targetPath, failedPaths];

  @override
  String toString() => 'CleanupFailure: $message';
}

/// Types of storage errors for failure classification
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

/// Types of network errors for file operations
enum NetworkErrorType {
  connectionTimeout,
  noInternet,
  serverError,
  unauthorizedAccess,
  notFound,
  rateLimited,
  unknown,
}

/// Permission status enumeration
enum PermissionStatus {
  granted,
  denied,
  restricted,
  permanentlyDenied,
  unknown,
}
