import 'package:equatable/equatable.dart';

/// Represents a single reading session
///
/// Tracks the time spent reading, pages read, and other metrics
/// for a specific reading session of a book.
class ReadingSession extends Equatable {
  /// Unique identifier for this reading session
  final String id;

  /// ID of the book being read
  final String bookId;

  /// User ID who performed this reading session
  final String? userId;

  /// When the reading session started
  final DateTime startTime;

  /// When the reading session ended (null if still active)
  final DateTime? endTime;

  /// Starting page/position when session began
  final int startPage;

  /// Ending page/position when session ended
  final int? endPage;

  /// Starting progress percentage (0.0 to 1.0)
  final double startProgressPercentage;

  /// Ending progress percentage (0.0 to 1.0)
  final double? endProgressPercentage;

  /// Number of pages read during this session
  final int pagesRead;

  /// Total time spent reading in minutes
  final int durationMinutes;

  /// Average reading speed for this session (pages per minute)
  final double readingSpeedPagesPerMinute;

  /// Device type used for reading (mobile, tablet, desktop)
  final String deviceType;

  /// Book format being read (pdf, epub)
  final String bookFormat;

  /// Whether this session was interrupted
  final bool wasInterrupted;

  /// Additional session metadata
  final Map<String, dynamic>? metadata;

  const ReadingSession({
    required this.id,
    required this.bookId,
    this.userId,
    required this.startTime,
    this.endTime,
    required this.startPage,
    this.endPage,
    required this.startProgressPercentage,
    this.endProgressPercentage,
    required this.pagesRead,
    required this.durationMinutes,
    required this.readingSpeedPagesPerMinute,
    required this.deviceType,
    required this.bookFormat,
    this.wasInterrupted = false,
    this.metadata,
  });

  /// Create a copy with updated fields
  ReadingSession copyWith({
    String? id,
    String? bookId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? startPage,
    int? endPage,
    double? startProgressPercentage,
    double? endProgressPercentage,
    int? pagesRead,
    int? durationMinutes,
    double? readingSpeedPagesPerMinute,
    String? deviceType,
    String? bookFormat,
    bool? wasInterrupted,
    Map<String, dynamic>? metadata,
  }) {
    return ReadingSession(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      startProgressPercentage:
          startProgressPercentage ?? this.startProgressPercentage,
      endProgressPercentage:
          endProgressPercentage ?? this.endProgressPercentage,
      pagesRead: pagesRead ?? this.pagesRead,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      readingSpeedPagesPerMinute:
          readingSpeedPagesPerMinute ?? this.readingSpeedPagesPerMinute,
      deviceType: deviceType ?? this.deviceType,
      bookFormat: bookFormat ?? this.bookFormat,
      wasInterrupted: wasInterrupted ?? this.wasInterrupted,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if the session is currently active
  bool get isActive => endTime == null;

  /// Get duration as Duration object
  Duration get duration => Duration(minutes: durationMinutes);

  /// Get progress made during this session
  double get progressMade =>
      (endProgressPercentage ?? startProgressPercentage) -
      startProgressPercentage;

  /// Get session efficiency score (0.0 to 1.0 based on reading speed)
  double get efficiencyScore {
    // Assuming average reading speed is 1-2 pages per minute
    const averageSpeed = 1.5;
    return (readingSpeedPagesPerMinute / averageSpeed).clamp(0.0, 1.0);
  }

  /// Create from JSON
  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      userId: json['userId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      startPage: json['startPage'] as int,
      endPage: json['endPage'] as int?,
      startProgressPercentage: json['startProgressPercentage'] as double,
      endProgressPercentage: json['endProgressPercentage'] as double?,
      pagesRead: json['pagesRead'] as int,
      durationMinutes: json['durationMinutes'] as int,
      readingSpeedPagesPerMinute: json['readingSpeedPagesPerMinute'] as double,
      deviceType: json['deviceType'] as String,
      bookFormat: json['bookFormat'] as String,
      wasInterrupted: json['wasInterrupted'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'startPage': startPage,
      'endPage': endPage,
      'startProgressPercentage': startProgressPercentage,
      'endProgressPercentage': endProgressPercentage,
      'pagesRead': pagesRead,
      'durationMinutes': durationMinutes,
      'readingSpeedPagesPerMinute': readingSpeedPagesPerMinute,
      'deviceType': deviceType,
      'bookFormat': bookFormat,
      'wasInterrupted': wasInterrupted,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        userId,
        startTime,
        endTime,
        startPage,
        endPage,
        startProgressPercentage,
        endProgressPercentage,
        pagesRead,
        durationMinutes,
        readingSpeedPagesPerMinute,
        deviceType,
        bookFormat,
        wasInterrupted,
        metadata,
      ];

  @override
  String toString() => 'ReadingSession(id: $id, book: $bookId, '
      'duration: $durationMinutesmin, pages: $pagesRead)';
}

/// Reading session builder for creating new sessions
class ReadingSessionBuilder {
  String? _id;
  String? _bookId;
  String? _userId;
  DateTime? _startTime;
  int? _startPage;
  double? _startProgressPercentage;
  String? _deviceType;
  String? _bookFormat;
  Map<String, dynamic>? _metadata;

  ReadingSessionBuilder();

  ReadingSessionBuilder setId(String id) {
    _id = id;
    return this;
  }

  ReadingSessionBuilder setBookId(String bookId) {
    _bookId = bookId;
    return this;
  }

  ReadingSessionBuilder setUserId(String? userId) {
    _userId = userId;
    return this;
  }

  ReadingSessionBuilder setStartTime(DateTime startTime) {
    _startTime = startTime;
    return this;
  }

  ReadingSessionBuilder setStartPage(int startPage) {
    _startPage = startPage;
    return this;
  }

  ReadingSessionBuilder setStartProgressPercentage(double progressPercentage) {
    _startProgressPercentage = progressPercentage;
    return this;
  }

  ReadingSessionBuilder setDeviceType(String deviceType) {
    _deviceType = deviceType;
    return this;
  }

  ReadingSessionBuilder setBookFormat(String bookFormat) {
    _bookFormat = bookFormat;
    return this;
  }

  ReadingSessionBuilder setMetadata(Map<String, dynamic>? metadata) {
    _metadata = metadata;
    return this;
  }

  ReadingSession build() {
    if (_id == null ||
        _bookId == null ||
        _startTime == null ||
        _startPage == null ||
        _startProgressPercentage == null ||
        _deviceType == null ||
        _bookFormat == null) {
      throw ArgumentError('Missing required fields for ReadingSession');
    }

    return ReadingSession(
      id: _id!,
      bookId: _bookId!,
      userId: _userId,
      startTime: _startTime!,
      startPage: _startPage!,
      startProgressPercentage: _startProgressPercentage!,
      pagesRead: 0, // Will be updated when session ends
      durationMinutes: 0, // Will be updated when session ends
      readingSpeedPagesPerMinute: 0.0, // Will be calculated when session ends
      deviceType: _deviceType!,
      bookFormat: _bookFormat!,
      metadata: _metadata,
    );
  }
}
