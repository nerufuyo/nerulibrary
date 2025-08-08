import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import '../network/dio_client.dart';
import '../storage/local_storage.dart';
import '../constants/storage_constants.dart';
import '../errors/exceptions.dart' as app_exceptions;

/// File management operations for downloads and file handling
/// 
/// Handles file downloads, validation, compression, and file system operations
/// for books, covers, and other application assets.
class FileManager {
  static FileManager? _instance;
  static FileManager get instance => _instance ??= FileManager._();
  
  final DioClient _dioClient = DioClient.instance;
  final LocalStorage _localStorage = LocalStorage.instance;
  
  FileManager._();
  
  /// Download a file from URL to local storage
  Future<String> downloadFile({
    required String url,
    required String fileName,
    String? customPath,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // Determine destination path
      final destinationPath = customPath ?? 
          _localStorage.getTempFilePath(fileName);
      
      // Ensure directory exists
      final directory = Directory(path.dirname(destinationPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Download the file
      await _dioClient.download(
        url,
        destinationPath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );
      
      // Validate downloaded file
      if (!await _validateDownloadedFile(destinationPath)) {
        await File(destinationPath).delete();
        throw app_exceptions.FileSystemException(
          'Downloaded file validation failed: $destinationPath',
        );
      }
      
      return destinationPath;
      
    } catch (e) {
      if (e is app_exceptions.AppException) {
        rethrow;
      }
      throw app_exceptions.FileSystemException(
        'Failed to download file: ${e.toString()} (path: $customPath)',
      );
    }
  }
  
  /// Download book file with proper naming and validation
  Future<String> downloadBook({
    required String url,
    required String bookId,
    required String format,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // Validate format
      if (!_isValidBookFormat(format)) {
        throw app_exceptions.ValidationException(
          'Unsupported book format: $format',
        );
      }
      
      // Generate file path
      final extension = _getFileExtension(format);
      final fileName = '$bookId$extension';
      final filePath = _localStorage.getBookFilePath(bookId, format);
      
      // Check if file already exists
      if (await _localStorage.fileExists(filePath)) {
        return filePath;
      }
      
      // Download to temporary location first
      final tempPath = await downloadFile(
        url: url,
        fileName: fileName,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      
      // Validate book file format
      if (!await _validateBookFile(tempPath, format)) {
        await File(tempPath).delete();
        throw app_exceptions.BookException(
          'Invalid book file format',
          bookId: bookId,
          format: format,
        );
      }
      
      // Move to final location
      await _localStorage.moveFile(tempPath, filePath);
      
      return filePath;
      
    } catch (e) {
      if (e is app_exceptions.AppException) {
        rethrow;
      }
      throw app_exceptions.BookException(
        'Failed to download book: ${e.toString()}',
        bookId: bookId,
        format: format,
      );
    }
  }
  
  /// Download cover image
  Future<String> downloadCover({
    required String url,
    required String bookId,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final fileName = 'cover_$bookId.jpg';
      final filePath = _localStorage.getCoverFilePath(bookId);
      
      // Check if cover already exists
      if (await _localStorage.fileExists(filePath)) {
        return filePath;
      }
      
      // Download to temporary location first
      final tempPath = await downloadFile(
        url: url,
        fileName: fileName,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      
      // Validate image file
      if (!await _validateImageFile(tempPath)) {
        await File(tempPath).delete();
        throw app_exceptions.FileSystemException(
          'Invalid image file: $tempPath',
        );
      }
      
      // Check file size limit
      final fileSize = await _localStorage.getFileSize(tempPath);
      if (fileSize > StorageConstants.maxCoverFileSize) {
        await File(tempPath).delete();
        throw app_exceptions.FileSystemException(
          'Cover image too large: ${_formatBytes(fileSize)} (path: $tempPath)',
        );
      }
      
      // Move to final location
      await _localStorage.moveFile(tempPath, filePath);
      
      return filePath;
      
    } catch (e) {
      if (e is app_exceptions.AppException) {
        rethrow;
      }
      throw app_exceptions.FileSystemException(
        'Failed to download cover: ${e.toString()}',
      );
    }
  }
  
  /// Validate downloaded file
  Future<bool> _validateDownloadedFile(String filePath) async {
    try {
      final file = File(filePath);
      
      // Check if file exists
      if (!await file.exists()) return false;
      
      // Check if file is not empty
      final size = await file.length();
      if (size == 0) return false;
      
      // Check if file is readable
      try {
        await file.readAsBytes();
        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Validate book file format
  Future<bool> _validateBookFile(String filePath, String format) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      switch (format.toLowerCase()) {
        case 'epub':
          return _validateEpubFile(bytes);
        case 'pdf':
          return _validatePdfFile(bytes);
        case 'txt':
          return _validateTextFile(bytes);
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Validate EPUB file format
  bool _validateEpubFile(Uint8List bytes) {
    // EPUB files are ZIP archives with specific structure
    // Check for ZIP file signature (PK)
    if (bytes.length < 4) return false;
    return bytes[0] == 0x50 && bytes[1] == 0x4B;
  }
  
  /// Validate PDF file format
  bool _validatePdfFile(Uint8List bytes) {
    // PDF files start with "%PDF"
    if (bytes.length < 4) return false;
    return bytes[0] == 0x25 && // %
           bytes[1] == 0x50 && // P
           bytes[2] == 0x44 && // D
           bytes[3] == 0x46;   // F
  }
  
  /// Validate text file format
  bool _validateTextFile(Uint8List bytes) {
    // For text files, just check if it's valid UTF-8
    try {
      final String content = String.fromCharCodes(bytes);
      return content.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Validate image file
  Future<bool> _validateImageFile(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      if (bytes.length < 4) return false;
      
      // Check for common image file signatures
      // JPEG: FF D8 FF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return true;
      }
      
      // PNG: 89 50 4E 47
      if (bytes[0] == 0x89 && 
          bytes[1] == 0x50 && 
          bytes[2] == 0x4E && 
          bytes[3] == 0x47) {
        return true;
      }
      
      // GIF: 47 49 46 38
      if (bytes[0] == 0x47 && 
          bytes[1] == 0x49 && 
          bytes[2] == 0x46 && 
          bytes[3] == 0x38) {
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if book format is supported
  bool _isValidBookFormat(String format) {
    const supportedFormats = ['epub', 'pdf', 'txt'];
    return supportedFormats.contains(format.toLowerCase());
  }
  
  /// Get file extension for format
  String _getFileExtension(String format) {
    switch (format.toLowerCase()) {
      case 'epub':
        return StorageConstants.extEpub;
      case 'pdf':
        return StorageConstants.extPdf;
      case 'txt':
        return StorageConstants.extTxt;
      default:
        return '.${format.toLowerCase()}';
    }
  }
  
  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Get file info
  Future<FileInfo> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw app_exceptions.FileSystemException(
          'File does not exist: $filePath',
        );
      }
      
      final stat = await file.stat();
      final size = await file.length();
      final extension = path.extension(filePath);
      final name = path.basenameWithoutExtension(filePath);
      
      return FileInfo(
        path: filePath,
        name: name,
        extension: extension,
        size: size,
        createdAt: stat.changed,
        modifiedAt: stat.modified,
        isReadable: true, // Simplified for now
        isWritable: true, // Simplified for now
      );
    } catch (e) {
      if (e is app_exceptions.AppException) {
        rethrow;
      }
      throw app_exceptions.FileSystemException(
        'Failed to get file info: ${e.toString()} (path: $filePath)',
      );
    }
  }
  
  /// Delete file safely
  Future<bool> deleteFile(String filePath) async {
    return await _localStorage.deleteFile(filePath);
  }
  
  /// Check available space before download
  Future<bool> checkSpaceForDownload(int fileSize) async {
    return await _localStorage.hasEnoughSpace(fileSize);
  }
}

/// File information class
class FileInfo {
  final String path;
  final String name;
  final String extension;
  final int size;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isReadable;
  final bool isWritable;
  
  const FileInfo({
    required this.path,
    required this.name,
    required this.extension,
    required this.size,
    required this.createdAt,
    required this.modifiedAt,
    required this.isReadable,
    required this.isWritable,
  });
  
  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Check if file is an image
  bool get isImage {
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return imageExtensions.contains(extension.toLowerCase());
  }
  
  /// Check if file is a book
  bool get isBook {
    const bookExtensions = ['.epub', '.pdf', '.txt'];
    return bookExtensions.contains(extension.toLowerCase());
  }
}
