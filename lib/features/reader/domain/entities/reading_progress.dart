import 'package:equatable/equatable.dart';

/// Reading progress entity for tracking book reading progress
/// 
/// Contains information about current reading position,
/// progress percentage, and reading time for a specific book.
class ReadingProgress extends Equatable {
  final String id;
  final String bookId;
  final String? userId;
  final int currentPage;
  final int totalPages;
  final double progressPercentage;
  final int readingTimeMinutes;
  final String? lastPosition;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReadingProgress({
    required this.id,
    required this.bookId,
    this.userId,
    required this.currentPage,
    required this.totalPages,
    required this.progressPercentage,
    required this.readingTimeMinutes,
    this.lastPosition,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this reading progress with updated fields
  ReadingProgress copyWith({
    String? id,
    String? bookId,
    String? userId,
    int? currentPage,
    int? totalPages,
    double? progressPercentage,
    int? readingTimeMinutes,
    String? lastPosition,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReadingProgress(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      lastPosition: lastPosition ?? this.lastPosition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if the book is completed
  bool get isCompleted => progressPercentage >= 100.0;

  /// Check if reading has started
  bool get hasStarted => currentPage > 0 || progressPercentage > 0;

  /// Get reading time in hours
  double get readingTimeHours => readingTimeMinutes / 60.0;

  /// Get pages remaining
  int get pagesRemaining => totalPages - currentPage;

  /// Get progress as a fraction (0.0 to 1.0)
  double get progressFraction => progressPercentage / 100.0;

  @override
  List<Object?> get props => [
        id,
        bookId,
        userId,
        currentPage,
        totalPages,
        progressPercentage,
        readingTimeMinutes,
        lastPosition,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'ReadingProgress(id: $id, bookId: $bookId, progress: ${progressPercentage.toStringAsFixed(1)}%)';
}
