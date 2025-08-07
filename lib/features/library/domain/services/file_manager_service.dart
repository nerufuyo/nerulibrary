import 'package:dartz/dartz.dart';

import '../../../../core/errors/file_failures.dart';
import '../entities/download_item.dart';

/// File manager service interface for handling all file operations
/// 
/// Provides comprehensive file management capabilities including downloads,
/// storage management, cleanup, and integrity verification.
abstract class FileManagerService {
  /// Downloads a file from the given URL with queue management
  /// 
  /// [url] - The URL to download from
  /// [fileName] - The local file name
  /// [bookId] - Associated book identifier
  /// [priority] - Download priority level
  /// [expectedSize] - Expected file size in bytes
  /// [expectedHash] - Expected file hash for integrity verification
  /// 
  /// Returns [Either] containing [DownloadFailure] on error or [DownloadItem] on success
  Future<Either<FileFailure, DownloadItem>> downloadFile({
    required String url,
    required String fileName,
    required String bookId,
    DownloadPriority priority = DownloadPriority.normal,
    int? expectedSize,
    String? expectedHash,
    Map<String, dynamic>? metadata,
  });

  /// Pauses an active download
  Future<Either<FileFailure, DownloadItem>> pauseDownload(String downloadId);

  /// Resumes a paused download
  Future<Either<FileFailure, DownloadItem>> resumeDownload(String downloadId);

  /// Cancels a download and optionally removes the partial file
  Future<Either<FileFailure, bool>> cancelDownload(
    String downloadId, {
    bool removePartialFile = true,
  });

  /// Retries a failed download
  Future<Either<FileFailure, DownloadItem>> retryDownload(String downloadId);

  /// Gets the current status of a download
  Future<Either<FileFailure, DownloadItem>> getDownloadStatus(String downloadId);

  /// Gets all downloads with optional status filtering
  Future<Either<FileFailure, List<DownloadItem>>> getAllDownloads({
    DownloadStatus? status,
    String? bookId,
  });

  /// Gets download statistics
  Future<Either<FileFailure, DownloadStatistics>> getDownloadStatistics();

  /// Clears completed downloads from the queue
  Future<Either<FileFailure, int>> clearCompletedDownloads();

  /// Gets the local file path for a book
  Future<Either<FileFailure, String>> getBookFilePath(
    String bookId,
    String fileName,
  );

  /// Checks if a file exists locally
  Future<Either<FileFailure, bool>> fileExists(String filePath);

  /// Gets file information
  Future<Either<FileFailure, FileInfo>> getFileInfo(String filePath);

  /// Deletes a local file
  Future<Either<FileFailure, bool>> deleteFile(String filePath);

  /// Moves a file to a new location
  Future<Either<FileFailure, String>> moveFile(
    String sourcePath,
    String destinationPath,
  );

  /// Copies a file to a new location
  Future<Either<FileFailure, String>> copyFile(
    String sourcePath,
    String destinationPath,
  );

  /// Verifies file integrity using hash comparison
  Future<Either<FileFailure, bool>> verifyFileIntegrity(
    String filePath,
    String expectedHash, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
  });

  /// Gets available storage space in bytes
  Future<Either<FileFailure, int>> getAvailableStorageSpace();

  /// Gets used storage space by the app in bytes
  Future<Either<FileFailure, int>> getUsedStorageSpace();

  /// Cleans up temporary files
  Future<Either<FileFailure, CleanupResult>> cleanupTemporaryFiles({
    Duration? olderThan,
  });

  /// Cleans up cached files
  Future<Either<FileFailure, CleanupResult>> cleanupCachedFiles({
    Duration? olderThan,
    int? maxCacheSize,
  });

  /// Cleans up orphaned files (files without database references)
  Future<Either<FileFailure, CleanupResult>> cleanupOrphanedFiles();

  /// Performs a full storage cleanup
  Future<Either<FileFailure, CleanupResult>> performFullCleanup({
    bool includeTemporary = true,
    bool includeCache = true,
    bool includeOrphaned = true,
    Duration? olderThan,
  });

  /// Creates necessary directory structure
  Future<Either<FileFailure, bool>> createDirectoryStructure();

  /// Validates file format support
  Either<FileFailure, bool> validateFileFormat(String fileName);

  /// Checks if file size is within limits
  Either<FileFailure, bool> validateFileSize(int fileSizeBytes);

  /// Stream of download progress updates
  Stream<DownloadItem> get downloadProgressStream;

  /// Stream of download queue changes
  Stream<List<DownloadItem>> get downloadQueueStream;
}

/// File information entity
class FileInfo {
  final String path;
  final String name;
  final String extension;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isReadable;
  final bool isWritable;
  final String? mimeType;

  const FileInfo({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.createdAt,
    required this.modifiedAt,
    required this.isReadable,
    required this.isWritable,
    this.mimeType,
  });

  /// Human-readable file size
  String get formattedSize {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = sizeBytes.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }

  @override
  String toString() {
    return 'FileInfo{name: $name, size: $formattedSize, modified: $modifiedAt}';
  }
}

/// Cleanup operation result
class CleanupResult {
  final int filesDeleted;
  final int bytesFreed;
  final Duration operationDuration;
  final List<String> errors;

  const CleanupResult({
    required this.filesDeleted,
    required this.bytesFreed,
    required this.operationDuration,
    this.errors = const [],
  });

  /// Human-readable bytes freed
  String get formattedBytesFreed {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytesFreed.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }

  @override
  String toString() {
    return 'CleanupResult{files: $filesDeleted, freed: $formattedBytesFreed, duration: ${operationDuration.inSeconds}s}';
  }
}

/// Hash algorithms for file integrity verification
enum HashAlgorithm {
  md5,
  sha1,
  sha256,
  sha512,
}
