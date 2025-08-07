import 'package:equatable/equatable.dart';

/// Reading position entity for tracking user's progress through books
/// 
/// Maintains accurate position tracking across different book formats
/// with support for offline sync and cross-session persistence.
class ReadingPosition extends Equatable {
  final String id;
  final String bookId;
  final String? userId;
  final PositionLocation location;
  final double progressPercentage;
  final Duration readingTime;
  final DateTime lastReadAt;
  final bool isFinished;
  final Map<String, dynamic>? metadata;

  const ReadingPosition({
    required this.id,
    required this.bookId,
    this.userId,
    required this.location,
    required this.progressPercentage,
    required this.readingTime,
    required this.lastReadAt,
    this.isFinished = false,
    this.metadata,
  });

  /// Create a copy with modified properties
  ReadingPosition copyWith({
    String? id,
    String? bookId,
    String? userId,
    PositionLocation? location,
    double? progressPercentage,
    Duration? readingTime,
    DateTime? lastReadAt,
    bool? isFinished,
    Map<String, dynamic>? metadata,
  }) {
    return ReadingPosition(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      readingTime: readingTime ?? this.readingTime,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isFinished: isFinished ?? this.isFinished,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if this position represents the start of the book
  bool get isAtStart => progressPercentage <= 0.01;

  /// Check if this position represents the end of the book
  bool get isAtEnd => progressPercentage >= 0.99 || isFinished;

  /// Get human-readable progress description
  String get progressDescription {
    if (isFinished) return 'Finished';
    if (isAtStart) return 'Not started';
    if (isAtEnd) return 'Nearly finished';
    return '${(progressPercentage * 100).toStringAsFixed(1)}% complete';
  }

  /// Get human-readable time description
  String get timeDescription {
    final hours = readingTime.inHours;
    final minutes = readingTime.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '< 1m';
    }
  }

  /// Calculate estimated time remaining based on reading speed
  Duration estimatedTimeRemaining({Duration? averageReadingSpeed}) {
    if (isFinished || progressPercentage >= 1.0) {
      return Duration.zero;
    }

    final speed = averageReadingSpeed ?? const Duration(minutes: 2); // 2 min per 1%
    final remainingPercentage = 1.0 - progressPercentage;
    final remainingMinutes = (remainingPercentage * speed.inMinutes).round();
    
    return Duration(minutes: remainingMinutes);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'userId': userId,
      'location': location.toJson(),
      'progressPercentage': progressPercentage,
      'readingTimeMinutes': readingTime.inMinutes,
      'lastReadAt': lastReadAt.toIso8601String(),
      'isFinished': isFinished,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory ReadingPosition.fromJson(Map<String, dynamic> json) {
    return ReadingPosition(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      userId: json['userId'] as String?,
      location: PositionLocation.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      readingTime: Duration(minutes: json['readingTimeMinutes'] as int),
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
      isFinished: json['isFinished'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        userId,
        location,
        progressPercentage,
        readingTime,
        lastReadAt,
        isFinished,
        metadata,
      ];
}

/// Location information for reading position tracking
class PositionLocation extends Equatable {
  /// Page number (for PDF)
  final int? pageNumber;
  
  /// Total pages (for progress calculation)
  final int? totalPages;
  
  /// Chapter identifier (for EPUB)
  final String? chapterId;
  
  /// Position within chapter (for EPUB)
  final double? chapterProgress;
  
  /// Character offset in the text
  final int? characterOffset;
  
  /// Scroll position within the current view
  final double? scrollPosition;
  
  /// Additional format-specific position data
  final Map<String, dynamic>? formatData;

  const PositionLocation({
    this.pageNumber,
    this.totalPages,
    this.chapterId,
    this.chapterProgress,
    this.characterOffset,
    this.scrollPosition,
    this.formatData,
  });

  /// Create a copy with modified properties
  PositionLocation copyWith({
    int? pageNumber,
    int? totalPages,
    String? chapterId,
    double? chapterProgress,
    int? characterOffset,
    double? scrollPosition,
    Map<String, dynamic>? formatData,
  }) {
    return PositionLocation(
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      chapterId: chapterId ?? this.chapterId,
      chapterProgress: chapterProgress ?? this.chapterProgress,
      characterOffset: characterOffset ?? this.characterOffset,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      formatData: formatData ?? this.formatData,
    );
  }

  /// Calculate progress percentage for PDF
  double? get pdfProgress {
    if (pageNumber != null && totalPages != null && totalPages! > 0) {
      return pageNumber! / totalPages!;
    }
    return null;
  }

  /// Get human-readable location description
  String get displayLocation {
    if (pageNumber != null) {
      if (totalPages != null) {
        return 'Page $pageNumber of $totalPages';
      }
      return 'Page $pageNumber';
    }
    if (chapterId != null) {
      if (chapterProgress != null) {
        final percent = (chapterProgress! * 100).toStringAsFixed(1);
        return 'Chapter $chapterId ($percent%)';
      }
      return 'Chapter $chapterId';
    }
    if (characterOffset != null) {
      return 'Position $characterOffset';
    }
    return 'Unknown position';
  }

  /// Check if location data is valid
  bool get isValid {
    return pageNumber != null || 
           chapterId != null || 
           characterOffset != null;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'totalPages': totalPages,
      'chapterId': chapterId,
      'chapterProgress': chapterProgress,
      'characterOffset': characterOffset,
      'scrollPosition': scrollPosition,
      'formatData': formatData,
    };
  }

  /// Create from JSON
  factory PositionLocation.fromJson(Map<String, dynamic> json) {
    return PositionLocation(
      pageNumber: json['pageNumber'] as int?,
      totalPages: json['totalPages'] as int?,
      chapterId: json['chapterId'] as String?,
      chapterProgress: (json['chapterProgress'] as num?)?.toDouble(),
      characterOffset: json['characterOffset'] as int?,
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble(),
      formatData: json['formatData'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        pageNumber,
        totalPages,
        chapterId,
        chapterProgress,
        characterOffset,
        scrollPosition,
        formatData,
      ];
}

/// Reading session entity for tracking individual reading sessions
class ReadingSession extends Equatable {
  final String id;
  final String bookId;
  final String? userId;
  final DateTime startTime;
  final DateTime? endTime;
  final PositionLocation startLocation;
  final PositionLocation? endLocation;
  final Duration duration;
  final int pagesRead;
  final Map<String, dynamic>? metadata;

  const ReadingSession({
    required this.id,
    required this.bookId,
    this.userId,
    required this.startTime,
    this.endTime,
    required this.startLocation,
    this.endLocation,
    required this.duration,
    required this.pagesRead,
    this.metadata,
  });

  /// Check if session is currently active
  bool get isActive => endTime == null;

  /// Get words read estimate (rough calculation)
  int get estimatedWordsRead {
    // Rough estimate: 250 words per page
    return pagesRead * 250;
  }

  /// Get reading speed in words per minute
  double get wordsPerMinute {
    if (duration.inMinutes == 0) return 0.0;
    return estimatedWordsRead / duration.inMinutes;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation?.toJson(),
      'durationMinutes': duration.inMinutes,
      'pagesRead': pagesRead,
      'metadata': metadata,
    };
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
      startLocation: PositionLocation.fromJson(
        json['startLocation'] as Map<String, dynamic>,
      ),
      endLocation: json['endLocation'] != null
          ? PositionLocation.fromJson(
              json['endLocation'] as Map<String, dynamic>,
            )
          : null,
      duration: Duration(minutes: json['durationMinutes'] as int),
      pagesRead: json['pagesRead'] as int,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        userId,
        startTime,
        endTime,
        startLocation,
        endLocation,
        duration,
        pagesRead,
        metadata,
      ];
}
