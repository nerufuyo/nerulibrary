import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reading_progress.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/entities/reading_statistics.dart';
import '../../domain/services/progress_calculation_service.dart';
import '../../domain/services/reading_time_tracking_service.dart';

/// Provider for progress calculation service
final progressCalculationServiceProvider =
    Provider<ProgressCalculationService>((ref) {
  return ProgressCalculationServiceImpl();
});

/// Provider for reading time tracking service
final readingTimeTrackingServiceProvider =
    Provider<ReadingTimeTrackingService>((ref) {
  return ReadingTimeTrackingServiceImpl();
});

/// State notifier for managing reading progress
class ProgressTrackingNotifier
    extends StateNotifier<AsyncValue<ReadingProgress?>> {
  final ProgressCalculationService _progressService;
  final ReadingTimeTrackingService _timeService;

  ReadingProgress? _currentProgress;
  ReadingSession? _currentSession;

  ProgressTrackingNotifier(
    this._progressService,
    this._timeService,
  ) : super(const AsyncValue.data(null));

  /// Get current progress
  ReadingProgress? get currentProgress => _currentProgress;

  /// Get current reading session
  ReadingSession? get currentSession => _currentSession;

  /// Start a new reading session
  Future<void> startReadingSession({
    required String bookId,
    required String userId,
    required int startPage,
    required double startProgressPercentage,
    required String deviceType,
    required String bookFormat,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();

    final result = await _timeService.startSession(
      bookId: bookId,
      userId: userId,
      startPage: startPage,
      startProgressPercentage: startProgressPercentage,
      deviceType: deviceType,
      bookFormat: bookFormat,
      metadata: metadata,
    );

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (session) {
        _currentSession = session;
        state = AsyncValue.data(_currentProgress);
      },
    );
  }

  /// End the current reading session
  Future<void> endReadingSession({
    required int endPage,
    required double endProgressPercentage,
  }) async {
    if (_currentSession == null) return;

    state = const AsyncValue.loading();

    final result = await _timeService.endSession(
      sessionId: _currentSession!.id,
      endPage: endPage,
      endProgressPercentage: endProgressPercentage,
    );

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (completedSession) {
        _currentSession = null;
        // Update progress from completed session
        if (_currentProgress != null) {
          _updateProgressFromSession(completedSession);
        }
      },
    );
  }

  /// Update reading progress
  Future<void> updateProgress({
    required String bookId,
    required String bookFormat,
    required Map<String, dynamic> positionData,
    required Map<String, dynamic> bookMetadata,
  }) async {
    state = const AsyncValue.loading();

    final result = await _progressService.calculateProgress(
      bookId: bookId,
      bookFormat: bookFormat,
      positionData: positionData,
      bookMetadata: bookMetadata,
    );

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (progress) {
        _currentProgress = progress;
        state = AsyncValue.data(progress);

        // Update current session if active
        if (_currentSession != null) {
          updateSessionProgress(
            currentPage: progress.currentPage,
            progressPercentage: progress.progressPercentage,
          );
        }
      },
    );
  }

  /// Update session progress during reading
  Future<void> updateSessionProgress({
    required int currentPage,
    required double progressPercentage,
  }) async {
    if (_currentSession == null) return;

    final result = await _timeService.updateSessionProgress(
      sessionId: _currentSession!.id,
      currentPage: currentPage,
      progressPercentage: progressPercentage,
    );

    result.fold(
      (failure) => {}, // Log error but don't update state
      (updatedSession) => _currentSession = updatedSession,
    );
  }

  /// Pause current reading session
  Future<void> pauseSession() async {
    if (_currentSession == null) return;

    final result = await _timeService.pauseSession(_currentSession!.id);
    result.fold(
      (failure) => {}, // Log error
      (session) => _currentSession = session,
    );
  }

  /// Resume paused reading session
  Future<void> resumeSession() async {
    if (_currentSession == null) return;

    final result = await _timeService.resumeSession(_currentSession!.id);
    result.fold(
      (failure) => {}, // Log error
      (session) => _currentSession = session,
    );
  }

  /// Load existing progress for a book
  Future<void> loadProgress(String bookId) async {
    // In a real implementation, this would load from database
    // For now, we'll just reset the state
    _currentProgress = null;
    state = const AsyncValue.data(null);
  }

  /// Sync progress across different formats
  Future<void> syncProgressAcrossFormats({
    required String bookId,
    required List<ReadingProgress> progressRecords,
  }) async {
    state = const AsyncValue.loading();

    final result = await _progressService.syncProgressAcrossFormats(
      bookId: bookId,
      progressRecords: progressRecords,
    );

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (syncedRecords) {
        // Update current progress with the latest synced record
        if (syncedRecords.isNotEmpty) {
          final latestProgress = syncedRecords.values
              .reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);
          _currentProgress = latestProgress;
          state = AsyncValue.data(latestProgress);
        }
      },
    );
  }

  /// Calculate estimated reading time remaining
  Future<Duration?> getEstimatedTimeRemaining(
      double averageReadingSpeed) async {
    if (_currentProgress == null) return null;

    final result = await _progressService.calculateEstimatedTimeRemaining(
      progress: _currentProgress!,
      averageReadingSpeed: averageReadingSpeed,
    );

    return result.fold(
      (failure) => null,
      (duration) => duration,
    );
  }

  /// Get reading sessions for a book
  Future<List<ReadingSession>> getSessionsForBook(String bookId) async {
    final result = await _timeService.getSessionsForBook(bookId: bookId);

    return result.fold(
      (failure) => [],
      (sessions) => sessions,
    );
  }

  /// Get total reading time for a book
  Future<Duration> getTotalReadingTime(String bookId) async {
    final result = await _timeService.getTotalReadingTime(bookId);

    return result.fold(
      (failure) => Duration.zero,
      (duration) => duration,
    );
  }

  /// Get reading velocity for current user
  Future<double> getReadingVelocity(String userId) async {
    final result = await _timeService.getReadingVelocity(userId: userId);

    return result.fold(
      (failure) => 0.0,
      (velocity) => velocity,
    );
  }

  /// Update progress from completed session
  void _updateProgressFromSession(ReadingSession session) async {
    if (_currentProgress == null) return;

    final result = await _progressService.updateProgressFromSession(
      session: session,
      currentProgress: _currentProgress!,
    );

    result.fold(
      (failure) => {}, // Log error
      (updatedProgress) {
        _currentProgress = updatedProgress;
        state = AsyncValue.data(updatedProgress);
      },
    );
  }

  /// Reset all progress tracking state
  void reset() {
    _currentProgress = null;
    _currentSession = null;
    state = const AsyncValue.data(null);
  }
}

/// Provider for progress tracking state
final progressTrackingProvider = StateNotifierProvider<ProgressTrackingNotifier,
    AsyncValue<ReadingProgress?>>((ref) {
  final progressService = ref.read(progressCalculationServiceProvider);
  final timeService = ref.read(readingTimeTrackingServiceProvider);

  return ProgressTrackingNotifier(progressService, timeService);
});

/// State notifier for reading statistics
class ReadingStatisticsNotifier
    extends StateNotifier<AsyncValue<ReadingStatistics>> {
  ReadingStatisticsNotifier()
      : super(AsyncValue.data(ReadingStatistics.empty()));

  /// Load statistics for a user
  Future<void> loadStatistics(String userId) async {
    state = const AsyncValue.loading();

    try {
      // In a real implementation, this would load from database
      // For now, create empty statistics
      final statistics = ReadingStatistics.empty();
      state = AsyncValue.data(statistics);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update statistics with new session data
  Future<void> updateWithSession(ReadingSession session) async {
    state.whenData((currentStats) {
      final updatedStats = currentStats.copyWith(
        totalSessions: currentStats.totalSessions + 1,
        totalReadingTime: currentStats.totalReadingTime + session.duration,
        totalPagesRead: currentStats.totalPagesRead + session.pagesRead,
        lastUpdated: DateTime.now(),
      );

      state = AsyncValue.data(updatedStats);
    });
  }

  /// Update daily reading goal
  void updateDailyGoal(int goalMinutes) {
    state.whenData((currentStats) {
      final updatedStats = currentStats.copyWith(
        dailyGoalMinutes: goalMinutes,
        lastUpdated: DateTime.now(),
      );

      state = AsyncValue.data(updatedStats);
    });
  }

  /// Update weekly reading goal
  void updateWeeklyGoal(int goalMinutes) {
    state.whenData((currentStats) {
      final updatedStats = currentStats.copyWith(
        weeklyGoalMinutes: goalMinutes,
        lastUpdated: DateTime.now(),
      );

      state = AsyncValue.data(updatedStats);
    });
  }

  /// Reset statistics
  void reset() {
    state = AsyncValue.data(ReadingStatistics.empty());
  }
}

/// Provider for reading statistics
final readingStatisticsProvider = StateNotifierProvider<
    ReadingStatisticsNotifier, AsyncValue<ReadingStatistics>>((ref) {
  return ReadingStatisticsNotifier();
});

/// Provider for current reading session
final currentSessionProvider = Provider<ReadingSession?>((ref) {
  final progressTracking = ref.watch(progressTrackingProvider.notifier);
  return progressTracking.currentSession;
});

/// Provider for checking if currently reading
final isCurrentlyReadingProvider = Provider<bool>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session != null && session.isActive;
});

/// Provider for current reading progress
final currentProgressProvider = Provider<ReadingProgress?>((ref) {
  final progressState = ref.watch(progressTrackingProvider);
  return progressState.whenData((progress) => progress).value;
});

/// Provider for estimated time remaining
final estimatedTimeRemainingProvider =
    FutureProvider.family<Duration?, String>((ref, bookId) async {
  final progressTracking = ref.read(progressTrackingProvider.notifier);
  final statistics = ref.read(readingStatisticsProvider);

  return statistics.whenData((stats) async {
    if (stats.wordsPerMinute > 0) {
      return await progressTracking
          .getEstimatedTimeRemaining(stats.wordsPerMinute);
    }
    return await progressTracking
        .getEstimatedTimeRemaining(1.5); // Default speed
  }).value;
});

/// Provider for book reading sessions
final bookSessionsProvider =
    FutureProvider.family<List<ReadingSession>, String>((ref, bookId) async {
  final progressTracking = ref.read(progressTrackingProvider.notifier);
  return await progressTracking.getSessionsForBook(bookId);
});

/// Provider for total reading time for a book
final bookTotalTimeProvider =
    FutureProvider.family<Duration, String>((ref, bookId) async {
  final progressTracking = ref.read(progressTrackingProvider.notifier);
  return await progressTracking.getTotalReadingTime(bookId);
});

/// Provider for user reading velocity
final userReadingVelocityProvider =
    FutureProvider.family<double, String>((ref, userId) async {
  final progressTracking = ref.read(progressTrackingProvider.notifier);
  return await progressTracking.getReadingVelocity(userId);
});
