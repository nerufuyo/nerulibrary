import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/errors/file_failures.dart';
import '../../../../core/services/file_permission_manager.dart';
import '../../../library/domain/entities/download_item.dart';
import '../../../library/domain/services/file_manager_service.dart';

/// Implementation of file manager service with comprehensive file operations
/// 
/// Provides download management, storage operations, cleanup mechanisms,
/// and file integrity verification with proper error handling.
class FileManagerServiceImpl implements FileManagerService {
  final Dio _dio;
  final FilePermissionManager _permissionManager;
  
  // Download queue and progress management
  final Map<String, DownloadItem> _downloadQueue = {};
  final Map<String, CancelToken> _cancelTokens = {};
  final StreamController<DownloadItem> _progressController = StreamController.broadcast();
  final StreamController<List<DownloadItem>> _queueController = StreamController.broadcast();
  
  // Directory paths
  String? _appDocumentsDir;
  String? _booksDir;
  String? _coversDir;
  String? _tempDir;
  String? _cacheDir;

  FileManagerServiceImpl({
    required Dio dio,
    required FilePermissionManager permissionManager,
  }) : _dio = dio, _permissionManager = permissionManager;

  /// Initialize the file manager and create directory structure
  Future<void> initialize() async {
    await _initializeDirectories();
    await createDirectoryStructure();
  }

  /// Initialize directory paths
  Future<void> _initializeDirectories() async {
    final appDir = await getApplicationDocumentsDirectory();
    _appDocumentsDir = appDir.path;
    _booksDir = path.join(_appDocumentsDir!, StorageConstants.dirBooks);
    _coversDir = path.join(_appDocumentsDir!, StorageConstants.dirCovers);
    _tempDir = path.join(_appDocumentsDir!, StorageConstants.dirTemp);
    _cacheDir = path.join(_appDocumentsDir!, StorageConstants.dirCache);
  }

  @override
  Future<Either<FileFailure, DownloadItem>> downloadFile({
    required String url,
    required String fileName,
    required String bookId,
    DownloadPriority priority = DownloadPriority.normal,
    int? expectedSize,
    String? expectedHash,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Ensure permissions
      final permissionResult = await _permissionManager.ensureFilePermissions();
      if (permissionResult.isLeft()) {
        return Left(PermissionFailure(
          message: 'File permissions not granted',
          requiredPermission: 'storage',
        ));
      }

      // Validate file format
      final formatValidation = validateFileFormat(fileName);
      if (formatValidation.isLeft()) {
        return formatValidation.fold(
          (failure) => Left(failure),
          (_) => Left(UnsupportedFormatFailure(message: 'Invalid format validation')),
        );
      }

      // Create download item
      final downloadId = _generateDownloadId();
      final downloadItem = DownloadItem(
        id: downloadId,
        bookId: bookId,
        url: url,
        fileName: fileName,
        priority: priority,
        createdAt: DateTime.now(),
        expectedSize: expectedSize,
        expectedHash: expectedHash,
        metadata: metadata,
      );

      // Add to queue
      _downloadQueue[downloadId] = downloadItem;
      _notifyQueueChanged();

      // Start download
      await _startDownload(downloadItem);

      return Right(downloadItem);
    } catch (e) {
      return Left(DownloadFailure(
        message: 'Failed to start download: $e',
        url: url,
      ));
    }
  }

  /// Start the actual download process
  Future<void> _startDownload(DownloadItem item) async {
    try {
      // Update status to downloading
      _updateDownloadItem(item.id, item.copyWith(
        status: DownloadStatus.downloading,
        startedAt: DateTime.now(),
      ));

      // Create cancel token
      final cancelToken = CancelToken();
      _cancelTokens[item.id] = cancelToken;

      // Get file path
      final filePathResult = await getBookFilePath(item.bookId, item.fileName);
      if (filePathResult.isLeft()) {
        _handleDownloadError(item.id, 'Failed to get file path');
        return;
      }

      final filePath = filePathResult.fold((l) => '', (r) => r);

      // Start download
      await _dio.download(
        item.url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          _handleDownloadProgress(item.id, received, total);
        },
      );

      // Verify file integrity if hash provided
      if (item.expectedHash != null) {
        final verificationResult = await verifyFileIntegrity(
          filePath,
          item.expectedHash!,
        );
        
        if (verificationResult.isLeft()) {
          _handleDownloadError(item.id, 'File integrity verification failed');
          return;
        }
      }

      // Mark as completed
      _updateDownloadItem(item.id, item.copyWith(
        status: DownloadStatus.completed,
        completedAt: DateTime.now(),
        localPath: filePath,
      ));

    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // Download was cancelled
        _updateDownloadItem(item.id, item.copyWith(
          status: DownloadStatus.cancelled,
        ));
      } else {
        _handleDownloadError(item.id, e.toString());
      }
    } finally {
      _cancelTokens.remove(item.id);
    }
  }

  /// Handle download progress updates
  void _handleDownloadProgress(String downloadId, int received, int total) {
    final item = _downloadQueue[downloadId];
    if (item != null) {
      final updatedItem = item.copyWith(
        downloadedBytes: received,
        expectedSize: total > 0 ? total : item.expectedSize,
      );
      _updateDownloadItem(downloadId, updatedItem);
    }
  }

  /// Handle download errors
  void _handleDownloadError(String downloadId, String error) {
    final item = _downloadQueue[downloadId];
    if (item != null) {
      _updateDownloadItem(downloadId, item.copyWith(
        status: DownloadStatus.failed,
        errorMessage: error,
      ));
    }
  }

  /// Update download item and notify listeners
  void _updateDownloadItem(String downloadId, DownloadItem item) {
    _downloadQueue[downloadId] = item;
    _progressController.add(item);
    _notifyQueueChanged();
  }

  /// Notify queue change listeners
  void _notifyQueueChanged() {
    _queueController.add(_downloadQueue.values.toList());
  }

  @override
  Future<Either<FileFailure, DownloadItem>> pauseDownload(String downloadId) async {
    try {
      final item = _downloadQueue[downloadId];
      if (item == null) {
        return Left(StorageFailure(
          message: 'Download not found',
          errorType: StorageErrorType.fileNotFound,
        ));
      }

      if (item.status != DownloadStatus.downloading) {
        return Left(StorageFailure(
          message: 'Download is not in progress',
        ));
      }

      // Cancel the download
      final cancelToken = _cancelTokens[downloadId];
      cancelToken?.cancel('Download paused by user');

      // Update status
      final pausedItem = item.copyWith(status: DownloadStatus.paused);
      _updateDownloadItem(downloadId, pausedItem);

      return Right(pausedItem);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to pause download: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, DownloadItem>> resumeDownload(String downloadId) async {
    try {
      final item = _downloadQueue[downloadId];
      if (item == null) {
        return Left(StorageFailure(
          message: 'Download not found',
          errorType: StorageErrorType.fileNotFound,
        ));
      }

      if (item.status != DownloadStatus.paused) {
        return Left(StorageFailure(
          message: 'Download is not paused',
        ));
      }

      // Restart the download
      await _startDownload(item);

      return Right(item);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to resume download: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, bool>> cancelDownload(
    String downloadId, {
    bool removePartialFile = true,
  }) async {
    try {
      final item = _downloadQueue[downloadId];
      if (item == null) {
        return Left(StorageFailure(
          message: 'Download not found',
          errorType: StorageErrorType.fileNotFound,
        ));
      }

      // Cancel active download
      final cancelToken = _cancelTokens[downloadId];
      cancelToken?.cancel('Download cancelled by user');

      // Remove partial file if requested
      if (removePartialFile && item.localPath != null) {
        final file = File(item.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Update status and remove from queue
      _updateDownloadItem(downloadId, item.copyWith(
        status: DownloadStatus.cancelled,
      ));
      _downloadQueue.remove(downloadId);
      _notifyQueueChanged();

      return const Right(true);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to cancel download: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, DownloadItem>> retryDownload(String downloadId) async {
    try {
      final item = _downloadQueue[downloadId];
      if (item == null) {
        return Left(StorageFailure(
          message: 'Download not found',
          errorType: StorageErrorType.fileNotFound,
        ));
      }

      if (!item.canRetry) {
        return Left(StorageFailure(
          message: 'Download cannot be retried',
        ));
      }

      // Reset download state
      final retryItem = item.copyWith(
        status: DownloadStatus.queued,
        retryCount: item.retryCount + 1,
        errorMessage: null,
        downloadedBytes: 0,
        startedAt: null,
        completedAt: null,
      );

      _updateDownloadItem(downloadId, retryItem);

      // Restart download
      await _startDownload(retryItem);

      return Right(retryItem);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to retry download: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, DownloadItem>> getDownloadStatus(String downloadId) async {
    try {
      final item = _downloadQueue[downloadId];
      if (item == null) {
        return Left(StorageFailure(
          message: 'Download not found',
          errorType: StorageErrorType.fileNotFound,
        ));
      }
      return Right(item);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to get download status: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, List<DownloadItem>>> getAllDownloads({
    DownloadStatus? status,
    String? bookId,
  }) async {
    try {
      var downloads = _downloadQueue.values.toList();
      
      if (status != null) {
        downloads = downloads.where((item) => item.status == status).toList();
      }
      
      if (bookId != null) {
        downloads = downloads.where((item) => item.bookId == bookId).toList();
      }
      
      return Right(downloads);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to get downloads: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, DownloadStatistics>> getDownloadStatistics() async {
    try {
      final downloads = _downloadQueue.values.toList();
      
      final stats = DownloadStatistics(
        totalDownloads: downloads.length,
        completedDownloads: downloads.where((d) => d.isCompleted).length,
        failedDownloads: downloads.where((d) => d.hasFailed).length,
        activeDownloads: downloads.where((d) => d.isInProgress).length,
        queuedDownloads: downloads.where((d) => d.isQueued).length,
        totalBytesDownloaded: downloads
            .where((d) => d.isCompleted)
            .fold<int>(0, (sum, d) => sum + d.downloadedBytes),
        averageDownloadSpeed: _calculateAverageSpeed(downloads),
        lastUpdated: DateTime.now(),
      );
      
      return Right(stats);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to get download statistics: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, int>> clearCompletedDownloads() async {
    try {
      final completedIds = _downloadQueue.values
          .where((item) => item.isCompleted)
          .map((item) => item.id)
          .toList();
      
      for (final id in completedIds) {
        _downloadQueue.remove(id);
      }
      
      _notifyQueueChanged();
      
      return Right(completedIds.length);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to clear completed downloads: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, String>> getBookFilePath(
    String bookId,
    String fileName,
  ) async {
    try {
      if (_booksDir == null) {
        await _initializeDirectories();
      }
      
      final bookDir = path.join(_booksDir!, bookId);
      await Directory(bookDir).create(recursive: true);
      
      final filePath = path.join(bookDir, fileName);
      return Right(filePath);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to get book file path: $e',
        errorType: StorageErrorType.pathNotFound,
      ));
    }
  }

  @override
  Future<Either<FileFailure, bool>> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      final exists = await file.exists();
      return Right(exists);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to check file existence: $e',
        path: filePath,
      ));
    }
  }

  @override
  Future<Either<FileFailure, FileInfo>> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Left(StorageFailure(
          message: 'File does not exist',
          errorType: StorageErrorType.fileNotFound,
          path: filePath,
        ));
      }

      final stat = await file.stat();
      final fileName = path.basename(filePath);
      final extension = path.extension(filePath);

      final fileInfo = FileInfo(
        path: filePath,
        name: fileName,
        extension: extension.isNotEmpty ? extension.substring(1) : '',
        sizeBytes: stat.size,
        createdAt: stat.changed,
        modifiedAt: stat.modified,
        isReadable: true, // TODO: Check actual permissions
        isWritable: true, // TODO: Check actual permissions
      );

      return Right(fileInfo);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to get file info: $e',
        path: filePath,
      ));
    }
  }

  @override
  Future<Either<FileFailure, bool>> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return const Right(true);
      }
      return const Right(false);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to delete file: $e',
        path: filePath,
      ));
    }
  }

  @override
  Future<Either<FileFailure, String>> moveFile(
    String sourcePath,
    String destinationPath,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return Left(StorageFailure(
          message: 'Source file does not exist',
          errorType: StorageErrorType.fileNotFound,
          path: sourcePath,
        ));
      }

      // Create destination directory if needed
      final destDir = Directory(path.dirname(destinationPath));
      await destDir.create(recursive: true);

      final movedFile = await sourceFile.rename(destinationPath);
      return Right(movedFile.path);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to move file: $e',
        path: sourcePath,
      ));
    }
  }

  @override
  Future<Either<FileFailure, String>> copyFile(
    String sourcePath,
    String destinationPath,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return Left(StorageFailure(
          message: 'Source file does not exist',
          errorType: StorageErrorType.fileNotFound,
          path: sourcePath,
        ));
      }

      // Create destination directory if needed
      final destDir = Directory(path.dirname(destinationPath));
      await destDir.create(recursive: true);

      final copiedFile = await sourceFile.copy(destinationPath);
      return Right(copiedFile.path);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to copy file: $e',
        path: sourcePath,
      ));
    }
  }

  @override
  Future<Either<FileFailure, bool>> verifyFileIntegrity(
    String filePath,
    String expectedHash, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Left(FileIntegrityFailure(
          message: 'File does not exist for integrity verification',
          filePath: filePath,
        ));
      }

      final bytes = await file.readAsBytes();
      final digest = _calculateHash(bytes, algorithm);
      final actualHash = digest.toString();

      final isValid = actualHash.toLowerCase() == expectedHash.toLowerCase();
      
      if (!isValid) {
        return Left(FileIntegrityFailure(
          message: 'File integrity verification failed',
          expectedHash: expectedHash,
          actualHash: actualHash,
          filePath: filePath,
        ));
      }

      return const Right(true);
    } catch (e) {
      return Left(FileIntegrityFailure(
        message: 'Failed to verify file integrity: $e',
        filePath: filePath,
      ));
    }
  }

  @override
  Future<Either<FileFailure, int>> getAvailableStorageSpace() async {
    try {
      if (_appDocumentsDir == null) {
        await _initializeDirectories();
      }
      
      final dir = Directory(_appDocumentsDir!);
      // Check if directory exists before getting storage info
      await dir.stat();
      
      // Note: This is a simplified implementation
      // In a real app, you might want to use platform-specific code
      // to get accurate storage information
      return const Right(1024 * 1024 * 1024); // 1GB placeholder
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to get available storage space: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, int>> getUsedStorageSpace() async {
    try {
      if (_appDocumentsDir == null) {
        await _initializeDirectories();
      }
      
      final usedSpace = await _calculateDirectorySize(Directory(_appDocumentsDir!));
      return Right(usedSpace);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to get used storage space: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, CleanupResult>> cleanupTemporaryFiles({
    Duration? olderThan,
  }) async {
    try {
      if (_tempDir == null) {
        await _initializeDirectories();
      }
      
      final tempDirectory = Directory(_tempDir!);
      if (!await tempDirectory.exists()) {
        return const Right(CleanupResult(
          filesDeleted: 0,
          bytesFreed: 0,
          operationDuration: Duration.zero,
        ));
      }

      final startTime = DateTime.now();
      final cutoffTime = olderThan != null 
          ? DateTime.now().subtract(olderThan)
          : DateTime.now().subtract(StorageConstants.tempFileRetention);

      int filesDeleted = 0;
      int bytesFreed = 0;
      final errors = <String>[];

      await for (final entity in tempDirectory.list(recursive: true)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoffTime)) {
              bytesFreed += stat.size;
              await entity.delete();
              filesDeleted++;
            }
          } catch (e) {
            errors.add('Failed to delete ${entity.path}: $e');
          }
        }
      }

      final duration = DateTime.now().difference(startTime);
      
      return Right(CleanupResult(
        filesDeleted: filesDeleted,
        bytesFreed: bytesFreed,
        operationDuration: duration,
        errors: errors,
      ));
    } catch (e) {
      return Left(CleanupFailure(
        message: 'Failed to cleanup temporary files: $e',
        targetPath: _tempDir,
      ));
    }
  }

  @override
  Future<Either<FileFailure, CleanupResult>> cleanupCachedFiles({
    Duration? olderThan,
    int? maxCacheSize,
  }) async {
    try {
      if (_cacheDir == null) {
        await _initializeDirectories();
      }
      
      final cacheDirectory = Directory(_cacheDir!);
      if (!await cacheDirectory.exists()) {
        return const Right(CleanupResult(
          filesDeleted: 0,
          bytesFreed: 0,
          operationDuration: Duration.zero,
        ));
      }

      final startTime = DateTime.now();
      final cutoffTime = olderThan != null 
          ? DateTime.now().subtract(olderThan)
          : DateTime.now().subtract(StorageConstants.cacheFileRetention);

      int filesDeleted = 0;
      int bytesFreed = 0;
      final errors = <String>[];

      // Get all cache files with their sizes and modification times
      final cacheFiles = <MapEntry<File, FileStat>>[];
      await for (final entity in cacheDirectory.list(recursive: true)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            cacheFiles.add(MapEntry(entity, stat));
          } catch (e) {
            errors.add('Failed to stat ${entity.path}: $e');
          }
        }
      }

      // Sort by modification time (oldest first)
      cacheFiles.sort((a, b) => a.value.modified.compareTo(b.value.modified));

      // Delete old files or files exceeding cache size limit
      int currentCacheSize = cacheFiles.fold<int>(0, (sum, entry) => sum + entry.value.size);
      final maxSize = maxCacheSize ?? StorageConstants.maxCacheSize;

      for (final entry in cacheFiles) {
        final file = entry.key;
        final stat = entry.value;
        
        final shouldDelete = stat.modified.isBefore(cutoffTime) || 
                           currentCacheSize > maxSize;
        
        if (shouldDelete) {
          try {
            bytesFreed += stat.size;
            currentCacheSize -= stat.size;
            await file.delete();
            filesDeleted++;
          } catch (e) {
            errors.add('Failed to delete ${file.path}: $e');
          }
        }
      }

      final duration = DateTime.now().difference(startTime);
      
      return Right(CleanupResult(
        filesDeleted: filesDeleted,
        bytesFreed: bytesFreed,
        operationDuration: duration,
        errors: errors,
      ));
    } catch (e) {
      return Left(CleanupFailure(
        message: 'Failed to cleanup cached files: $e',
        targetPath: _cacheDir,
      ));
    }
  }

  @override
  Future<Either<FileFailure, CleanupResult>> cleanupOrphanedFiles() async {
    try {
      // This would require database access to check which files are still referenced
      // For now, return a placeholder implementation
      return const Right(CleanupResult(
        filesDeleted: 0,
        bytesFreed: 0,
        operationDuration: Duration.zero,
      ));
    } catch (e) {
      return Left(CleanupFailure(
        message: 'Failed to cleanup orphaned files: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, CleanupResult>> performFullCleanup({
    bool includeTemporary = true,
    bool includeCache = true,
    bool includeOrphaned = true,
    Duration? olderThan,
  }) async {
    try {
      final startTime = DateTime.now();
      int totalFilesDeleted = 0;
      int totalBytesFreed = 0;
      final allErrors = <String>[];

      // Cleanup temporary files
      if (includeTemporary) {
        final tempResult = await cleanupTemporaryFiles(olderThan: olderThan);
        tempResult.fold(
          (failure) => allErrors.add('Temp cleanup failed: ${failure.message}'),
          (result) {
            totalFilesDeleted += result.filesDeleted;
            totalBytesFreed += result.bytesFreed;
            allErrors.addAll(result.errors);
          },
        );
      }

      // Cleanup cached files
      if (includeCache) {
        final cacheResult = await cleanupCachedFiles(olderThan: olderThan);
        cacheResult.fold(
          (failure) => allErrors.add('Cache cleanup failed: ${failure.message}'),
          (result) {
            totalFilesDeleted += result.filesDeleted;
            totalBytesFreed += result.bytesFreed;
            allErrors.addAll(result.errors);
          },
        );
      }

      // Cleanup orphaned files
      if (includeOrphaned) {
        final orphanedResult = await cleanupOrphanedFiles();
        orphanedResult.fold(
          (failure) => allErrors.add('Orphaned cleanup failed: ${failure.message}'),
          (result) {
            totalFilesDeleted += result.filesDeleted;
            totalBytesFreed += result.bytesFreed;
            allErrors.addAll(result.errors);
          },
        );
      }

      final duration = DateTime.now().difference(startTime);

      return Right(CleanupResult(
        filesDeleted: totalFilesDeleted,
        bytesFreed: totalBytesFreed,
        operationDuration: duration,
        errors: allErrors,
      ));
    } catch (e) {
      return Left(CleanupFailure(
        message: 'Failed to perform full cleanup: $e',
      ));
    }
  }

  @override
  Future<Either<FileFailure, bool>> createDirectoryStructure() async {
    try {
      if (_appDocumentsDir == null) {
        await _initializeDirectories();
      }

      final directories = [
        _booksDir!,
        _coversDir!,
        _tempDir!,
        _cacheDir!,
      ];

      for (final dirPath in directories) {
        final directory = Directory(dirPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }

      return const Right(true);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to create directory structure: $e',
        errorType: StorageErrorType.pathNotFound,
      ));
    }
  }

  @override
  Either<FileFailure, bool> validateFileFormat(String fileName) {
    try {
      final extension = path.extension(fileName).toLowerCase();
      final supportedFormats = [StorageConstants.extEpub, StorageConstants.extPdf, StorageConstants.extTxt];
      
      if (!supportedFormats.contains(extension)) {
        return Left(UnsupportedFormatFailure(
          message: 'File format not supported: $extension',
          fileExtension: extension,
          supportedFormats: supportedFormats,
        ));
      }
      
      return const Right(true);
    } catch (e) {
      return Left(UnsupportedFormatFailure(
        message: 'Failed to validate file format: $e',
      ));
    }
  }

  @override
  Either<FileFailure, bool> validateFileSize(int fileSizeBytes) {
    try {
      if (fileSizeBytes > StorageConstants.maxBookFileSize) {
        return Left(FileSizeFailure(
          message: 'File size exceeds maximum allowed size',
          actualSize: fileSizeBytes,
          maxAllowedSize: StorageConstants.maxBookFileSize,
        ));
      }
      
      return const Right(true);
    } catch (e) {
      return Left(FileSizeFailure(
        message: 'Failed to validate file size: $e',
        actualSize: fileSizeBytes,
      ));
    }
  }

  @override
  Stream<DownloadItem> get downloadProgressStream => _progressController.stream;

  @override
  Stream<List<DownloadItem>> get downloadQueueStream => _queueController.stream;

  /// Generate unique download ID
  String _generateDownloadId() {
    return 'download_${DateTime.now().millisecondsSinceEpoch}_${_downloadQueue.length}';
  }

  /// Calculate hash for file integrity verification
  Digest _calculateHash(Uint8List bytes, HashAlgorithm algorithm) {
    switch (algorithm) {
      case HashAlgorithm.md5:
        return md5.convert(bytes);
      case HashAlgorithm.sha1:
        return sha1.convert(bytes);
      case HashAlgorithm.sha256:
        return sha256.convert(bytes);
      case HashAlgorithm.sha512:
        return sha512.convert(bytes);
    }
  }

  /// Calculate average download speed
  double _calculateAverageSpeed(List<DownloadItem> downloads) {
    final completedDownloads = downloads.where((d) => d.isCompleted).toList();
    if (completedDownloads.isEmpty) return 0.0;

    double totalSpeed = 0.0;
    int validSpeeds = 0;

    for (final download in completedDownloads) {
      if (download.startedAt != null && download.completedAt != null) {
        final duration = download.completedAt!.difference(download.startedAt!);
        if (duration.inSeconds > 0) {
          final speed = download.downloadedBytes / duration.inSeconds;
          totalSpeed += speed;
          validSpeeds++;
        }
      }
    }

    return validSpeeds > 0 ? totalSpeed / validSpeeds : 0.0;
  }

  /// Calculate directory size recursively
  Future<int> _calculateDirectorySize(Directory directory) async {
    int size = 0;
    
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          size += stat.size;
        }
      }
    } catch (e) {
      // Handle permission or access errors
    }
    
    return size;
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
    _queueController.close();
    
    // Cancel all active downloads
    for (final cancelToken in _cancelTokens.values) {
      cancelToken.cancel('FileManager disposed');
    }
    _cancelTokens.clear();
  }
}
