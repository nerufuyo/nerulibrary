import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../constants/storage_constants.dart';
import '../errors/exceptions.dart' as app_exceptions;

/// Local storage management and file operations
/// 
/// Handles file system operations for the application including
/// creating directories, managing file paths, and storage cleanup.
class LocalStorage {
  static LocalStorage? _instance;
  static LocalStorage get instance => _instance ??= LocalStorage._();
  
  String? _documentsPath;
  String? _appSupportPath;
  String? _cachePath;
  String? _tempPath;
  
  LocalStorage._();
  
  /// Initialize storage paths
  Future<void> initialize() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final appSupportDir = await getApplicationSupportDirectory();
      final cacheDir = await getTemporaryDirectory();
      final tempDir = await getTemporaryDirectory();
      
      _documentsPath = documentsDir.path;
      _appSupportPath = appSupportDir.path;
      _cachePath = cacheDir.path;
      _tempPath = tempDir.path;
      
      // Create required directories
      await _createRequiredDirectories();
      
    } catch (e) {
      throw app_exceptions.StorageException(
        'Failed to initialize local storage: ${e.toString()}',
      );
    }
  }
  
  /// Create required application directories
  Future<void> _createRequiredDirectories() async {
    final requiredDirs = [
      booksDirectory,
      coversDirectory,
      tempDirectory,
      cacheDirectory,
      logsDirectory,
    ];
    
    for (final dir in requiredDirs) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
  }
  
  /// Get books storage directory
  String get booksDirectory {
    _ensureInitialized();
    return path.join(_documentsPath!, StorageConstants.dirBooks);
  }
  
  /// Get covers storage directory
  String get coversDirectory {
    _ensureInitialized();
    return path.join(_documentsPath!, StorageConstants.dirCovers);
  }
  
  /// Get temporary files directory
  String get tempDirectory {
    _ensureInitialized();
    return path.join(_tempPath!, StorageConstants.dirTemp);
  }
  
  /// Get cache directory
  String get cacheDirectory {
    _ensureInitialized();
    return path.join(_cachePath!, StorageConstants.dirCache);
  }
  
  /// Get logs directory
  String get logsDirectory {
    _ensureInitialized();
    return path.join(_appSupportPath!, StorageConstants.dirLogs);
  }
  
  /// Get documents directory path
  String get documentsPath {
    _ensureInitialized();
    return _documentsPath!;
  }
  
  /// Get application support directory path
  String get appSupportPath {
    _ensureInitialized();
    return _appSupportPath!;
  }
  
  /// Generate book file path
  String getBookFilePath(String bookId, String format) {
    final filename = StorageConstants.patternBookFile
        .replaceAll('{book_id}', bookId)
        .replaceAll('{format}', format);
    return path.join(booksDirectory, filename);
  }
  
  /// Generate cover file path
  String getCoverFilePath(String bookId) {
    final filename = StorageConstants.patternCoverFile
        .replaceAll('{book_id}', bookId);
    return path.join(coversDirectory, filename);
  }
  
  /// Generate temporary file path
  String getTempFilePath(String filename) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final tempFilename = StorageConstants.patternTempFile
        .replaceAll('{timestamp}', timestamp)
        .replaceAll('{filename}', filename);
    return path.join(tempDirectory, tempFilename);
  }
  
  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
  
  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Delete file
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      throw app_exceptions.StorageException(
        'Failed to delete file: ${e.toString()}',
        path: filePath,
      );
    }
  }
  
  /// Move file from source to destination
  Future<bool> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        // Ensure destination directory exists
        final destinationDir = Directory(path.dirname(destinationPath));
        if (!await destinationDir.exists()) {
          await destinationDir.create(recursive: true);
        }
        
        await sourceFile.rename(destinationPath);
        return true;
      }
      return false;
    } catch (e) {
      throw app_exceptions.StorageException(
        'Failed to move file: ${e.toString()}',
        path: sourcePath,
      );
    }
  }
  
  /// Copy file from source to destination
  Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        // Ensure destination directory exists
        final destinationDir = Directory(path.dirname(destinationPath));
        if (!await destinationDir.exists()) {
          await destinationDir.create(recursive: true);
        }
        
        await sourceFile.copy(destinationPath);
        return true;
      }
      return false;
    } catch (e) {
      throw app_exceptions.StorageException(
        'Failed to copy file: ${e.toString()}',
        path: sourcePath,
      );
    }
  }
  
  /// Get directory size in bytes
  Future<int> getDirectorySize(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  /// Clean up temporary files older than specified duration
  Future<void> cleanupTempFiles({
    Duration retention = StorageConstants.tempFileRetention,
  }) async {
    try {
      final tempDir = Directory(tempDirectory);
      if (!await tempDir.exists()) return;
      
      final cutoffDate = DateTime.now().subtract(retention);
      
      await for (final entity in tempDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      throw app_exceptions.StorageException(
        'Failed to cleanup temp files: ${e.toString()}',
      );
    }
  }
  
  /// Clean up cache files older than specified duration
  Future<void> cleanupCacheFiles({
    Duration retention = StorageConstants.cacheFileRetention,
  }) async {
    try {
      final cacheDir = Directory(cacheDirectory);
      if (!await cacheDir.exists()) return;
      
      final cutoffDate = DateTime.now().subtract(retention);
      
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      throw app_exceptions.StorageException(
        'Failed to cleanup cache files: ${e.toString()}',
      );
    }
  }
  
  /// Get available storage space in bytes
  Future<int> getAvailableSpace() async {
    try {
      // Note: Flutter doesn't provide direct access to available space
      // This is a simplified implementation
      return 1024 * 1024 * 1024; // 1GB placeholder
    } catch (e) {
      return 0;
    }
  }
  
  /// Check if there's enough space for a file
  Future<bool> hasEnoughSpace(int requiredBytes) async {
    final availableSpace = await getAvailableSpace();
    return availableSpace >= requiredBytes;
  }
  
  /// Ensure storage is initialized
  void _ensureInitialized() {
    if (_documentsPath == null) {
      throw app_exceptions.StorageException(
        'LocalStorage not initialized. Call initialize() first.',
      );
    }
  }
  
  /// Get storage usage statistics
  Future<StorageStats> getStorageStats() async {
    final booksSize = await getDirectorySize(booksDirectory);
    final coversSize = await getDirectorySize(coversDirectory);
    final cacheSize = await getDirectorySize(cacheDirectory);
    final tempSize = await getDirectorySize(tempDirectory);
    final logsSize = await getDirectorySize(logsDirectory);
    
    return StorageStats(
      booksSize: booksSize,
      coversSize: coversSize,
      cacheSize: cacheSize,
      tempSize: tempSize,
      logsSize: logsSize,
      totalSize: booksSize + coversSize + cacheSize + tempSize + logsSize,
    );
  }
}

/// Storage usage statistics
class StorageStats {
  final int booksSize;
  final int coversSize;
  final int cacheSize;
  final int tempSize;
  final int logsSize;
  final int totalSize;
  
  const StorageStats({
    required this.booksSize,
    required this.coversSize,
    required this.cacheSize,
    required this.tempSize,
    required this.logsSize,
    required this.totalSize,
  });
  
  /// Format size in human-readable format
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Get formatted total size
  String get formattedTotalSize => formatSize(totalSize);
  
  /// Get formatted books size
  String get formattedBooksSize => formatSize(booksSize);
  
  /// Get formatted covers size
  String get formattedCoversSize => formatSize(coversSize);
  
  /// Get formatted cache size
  String get formattedCacheSize => formatSize(cacheSize);
}
