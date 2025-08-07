import 'package:equatable/equatable.dart';

/// Statistics for reading habits and progress
class ReadingStatistics extends Equatable {
  /// Total reading time across all sessions
  final Duration totalReadingTime;
  
  /// Average reading session duration
  final Duration averageSessionDuration;
  
  /// Total number of pages read
  final int totalPagesRead;
  
  /// Total number of reading sessions
  final int totalSessions;
  
  /// Total number of bookmarks created
  final int totalBookmarks;
  
  /// Total number of highlights created
  final int totalHighlights;
  
  /// Total number of notes created
  final int totalNotes;
  
  /// Reading streak in days
  final int readingStreak;
  
  /// Words per minute (average reading speed)
  final double wordsPerMinute;
  
  /// Books completed
  final int booksCompleted;
  
  /// Current overall reading progress (0.0 to 1.0)
  final double overallProgress;
  
  /// Weekly reading time goal in minutes
  final int? weeklyGoalMinutes;
  
  /// Daily reading time goal in minutes
  final int? dailyGoalMinutes;
  
  /// Most read genre or category
  final String? favoriteGenre;
  
  /// Average time spent per session
  final Map<String, Duration> sessionsByDay;
  
  /// Reading activity by month
  final Map<String, int> monthlyActivity;
  
  /// When statistics were last calculated
  final DateTime lastUpdated;

  const ReadingStatistics({
    required this.totalReadingTime,
    required this.averageSessionDuration,
    required this.totalPagesRead,
    required this.totalSessions,
    required this.totalBookmarks,
    required this.totalHighlights,
    required this.totalNotes,
    required this.readingStreak,
    required this.wordsPerMinute,
    required this.booksCompleted,
    required this.overallProgress,
    required this.lastUpdated,
    this.weeklyGoalMinutes,
    this.dailyGoalMinutes,
    this.favoriteGenre,
    this.sessionsByDay = const {},
    this.monthlyActivity = const {},
  });

  /// Create empty statistics
  factory ReadingStatistics.empty() {
    return ReadingStatistics(
      totalReadingTime: Duration.zero,
      averageSessionDuration: Duration.zero,
      totalPagesRead: 0,
      totalSessions: 0,
      totalBookmarks: 0,
      totalHighlights: 0,
      totalNotes: 0,
      readingStreak: 0,
      wordsPerMinute: 0.0,
      booksCompleted: 0,
      overallProgress: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get daily average reading time
  Duration get dailyAverageTime {
    if (readingStreak <= 0) return Duration.zero;
    return Duration(
      minutes: totalReadingTime.inMinutes ~/ readingStreak,
    );
  }

  /// Get weekly average reading time
  Duration get weeklyAverageTime {
    return Duration(
      minutes: totalReadingTime.inMinutes ~/ 
        ((DateTime.now().difference(lastUpdated).inDays / 7).ceil()),
    );
  }

  /// Check if daily goal is met
  bool get isDailyGoalMet {
    if (dailyGoalMinutes == null) return false;
    return dailyAverageTime.inMinutes >= dailyGoalMinutes!;
  }

  /// Check if weekly goal is met
  bool get isWeeklyGoalMet {
    if (weeklyGoalMinutes == null) return false;
    return weeklyAverageTime.inMinutes >= weeklyGoalMinutes!;
  }

  /// Get reading consistency percentage (0.0 to 1.0)
  double get consistencyScore {
    if (totalSessions <= 0) return 0.0;
    final expectedSessions = DateTime.now().difference(lastUpdated).inDays;
    if (expectedSessions <= 0) return 1.0;
    return (totalSessions / expectedSessions).clamp(0.0, 1.0);
  }

  /// Create a copy with updated values
  ReadingStatistics copyWith({
    Duration? totalReadingTime,
    Duration? averageSessionDuration,
    int? totalPagesRead,
    int? totalSessions,
    int? totalBookmarks,
    int? totalHighlights,
    int? totalNotes,
    int? readingStreak,
    double? wordsPerMinute,
    int? booksCompleted,
    double? overallProgress,
    int? weeklyGoalMinutes,
    int? dailyGoalMinutes,
    String? favoriteGenre,
    Map<String, Duration>? sessionsByDay,
    Map<String, int>? monthlyActivity,
    DateTime? lastUpdated,
  }) {
    return ReadingStatistics(
      totalReadingTime: totalReadingTime ?? this.totalReadingTime,
      averageSessionDuration: averageSessionDuration ?? this.averageSessionDuration,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      totalSessions: totalSessions ?? this.totalSessions,
      totalBookmarks: totalBookmarks ?? this.totalBookmarks,
      totalHighlights: totalHighlights ?? this.totalHighlights,
      totalNotes: totalNotes ?? this.totalNotes,
      readingStreak: readingStreak ?? this.readingStreak,
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
      booksCompleted: booksCompleted ?? this.booksCompleted,
      overallProgress: overallProgress ?? this.overallProgress,
      weeklyGoalMinutes: weeklyGoalMinutes ?? this.weeklyGoalMinutes,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      favoriteGenre: favoriteGenre ?? this.favoriteGenre,
      sessionsByDay: sessionsByDay ?? this.sessionsByDay,
      monthlyActivity: monthlyActivity ?? this.monthlyActivity,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalReadingTime': totalReadingTime.inMilliseconds,
      'averageSessionDuration': averageSessionDuration.inMilliseconds,
      'totalPagesRead': totalPagesRead,
      'totalSessions': totalSessions,
      'totalBookmarks': totalBookmarks,
      'totalHighlights': totalHighlights,
      'totalNotes': totalNotes,
      'readingStreak': readingStreak,
      'wordsPerMinute': wordsPerMinute,
      'booksCompleted': booksCompleted,
      'overallProgress': overallProgress,
      'weeklyGoalMinutes': weeklyGoalMinutes,
      'dailyGoalMinutes': dailyGoalMinutes,
      'favoriteGenre': favoriteGenre,
      'sessionsByDay': sessionsByDay.map((k, v) => MapEntry(k, v.inMilliseconds)),
      'monthlyActivity': monthlyActivity,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ReadingStatistics.fromJson(Map<String, dynamic> json) {
    return ReadingStatistics(
      totalReadingTime: Duration(milliseconds: json['totalReadingTime'] ?? 0),
      averageSessionDuration: Duration(milliseconds: json['averageSessionDuration'] ?? 0),
      totalPagesRead: json['totalPagesRead'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      totalBookmarks: json['totalBookmarks'] ?? 0,
      totalHighlights: json['totalHighlights'] ?? 0,
      totalNotes: json['totalNotes'] ?? 0,
      readingStreak: json['readingStreak'] ?? 0,
      wordsPerMinute: (json['wordsPerMinute'] ?? 0.0).toDouble(),
      booksCompleted: json['booksCompleted'] ?? 0,
      overallProgress: (json['overallProgress'] ?? 0.0).toDouble(),
      weeklyGoalMinutes: json['weeklyGoalMinutes'],
      dailyGoalMinutes: json['dailyGoalMinutes'],
      favoriteGenre: json['favoriteGenre'],
      sessionsByDay: (json['sessionsByDay'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, Duration(milliseconds: v)),
      ) ?? {},
      monthlyActivity: (json['monthlyActivity'] as Map<String, dynamic>?)?.cast<String, int>() ?? {},
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [
        totalReadingTime,
        averageSessionDuration,
        totalPagesRead,
        totalSessions,
        totalBookmarks,
        totalHighlights,
        totalNotes,
        readingStreak,
        wordsPerMinute,
        booksCompleted,
        overallProgress,
        weeklyGoalMinutes,
        dailyGoalMinutes,
        favoriteGenre,
        sessionsByDay,
        monthlyActivity,
        lastUpdated,
      ];

  @override
  String toString() => 'ReadingStatistics(sessions: $totalSessions, '
      'totalTime: $totalReadingTime, streak: $readingStreak days)';
}
