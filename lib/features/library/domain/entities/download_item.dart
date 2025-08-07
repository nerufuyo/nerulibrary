import 'package:equatable/equatable.dart';

/// Download status enumeration
enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Download priority levels
enum DownloadPriority {
  low,
  normal,
  high,
  critical,
}

/// Download item entity representing a file download operation
/// 
/// Manages download metadata, progress tracking, and status information
/// for files in the download queue system.
class DownloadItem extends Equatable {
  final String id;
  final String bookId;
  final String url;
  final String fileName;
  final String? localPath;
  final int? expectedSize;
  final int downloadedBytes;
  final DownloadStatus status;
  final DownloadPriority priority;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final String? expectedHash;
  final Map<String, dynamic>? metadata;
  final int retryCount;
  final int maxRetries;

  const DownloadItem({
    required this.id,
    required this.bookId,
    required this.url,
    required this.fileName,
    this.localPath,
    this.expectedSize,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.queued,
    this.priority = DownloadPriority.normal,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.expectedHash,
    this.metadata,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  /// Creates a copy of this download item with updated fields
  DownloadItem copyWith({
    String? id,
    String? bookId,
    String? url,
    String? fileName,
    String? localPath,
    int? expectedSize,
    int? downloadedBytes,
    DownloadStatus? status,
    DownloadPriority? priority,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? expectedHash,
    Map<String, dynamic>? metadata,
    int? retryCount,
    int? maxRetries,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      expectedSize: expectedSize ?? this.expectedSize,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      expectedHash: expectedHash ?? this.expectedHash,
      metadata: metadata ?? this.metadata,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  /// Calculates download progress as a percentage (0.0 to 1.0)
  double get progress {
    if (expectedSize == null || expectedSize! <= 0) return 0.0;
    return (downloadedBytes / expectedSize!).clamp(0.0, 1.0);
  }

  /// Calculates download speed in bytes per second
  double? get downloadSpeed {
    if (startedAt == null || status != DownloadStatus.downloading) return null;
    
    final duration = DateTime.now().difference(startedAt!);
    if (duration.inSeconds <= 0) return null;
    
    return downloadedBytes / duration.inSeconds;
  }

  /// Estimates remaining time for download completion
  Duration? get estimatedTimeRemaining {
    final speed = downloadSpeed;
    if (speed == null || speed <= 0 || expectedSize == null) return null;
    
    final remainingBytes = expectedSize! - downloadedBytes;
    if (remainingBytes <= 0) return Duration.zero;
    
    return Duration(seconds: (remainingBytes / speed).round());
  }

  /// Checks if the download can be retried
  bool get canRetry {
    return status == DownloadStatus.failed && retryCount < maxRetries;
  }

  /// Checks if the download is in progress
  bool get isInProgress {
    return status == DownloadStatus.downloading;
  }

  /// Checks if the download is completed successfully
  bool get isCompleted {
    return status == DownloadStatus.completed;
  }

  /// Checks if the download has failed
  bool get hasFailed {
    return status == DownloadStatus.failed;
  }

  /// Checks if the download is paused
  bool get isPaused {
    return status == DownloadStatus.paused;
  }

  /// Checks if the download is queued
  bool get isQueued {
    return status == DownloadStatus.queued;
  }

  /// Checks if the download is cancelled
  bool get isCancelled {
    return status == DownloadStatus.cancelled;
  }

  /// Gets the file extension from the fileName
  String? get fileExtension {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return null;
    return fileName.substring(lastDot + 1).toLowerCase();
  }

  /// Validates if the download item has all required fields
  bool get isValid {
    return id.isNotEmpty && 
           bookId.isNotEmpty && 
           url.isNotEmpty && 
           fileName.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        url,
        fileName,
        localPath,
        expectedSize,
        downloadedBytes,
        status,
        priority,
        createdAt,
        startedAt,
        completedAt,
        errorMessage,
        expectedHash,
        metadata,
        retryCount,
        maxRetries,
      ];

  @override
  String toString() {
    return 'DownloadItem{id: $id, fileName: $fileName, status: $status, progress: ${(progress * 100).toStringAsFixed(1)}%}';
  }
}

/// Download statistics entity for tracking download performance
class DownloadStatistics extends Equatable {
  final int totalDownloads;
  final int completedDownloads;
  final int failedDownloads;
  final int activeDownloads;
  final int queuedDownloads;
  final int totalBytesDownloaded;
  final double averageDownloadSpeed;
  final DateTime lastUpdated;

  const DownloadStatistics({
    this.totalDownloads = 0,
    this.completedDownloads = 0,
    this.failedDownloads = 0,
    this.activeDownloads = 0,
    this.queuedDownloads = 0,
    this.totalBytesDownloaded = 0,
    this.averageDownloadSpeed = 0.0,
    required this.lastUpdated,
  });

  /// Success rate as a percentage (0.0 to 1.0)
  double get successRate {
    if (totalDownloads == 0) return 0.0;
    return completedDownloads / totalDownloads;
  }

  /// Failure rate as a percentage (0.0 to 1.0)
  double get failureRate {
    if (totalDownloads == 0) return 0.0;
    return failedDownloads / totalDownloads;
  }

  @override
  List<Object?> get props => [
        totalDownloads,
        completedDownloads,
        failedDownloads,
        activeDownloads,
        queuedDownloads,
        totalBytesDownloaded,
        averageDownloadSpeed,
        lastUpdated,
      ];

  @override
  String toString() {
    return 'DownloadStatistics{total: $totalDownloads, completed: $completedDownloads, success rate: ${(successRate * 100).toStringAsFixed(1)}%}';
  }
}
