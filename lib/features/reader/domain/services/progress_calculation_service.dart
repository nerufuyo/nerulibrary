import 'package:dartz/dartz.dart';

import '../entities/reading_progress.dart';
import '../entities/reading_session.dart';
import '../failures/reader_failures.dart';

/// Service for calculating reading progress across different book formats
///
/// Provides algorithms for tracking progress in PDF, EPUB, and other formats
/// with accurate position tracking and cross-format synchronization.
abstract class ProgressCalculationService {
  /// Calculate progress based on current position and book metadata
  Future<Either<ReaderFailure, ReadingProgress>> calculateProgress({
    required String bookId,
    required String bookFormat,
    required Map<String, dynamic> positionData,
    required Map<String, dynamic> bookMetadata,
  });

  /// Update progress for a specific reading session
  Future<Either<ReaderFailure, ReadingProgress>> updateProgressFromSession({
    required ReadingSession session,
    required ReadingProgress currentProgress,
  });

  /// Sync progress across different formats of the same book
  Future<Either<ReaderFailure, Map<String, ReadingProgress>>>
      syncProgressAcrossFormats({
    required String bookId,
    required List<ReadingProgress> progressRecords,
  });

  /// Calculate estimated reading time remaining
  Future<Either<ReaderFailure, Duration>> calculateEstimatedTimeRemaining({
    required ReadingProgress progress,
    required double averageReadingSpeed,
  });

  /// Calculate reading velocity (pages per minute)
  double calculateReadingVelocity({
    required List<ReadingSession> recentSessions,
    int maxSessionsToConsider = 10,
  });
}

/// Implementation of progress calculation algorithms
class ProgressCalculationServiceImpl implements ProgressCalculationService {
  /// Default reading speed in pages per minute
  static const double defaultReadingSpeed = 1.5;

  /// Minimum session duration to consider for velocity calculation (minutes)
  static const int minSessionDurationMinutes = 5;

  @override
  Future<Either<ReaderFailure, ReadingProgress>> calculateProgress({
    required String bookId,
    required String bookFormat,
    required Map<String, dynamic> positionData,
    required Map<String, dynamic> bookMetadata,
  }) async {
    try {
      final calculator = _getCalculatorForFormat(bookFormat);
      return await calculator.calculateProgress(
        bookId: bookId,
        positionData: positionData,
        bookMetadata: bookMetadata,
      );
    } catch (e) {
      return Left(ProgressCalculationFailure(
        message: 'Failed to calculate progress: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, ReadingProgress>> updateProgressFromSession({
    required ReadingSession session,
    required ReadingProgress currentProgress,
  }) async {
    try {
      if (session.endTime == null) {
        return Left(ProgressCalculationFailure(
          message: 'Cannot update progress from active session',
        ));
      }

      final updatedProgress = currentProgress.copyWith(
        currentPage: session.endPage ?? currentProgress.currentPage,
        progressPercentage:
            session.endProgressPercentage ?? currentProgress.progressPercentage,
        readingTimeMinutes:
            currentProgress.readingTimeMinutes + session.durationMinutes,
        lastPosition: _createPositionString(session),
        updatedAt: session.endTime!,
      );

      return Right(updatedProgress);
    } catch (e) {
      return Left(ProgressCalculationFailure(
        message: 'Failed to update progress from session: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, Map<String, ReadingProgress>>>
      syncProgressAcrossFormats({
    required String bookId,
    required List<ReadingProgress> progressRecords,
  }) async {
    try {
      if (progressRecords.isEmpty) {
        return const Right({});
      }

      // Find the most recent progress
      final latestProgress = progressRecords
          .reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);

      final syncedRecords = <String, ReadingProgress>{};

      for (final progress in progressRecords) {
        if (progress.id == latestProgress.id) {
          syncedRecords[progress.id] = progress;
          continue;
        }

        // Sync progress based on percentage
        final syncedProgress = progress.copyWith(
          progressPercentage: latestProgress.progressPercentage,
          currentPage: _calculatePageFromPercentage(
            latestProgress.progressPercentage,
            progress.totalPages,
          ),
          readingTimeMinutes: latestProgress.readingTimeMinutes,
          updatedAt: DateTime.now(),
        );

        syncedRecords[progress.id] = syncedProgress;
      }

      return Right(syncedRecords);
    } catch (e) {
      return Left(ProgressSyncFailure(
        message: 'Failed to sync progress across formats: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, Duration>> calculateEstimatedTimeRemaining({
    required ReadingProgress progress,
    required double averageReadingSpeed,
  }) async {
    try {
      final pagesRemaining = progress.pagesRemaining;
      final speedPagesPerMinute =
          averageReadingSpeed > 0 ? averageReadingSpeed : defaultReadingSpeed;

      final minutesRemaining = (pagesRemaining / speedPagesPerMinute).ceil();

      return Right(Duration(minutes: minutesRemaining));
    } catch (e) {
      return Left(ProgressCalculationFailure(
        message:
            'Failed to calculate estimated time remaining: ${e.toString()}',
      ));
    }
  }

  @override
  double calculateReadingVelocity({
    required List<ReadingSession> recentSessions,
    int maxSessionsToConsider = 10,
  }) {
    if (recentSessions.isEmpty) return defaultReadingSpeed;

    // Filter sessions by minimum duration and completion
    final validSessions = recentSessions
        .where((session) =>
            session.endTime != null &&
            session.durationMinutes >= minSessionDurationMinutes &&
            session.pagesRead > 0)
        .take(maxSessionsToConsider)
        .toList();

    if (validSessions.isEmpty) return defaultReadingSpeed;

    // Calculate weighted average based on session duration
    double totalWeightedSpeed = 0.0;
    int totalWeight = 0;

    for (final session in validSessions) {
      final weight = session.durationMinutes;
      totalWeightedSpeed += session.readingSpeedPagesPerMinute * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return defaultReadingSpeed;

    return totalWeightedSpeed / totalWeight;
  }

  /// Get progress calculator based on book format
  _FormatProgressCalculator _getCalculatorForFormat(String format) {
    switch (format.toLowerCase()) {
      case 'pdf':
        return _PdfProgressCalculator();
      case 'epub':
        return _EpubProgressCalculator();
      default:
        return _DefaultProgressCalculator();
    }
  }

  /// Create position string from reading session
  String _createPositionString(ReadingSession session) {
    return '${session.bookFormat}:page_${session.endPage}:progress_${session.endProgressPercentage?.toStringAsFixed(2)}';
  }

  /// Calculate page number from progress percentage
  int _calculatePageFromPercentage(double percentage, int totalPages) {
    return ((percentage / 100.0) * totalPages).round().clamp(0, totalPages);
  }
}

/// Abstract calculator for format-specific progress calculation
abstract class _FormatProgressCalculator {
  Future<Either<ReaderFailure, ReadingProgress>> calculateProgress({
    required String bookId,
    required Map<String, dynamic> positionData,
    required Map<String, dynamic> bookMetadata,
  });
}

/// PDF-specific progress calculator
class _PdfProgressCalculator extends _FormatProgressCalculator {
  @override
  Future<Either<ReaderFailure, ReadingProgress>> calculateProgress({
    required String bookId,
    required Map<String, dynamic> positionData,
    required Map<String, dynamic> bookMetadata,
  }) async {
    try {
      final currentPage = positionData['currentPage'] as int? ?? 0;
      final totalPages = bookMetadata['totalPages'] as int? ?? 1;

      final progressPercentage =
          totalPages > 0 ? (currentPage / totalPages) * 100.0 : 0.0;

      final progress = ReadingProgress(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: bookId,
        currentPage: currentPage,
        totalPages: totalPages,
        progressPercentage: progressPercentage,
        readingTimeMinutes: positionData['readingTimeMinutes'] as int? ?? 0,
        lastPosition: 'pdf:page_$currentPage',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Right(progress);
    } catch (e) {
      return Left(ProgressCalculationFailure(
        message: 'PDF progress calculation failed: ${e.toString()}',
      ));
    }
  }
}

/// EPUB-specific progress calculator
class _EpubProgressCalculator extends _FormatProgressCalculator {
  @override
  Future<Either<ReaderFailure, ReadingProgress>> calculateProgress({
    required String bookId,
    required Map<String, dynamic> positionData,
    required Map<String, dynamic> bookMetadata,
  }) async {
    try {
      final chapterId = positionData['chapterId'] as String? ?? '';
      final chapterProgress = positionData['chapterProgress'] as double? ?? 0.0;
      final totalChapters = bookMetadata['totalChapters'] as int? ?? 1;
      final currentChapter = positionData['currentChapter'] as int? ?? 0;

      // Calculate overall progress based on chapter completion
      final progressPercentage = totalChapters > 0
          ? ((currentChapter - 1 + chapterProgress) / totalChapters) * 100.0
          : 0.0;

      // Estimate pages for EPUB (chapters * average pages per chapter)
      final averagePagesPerChapter =
          bookMetadata['averagePagesPerChapter'] as int? ?? 10;
      final totalPages = totalChapters * averagePagesPerChapter;
      final currentPage = ((currentChapter - 1) * averagePagesPerChapter +
              (chapterProgress * averagePagesPerChapter))
          .round();

      final progress = ReadingProgress(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: bookId,
        currentPage: currentPage,
        totalPages: totalPages,
        progressPercentage: progressPercentage,
        readingTimeMinutes: positionData['readingTimeMinutes'] as int? ?? 0,
        lastPosition:
            'epub:chapter_$chapterId:progress_${chapterProgress.toStringAsFixed(2)}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Right(progress);
    } catch (e) {
      return Left(ProgressCalculationFailure(
        message: 'EPUB progress calculation failed: ${e.toString()}',
      ));
    }
  }
}

/// Default progress calculator for unknown formats
class _DefaultProgressCalculator extends _FormatProgressCalculator {
  @override
  Future<Either<ReaderFailure, ReadingProgress>> calculateProgress({
    required String bookId,
    required Map<String, dynamic> positionData,
    required Map<String, dynamic> bookMetadata,
  }) async {
    try {
      final progressPercentage =
          positionData['progressPercentage'] as double? ?? 0.0;
      final totalPages = bookMetadata['totalPages'] as int? ?? 1;
      final currentPage = ((progressPercentage / 100.0) * totalPages).round();

      final progress = ReadingProgress(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: bookId,
        currentPage: currentPage,
        totalPages: totalPages,
        progressPercentage: progressPercentage,
        readingTimeMinutes: positionData['readingTimeMinutes'] as int? ?? 0,
        lastPosition:
            'unknown:progress_${progressPercentage.toStringAsFixed(2)}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Right(progress);
    } catch (e) {
      return Left(ProgressCalculationFailure(
        message: 'Default progress calculation failed: ${e.toString()}',
      ));
    }
  }
}
