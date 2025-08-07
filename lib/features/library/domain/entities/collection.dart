import 'package:equatable/equatable.dart';

/// Collection entity for organizing books into custom collections
/// 
/// Contains information about user-created collections for organizing
/// their personal library with support for public/private collections.
class Collection extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? userId;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int bookCount;

  const Collection({
    required this.id,
    required this.name,
    this.description,
    this.userId,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.bookCount = 0,
  });

  /// Create a copy of this collection with updated fields
  Collection copyWith({
    String? id,
    String? name,
    String? description,
    String? userId,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? bookCount,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookCount: bookCount ?? this.bookCount,
    );
  }

  /// Check if collection has description
  bool get hasDescription => description != null && description!.isNotEmpty;

  /// Check if collection is empty
  bool get isEmpty => bookCount == 0;

  /// Check if collection is private
  bool get isPrivate => !isPublic;

  /// Get privacy status as string
  String get privacyStatus => isPublic ? 'Public' : 'Private';

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        userId,
        isPublic,
        createdAt,
        updatedAt,
        bookCount,
      ];

  @override
  String toString() => 'Collection(id: $id, name: $name, books: $bookCount)';
}

/// Download entity for tracking book download progress
/// 
/// Contains information about book download status, progress,
/// and file management for offline reading functionality.
class Download extends Equatable {
  final String id;
  final String bookId;
  final String downloadUrl;
  final String? filePath;
  final DownloadStatus status;
  final double progress;
  final int? totalBytes;
  final int downloadedBytes;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const Download({
    required this.id,
    required this.bookId,
    required this.downloadUrl,
    this.filePath,
    required this.status,
    required this.progress,
    this.totalBytes,
    required this.downloadedBytes,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// Create a copy of this download with updated fields
  Download copyWith({
    String? id,
    String? bookId,
    String? downloadUrl,
    String? filePath,
    DownloadStatus? status,
    double? progress,
    int? totalBytes,
    int? downloadedBytes,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Download(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Check if download is completed
  bool get isCompleted => status == DownloadStatus.completed;

  /// Check if download is in progress
  bool get isInProgress => status == DownloadStatus.downloading;

  /// Check if download failed
  bool get isFailed => status == DownloadStatus.failed;

  /// Check if download is paused
  bool get isPaused => status == DownloadStatus.paused;

  /// Check if download is pending
  bool get isPending => status == DownloadStatus.pending;

  /// Get downloaded size in MB
  double get downloadedSizeMB => downloadedBytes / (1024 * 1024);

  /// Get total size in MB
  double? get totalSizeMB {
    if (totalBytes == null) return null;
    return totalBytes! / (1024 * 1024);
  }

  /// Get remaining bytes to download
  int? get remainingBytes {
    if (totalBytes == null) return null;
    return totalBytes! - downloadedBytes;
  }

  /// Get download speed estimate (bytes per second)
  double? getDownloadSpeed() {
    if (createdAt == updatedAt || downloadedBytes == 0) return null;
    final duration = updatedAt.difference(createdAt).inSeconds;
    if (duration == 0) return null;
    return downloadedBytes / duration;
  }

  /// Get estimated time remaining in seconds
  int? getEstimatedTimeRemaining() {
    final speed = getDownloadSpeed();
    final remaining = remainingBytes;
    if (speed == null || remaining == null || speed == 0) return null;
    return (remaining / speed).round();
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        downloadUrl,
        filePath,
        status,
        progress,
        totalBytes,
        downloadedBytes,
        errorMessage,
        createdAt,
        updatedAt,
        completedAt,
      ];

  @override
  String toString() => 'Download(id: $id, bookId: $bookId, status: $status, progress: ${progress.toStringAsFixed(1)}%)';
}

/// Download status enumeration
enum DownloadStatus {
  pending('pending'),
  downloading('downloading'),
  paused('paused'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const DownloadStatus(this.value);
  final String value;

  /// Create DownloadStatus from string value
  static DownloadStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return DownloadStatus.pending;
      case 'downloading':
        return DownloadStatus.downloading;
      case 'paused':
        return DownloadStatus.paused;
      case 'completed':
        return DownloadStatus.completed;
      case 'failed':
        return DownloadStatus.failed;
      case 'cancelled':
        return DownloadStatus.cancelled;
      default:
        return DownloadStatus.pending;
    }
  }

  /// Get display name for status
  String get displayName {
    switch (this) {
      case DownloadStatus.pending:
        return 'Pending';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if status allows retry
  bool get canRetry {
    switch (this) {
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return true;
      case DownloadStatus.pending:
      case DownloadStatus.downloading:
      case DownloadStatus.paused:
      case DownloadStatus.completed:
        return false;
    }
  }

  /// Check if status allows pause
  bool get canPause {
    switch (this) {
      case DownloadStatus.downloading:
        return true;
      case DownloadStatus.pending:
      case DownloadStatus.paused:
      case DownloadStatus.completed:
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return false;
    }
  }

  /// Check if status allows resume
  bool get canResume {
    switch (this) {
      case DownloadStatus.paused:
        return true;
      case DownloadStatus.pending:
      case DownloadStatus.downloading:
      case DownloadStatus.completed:
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return false;
    }
  }
}
