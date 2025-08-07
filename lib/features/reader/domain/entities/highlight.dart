import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Highlight entity for text highlighting and annotation
/// 
/// Represents highlighted text within a book with color coding,
/// notes, and precise location information for different book formats.
class Highlight extends Equatable {
  final String id;
  final String bookId;
  final String? userId;
  final HighlightLocation location;
  final String selectedText;
  final HighlightColor color;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const Highlight({
    required this.id,
    required this.bookId,
    this.userId,
    required this.location,
    required this.selectedText,
    required this.color,
    this.note,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Create a copy with modified properties
  Highlight copyWith({
    String? id,
    String? bookId,
    String? userId,
    HighlightLocation? location,
    String? selectedText,
    HighlightColor? color,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Highlight(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      selectedText: selectedText ?? this.selectedText,
      color: color ?? this.color,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if highlight has an associated note
  bool get hasNote => note != null && note!.isNotEmpty;

  /// Get display title for the highlight
  String get displayTitle {
    final preview = selectedText.length > 50 
        ? '${selectedText.substring(0, 50)}...'
        : selectedText;
    return preview.replaceAll('\n', ' ');
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'userId': userId,
      'location': location.toJson(),
      'selectedText': selectedText,
      'color': color.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      userId: json['userId'] as String?,
      location: HighlightLocation.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      selectedText: json['selectedText'] as String,
      color: HighlightColor.values.firstWhere(
        (color) => color.name == json['color'],
        orElse: () => HighlightColor.yellow,
      ),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        userId,
        location,
        selectedText,
        color,
        note,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Location information for a highlight within different book formats
class HighlightLocation extends Equatable {
  /// Page number (for PDF)
  final int? pageNumber;
  
  /// Chapter identifier (for EPUB)
  final String? chapterId;
  
  /// Start position in text
  final int startOffset;
  
  /// End position in text
  final int endOffset;
  
  /// Bounding rectangle information for visual overlay
  final List<HighlightRect>? rects;
  
  /// Additional format-specific data
  final Map<String, dynamic>? formatData;

  const HighlightLocation({
    this.pageNumber,
    this.chapterId,
    required this.startOffset,
    required this.endOffset,
    this.rects,
    this.formatData,
  });

  /// Create a copy with modified properties
  HighlightLocation copyWith({
    int? pageNumber,
    String? chapterId,
    int? startOffset,
    int? endOffset,
    List<HighlightRect>? rects,
    Map<String, dynamic>? formatData,
  }) {
    return HighlightLocation(
      pageNumber: pageNumber ?? this.pageNumber,
      chapterId: chapterId ?? this.chapterId,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      rects: rects ?? this.rects,
      formatData: formatData ?? this.formatData,
    );
  }

  /// Get human-readable location description
  String get displayLocation {
    if (pageNumber != null) {
      return 'Page $pageNumber';
    }
    if (chapterId != null) {
      return 'Chapter $chapterId';
    }
    return 'Position $startOffset-$endOffset';
  }

  /// Check if location data is valid
  bool get isValid {
    return startOffset >= 0 && 
           endOffset > startOffset && 
           (pageNumber != null || chapterId != null);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'chapterId': chapterId,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'rects': rects?.map((rect) => rect.toJson()).toList(),
      'formatData': formatData,
    };
  }

  /// Create from JSON
  factory HighlightLocation.fromJson(Map<String, dynamic> json) {
    return HighlightLocation(
      pageNumber: json['pageNumber'] as int?,
      chapterId: json['chapterId'] as String?,
      startOffset: json['startOffset'] as int,
      endOffset: json['endOffset'] as int,
      rects: (json['rects'] as List<dynamic>?)
          ?.map((rect) => HighlightRect.fromJson(rect as Map<String, dynamic>))
          .toList(),
      formatData: json['formatData'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        pageNumber,
        chapterId,
        startOffset,
        endOffset,
        rects,
        formatData,
      ];
}

/// Rectangle information for visual highlight rendering
class HighlightRect extends Equatable {
  final double left;
  final double top;
  final double width;
  final double height;

  const HighlightRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Convert to Flutter Rect
  Rect get rect => Rect.fromLTWH(left, top, width, height);

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }

  /// Create from JSON
  factory HighlightRect.fromJson(Map<String, dynamic> json) {
    return HighlightRect(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [left, top, width, height];
}

/// Available highlight colors with Material Design color mappings
enum HighlightColor {
  yellow,
  green,
  blue,
  red,
  purple,
  orange,
  pink,
  cyan;

  /// Get the Material color for this highlight color
  Color get color {
    switch (this) {
      case HighlightColor.yellow:
        return Colors.yellow.shade300;
      case HighlightColor.green:
        return Colors.green.shade300;
      case HighlightColor.blue:
        return Colors.blue.shade300;
      case HighlightColor.red:
        return Colors.red.shade300;
      case HighlightColor.purple:
        return Colors.purple.shade300;
      case HighlightColor.orange:
        return Colors.orange.shade300;
      case HighlightColor.pink:
        return Colors.pink.shade300;
      case HighlightColor.cyan:
        return Colors.cyan.shade300;
    }
  }

  /// Get a darker variant for borders and accents
  Color get darkColor {
    switch (this) {
      case HighlightColor.yellow:
        return Colors.yellow.shade600;
      case HighlightColor.green:
        return Colors.green.shade600;
      case HighlightColor.blue:
        return Colors.blue.shade600;
      case HighlightColor.red:
        return Colors.red.shade600;
      case HighlightColor.purple:
        return Colors.purple.shade600;
      case HighlightColor.orange:
        return Colors.orange.shade600;
      case HighlightColor.pink:
        return Colors.pink.shade600;
      case HighlightColor.cyan:
        return Colors.cyan.shade600;
    }
  }

  /// Get human-readable name
  String get displayName {
    switch (this) {
      case HighlightColor.yellow:
        return 'Yellow';
      case HighlightColor.green:
        return 'Green';
      case HighlightColor.blue:
        return 'Blue';
      case HighlightColor.red:
        return 'Red';
      case HighlightColor.purple:
        return 'Purple';
      case HighlightColor.orange:
        return 'Orange';
      case HighlightColor.pink:
        return 'Pink';
      case HighlightColor.cyan:
        return 'Cyan';
    }
  }

  /// All available colors for selection UI
  static List<HighlightColor> get allColors => HighlightColor.values;
}
