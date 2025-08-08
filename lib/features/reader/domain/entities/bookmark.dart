import 'package:equatable/equatable.dart';

/// Represents a bookmark in the reading system
///
/// Bookmarks allow users to mark specific locations in books
/// for quick navigation and reference.
class Bookmark extends Equatable {
  /// Unique identifier for the bookmark
  final String id;

  /// ID of the book this bookmark belongs to
  final String bookId;

  /// User-friendly name for the bookmark
  final String name;

  /// Type of bookmark (manual, automatic, chapter, highlight)
  final BookmarkType type;

  /// Location information for the bookmark
  final BookmarkLocation location;

  /// Optional description or note for the bookmark
  final String? description;

  /// When the bookmark was created
  final DateTime createdAt;

  /// When the bookmark was last updated
  final DateTime updatedAt;

  /// Whether this bookmark is synchronized with the cloud
  final bool isSynced;

  const Bookmark({
    required this.id,
    required this.bookId,
    required this.name,
    required this.type,
    required this.location,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  /// Creates a copy of this bookmark with updated fields
  Bookmark copyWith({
    String? id,
    String? bookId,
    String? name,
    BookmarkType? type,
    BookmarkLocation? location,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      type: type ?? this.type,
      location: location ?? this.location,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Creates a bookmark from JSON data
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      name: json['name'] as String,
      type: BookmarkType.fromString(json['type'] as String),
      location:
          BookmarkLocation.fromJson(json['location'] as Map<String, dynamic>),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  /// Converts this bookmark to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'name': name,
      'type': type.value,
      'location': location.toJson(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        name,
        type,
        location,
        description,
        createdAt,
        updatedAt,
        isSynced,
      ];
}

/// Types of bookmarks supported by the system
enum BookmarkType {
  /// Manually created by user
  manual('manual'),

  /// Automatically created (e.g., last reading position)
  automatic('automatic'),

  /// Chapter or section marker
  chapter('chapter'),

  /// Highlighted text bookmark
  highlight('highlight');

  const BookmarkType(this.value);

  /// String representation of the bookmark type
  final String value;

  /// Creates a BookmarkType from string value
  static BookmarkType fromString(String value) {
    switch (value) {
      case 'manual':
        return BookmarkType.manual;
      case 'automatic':
        return BookmarkType.automatic;
      case 'chapter':
        return BookmarkType.chapter;
      case 'highlight':
        return BookmarkType.highlight;
      default:
        throw ArgumentError('Unknown bookmark type: $value');
    }
  }
}

/// Location information for a bookmark
class BookmarkLocation extends Equatable {
  /// Page number (for PDF files)
  final int? pageNumber;

  /// Chapter ID or name (for EPUB files)
  final String? chapterId;

  /// Character position in the text
  final int? characterPosition;

  /// Percentage progress through the book (0.0 to 1.0)
  final double? progressPercentage;

  /// Additional location metadata (format-specific)
  final Map<String, dynamic>? metadata;

  const BookmarkLocation({
    this.pageNumber,
    this.chapterId,
    this.characterPosition,
    this.progressPercentage,
    this.metadata,
  });

  /// Creates a copy of this location with updated fields
  BookmarkLocation copyWith({
    int? pageNumber,
    String? chapterId,
    int? characterPosition,
    double? progressPercentage,
    Map<String, dynamic>? metadata,
  }) {
    return BookmarkLocation(
      pageNumber: pageNumber ?? this.pageNumber,
      chapterId: chapterId ?? this.chapterId,
      characterPosition: characterPosition ?? this.characterPosition,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a location from JSON data
  factory BookmarkLocation.fromJson(Map<String, dynamic> json) {
    return BookmarkLocation(
      pageNumber: json['pageNumber'] as int?,
      chapterId: json['chapterId'] as String?,
      characterPosition: json['characterPosition'] as int?,
      progressPercentage: json['progressPercentage'] as double?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts this location to JSON data
  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'chapterId': chapterId,
      'characterPosition': characterPosition,
      'progressPercentage': progressPercentage,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        pageNumber,
        chapterId,
        characterPosition,
        progressPercentage,
        metadata,
      ];
}
