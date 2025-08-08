import 'dart:async';
import 'package:dartz/dartz.dart';

import '../entities/reading_session.dart';
import '../failures/reader_failures.dart';

/// Service for tracking reading time and managing reading sessions
///
/// Provides functionality to start, pause, resume, and end reading sessions
/// with accurate time tracking and session management.
abstract class ReadingTimeTrackingService {
  /// Start a new reading session
  Future<Either<ReaderFailure, ReadingSession>> startSession({
    required String bookId,
    required String userId,
    required int startPage,
    required double startProgressPercentage,
    required String deviceType,
    required String bookFormat,
    Map<String, dynamic>? metadata,
  });

  /// End the current reading session
  Future<Either<ReaderFailure, ReadingSession>> endSession({
    required String sessionId,
    required int endPage,
    required double endProgressPercentage,
  });

  /// Pause the current reading session
  Future<Either<ReaderFailure, ReadingSession>> pauseSession(String sessionId);

  /// Resume a paused reading session
  Future<Either<ReaderFailure, ReadingSession>> resumeSession(String sessionId);

  /// Get the current active session for a book
  Future<Either<ReaderFailure, ReadingSession?>> getCurrentSession(
      String bookId);

  /// Update session progress during reading
  Future<Either<ReaderFailure, ReadingSession>> updateSessionProgress({
    required String sessionId,
    required int currentPage,
    required double progressPercentage,
  });

  /// Get reading sessions for a specific book
  Future<Either<ReaderFailure, List<ReadingSession>>> getSessionsForBook({
    required String bookId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get reading sessions for a date range
  Future<Either<ReaderFailure, List<ReadingSession>>> getSessionsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  });

  /// Calculate total reading time for a book
  Future<Either<ReaderFailure, Duration>> getTotalReadingTime(String bookId);

  /// Get reading velocity for a user
  Future<Either<ReaderFailure, double>> getReadingVelocity({
    required String userId,
    int daysPeriod = 30,
  });
}

/// Implementation of reading time tracking service
class ReadingTimeTrackingServiceImpl implements ReadingTimeTrackingService {
  final Map<String, ReadingSession> _activeSessions = {};
  final Map<String, Timer> _sessionTimers = {};
  final Map<String, DateTime> _pausedTimes = {};

  /// List to store completed sessions (in real implementation, this would be a database)
  final List<ReadingSession> _completedSessions = [];

  @override
  Future<Either<ReaderFailure, ReadingSession>> startSession({
    required String bookId,
    required String userId,
    required int startPage,
    required double startProgressPercentage,
    required String deviceType,
    required String bookFormat,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if there's already an active session for this book
      final existingSession = await getCurrentSession(bookId);
      existingSession.fold(
        (failure) => null,
        (session) {
          if (session != null) {
            // End the existing session first
            endSession(
              sessionId: session.id,
              endPage: session.startPage,
              endProgressPercentage: session.startProgressPercentage,
            );
          }
        },
      );

      final sessionId = '${bookId}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final session = ReadingSessionBuilder()
          .setId(sessionId)
          .setBookId(bookId)
          .setUserId(userId)
          .setStartTime(now)
          .setStartPage(startPage)
          .setStartProgressPercentage(startProgressPercentage)
          .setDeviceType(deviceType)
          .setBookFormat(bookFormat)
          .setMetadata(metadata)
          .build();

      _activeSessions[bookId] = session;
      _startSessionTimer(sessionId);

      return Right(session);
    } catch (e) {
      return Left(ProgressFailure(
        message: 'Failed to start reading session: ${e.toString()}',
        operation: 'start_session',
        bookId: bookId,
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, ReadingSession>> endSession({
    required String sessionId,
    required int endPage,
    required double endProgressPercentage,
  }) async {
    try {
      final bookId = _getBookIdFromSessionId(sessionId);
      final activeSession = _activeSessions[bookId];

      if (activeSession == null) {
        return Left(ProgressFailure(
          message: 'No active session found with ID: $sessionId',
          operation: 'end_session',
        ));
      }

      final now = DateTime.now();
      final duration = now.difference(activeSession.startTime);
      final pagesRead = endPage - activeSession.startPage;
      final readingSpeed =
          duration.inMinutes > 0 ? pagesRead / duration.inMinutes : 0.0;

      final completedSession = activeSession.copyWith(
        endTime: now,
        endPage: endPage,
        endProgressPercentage: endProgressPercentage,
        pagesRead: pagesRead,
        durationMinutes: duration.inMinutes,
        readingSpeedPagesPerMinute: readingSpeed,
      );

      // Clean up
      _activeSessions.remove(bookId);
      _stopSessionTimer(sessionId);
      _pausedTimes.remove(sessionId);

      // Store completed session
      _completedSessions.add(completedSession);

      return Right(completedSession);
    } catch (e) {
      return Left(ProgressFailure(
        message: 'Failed to end reading session: ${e.toString()}',
        operation: 'end_session',
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, ReadingSession>> pauseSession(
      String sessionId) async {
    try {
      final bookId = _getBookIdFromSessionId(sessionId);
      final activeSession = _activeSessions[bookId];

      if (activeSession == null) {
        return Left(ProgressFailure(
          message: 'No active session found with ID: $sessionId',
          operation: 'pause_session',
        ));
      }

      _pausedTimes[sessionId] = DateTime.now();
      _stopSessionTimer(sessionId);

      return Right(activeSession);
    } catch (e) {
      return Left(ProgressFailure(
        message: 'Failed to pause reading session: ${e.toString()}',
        operation: 'pause_session',
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, ReadingSession>> resumeSession(
      String sessionId) async {
    try {
      final bookId = _getBookIdFromSessionId(sessionId);
      final activeSession = _activeSessions[bookId];

      if (activeSession == null) {
        return Left(ProgressFailure(
          message: 'No active session found with ID: $sessionId',
          operation: 'resume_session',
        ));
      }

      final pausedTime = _pausedTimes[sessionId];
      if (pausedTime != null) {
        // Adjust start time to account for paused duration
        final pausedDuration = DateTime.now().difference(pausedTime);
        final adjustedSession = activeSession.copyWith(
          startTime: activeSession.startTime.add(pausedDuration),
        );

        _activeSessions[bookId] = adjustedSession;
        _pausedTimes.remove(sessionId);
      }

      _startSessionTimer(sessionId);

      return Right(_activeSessions[bookId]!);
    } catch (e) {
      return Left(ProgressFailure(
        message: 'Failed to resume reading session: ${e.toString()}',
        operation: 'resume_session',
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, ReadingSession?>> getCurrentSession(
      String bookId) async {
    try {
      final session = _activeSessions[bookId];
      return Right(session);
    } catch (e) {
      return Left(ProgressFailure(
        message: 'Failed to get current session: ${e.toString()}',
        operation: 'get_current_session',
        bookId: bookId,
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, ReadingSession>> updateSessionProgress({
    required String sessionId,
    required int currentPage,
    required double progressPercentage,
  }) async {
    try {
      final bookId = _getBookIdFromSessionId(sessionId);
      final activeSession = _activeSessions[bookId];

      if (activeSession == null) {
        return Left(ProgressFailure(
          message: 'No active session found with ID: $sessionId',
          operation: 'update_progress',
        ));
      }

      // Update progress in metadata
      final updatedMetadata =
          Map<String, dynamic>.from(activeSession.metadata ?? {});
      updatedMetadata['currentPage'] = currentPage;
      updatedMetadata['progressPercentage'] = progressPercentage;
      updatedMetadata['lastUpdated'] = DateTime.now().toIso8601String();

      final updatedSession = activeSession.copyWith(
        metadata: updatedMetadata,
      );

      _activeSessions[bookId] = updatedSession;

      return Right(updatedSession);
    } catch (e) {
      return Left(ProgressFailure(
        message: 'Failed to update session progress: ${e.toString()}',
        operation: 'update_progress',
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, List<ReadingSession>>> getSessionsForBook({
    required String bookId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var sessions =
          _completedSessions.where((session) => session.bookId == bookId);

      if (startDate != null) {
        sessions =
            sessions.where((session) => session.startTime.isAfter(startDate));
      }

      if (endDate != null) {
        sessions =
            sessions.where((session) => session.startTime.isBefore(endDate));
      }

      return Right(sessions.toList());
    } catch (e) {
      return Left(ProgressFailure(
        message: 'Failed to get sessions for book: ${e.toString()}',
        operation: 'get_sessions_for_book',
        bookId: bookId,
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, List<ReadingSession>>> getSessionsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    try {
      var sessions = _completedSessions.where((session) =>
          session.startTime.isAfter(startDate) &&
          session.startTime.isBefore(endDate));

      if (userId != null) {
        sessions = sessions.where((session) => session.userId == userId);
      }

      return Right(sessions.toList());
    } catch (e) {
      return Left(ProgressFailure(
        message: 'Failed to get sessions for date range: ${e.toString()}',
        operation: 'get_sessions_for_date_range',
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, Duration>> getTotalReadingTime(
      String bookId) async {
    try {
      final sessionsResult = await getSessionsForBook(bookId: bookId);

      return sessionsResult.fold(
        (failure) => Left(failure),
        (sessions) {
          final totalMinutes =
              sessions.fold(0, (sum, session) => sum + session.durationMinutes);
          return Right(Duration(minutes: totalMinutes));
        },
      );
    } catch (e) {
      return Left(ProgressFailure(
        message: 'Failed to calculate total reading time: ${e.toString()}',
        operation: 'get_total_reading_time',
        bookId: bookId,
      ));
    }
  }

  @override
  Future<Either<ReaderFailure, double>> getReadingVelocity({
    required String userId,
    int daysPeriod = 30,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: daysPeriod));

      final sessionsResult = await getSessionsForDateRange(
        startDate: startDate,
        endDate: endDate,
        userId: userId,
      );

      return sessionsResult.fold(
        (failure) => Left(failure),
        (sessions) {
          if (sessions.isEmpty) {
            return const Right(0.0);
          }

          final validSessions = sessions.where((session) =>
              session.durationMinutes > 0 && session.pagesRead > 0);

          if (validSessions.isEmpty) {
            return const Right(0.0);
          }

          final totalPages =
              validSessions.fold(0, (sum, session) => sum + session.pagesRead);
          final totalMinutes = validSessions.fold(
              0, (sum, session) => sum + session.durationMinutes);

          final velocity = totalMinutes > 0 ? totalPages / totalMinutes : 0.0;
          return Right(velocity);
        },
      );
    } catch (e) {
      return Left(ProgressFailure(
        message: 'Failed to calculate reading velocity: ${e.toString()}',
        operation: 'get_reading_velocity',
      ));
    }
  }

  /// Start a timer for the session
  void _startSessionTimer(String sessionId) {
    _sessionTimers[sessionId] = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {
        // Update session duration periodically if needed
        // This could be used for real-time progress updates
      },
    );
  }

  /// Stop the timer for the session
  void _stopSessionTimer(String sessionId) {
    _sessionTimers[sessionId]?.cancel();
    _sessionTimers.remove(sessionId);
  }

  /// Extract book ID from session ID
  String _getBookIdFromSessionId(String sessionId) {
    return sessionId.split('_').first;
  }

  /// Dispose of all resources
  void dispose() {
    for (final timer in _sessionTimers.values) {
      timer.cancel();
    }
    _sessionTimers.clear();
    _activeSessions.clear();
    _pausedTimes.clear();
  }
}
