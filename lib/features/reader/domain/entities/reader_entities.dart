import 'package:equatable/equatable.dart';

/// Enumeration of supported book formats for the reader
enum BookFormat {
  pdf('PDF'),
  epub('EPUB'),
  txt('TXT');

  const BookFormat(this.displayName);
  
  final String displayName;

  /// Get the file extension for this format
  String get extension {
    switch (this) {
      case BookFormat.pdf:
        return '.pdf';
      case BookFormat.epub:
        return '.epub';
      case BookFormat.txt:
        return '.txt';
    }
  }

  /// Create BookFormat from file extension
  static BookFormat? fromExtension(String extension) {
    final cleanExt = extension.toLowerCase();
    switch (cleanExt) {
      case '.pdf':
        return BookFormat.pdf;
      case '.epub':
        return BookFormat.epub;
      case '.txt':
        return BookFormat.txt;
      default:
        return null;
    }
  }

  /// Create BookFormat from MIME type
  static BookFormat? fromMimeType(String mimeType) {
    switch (mimeType.toLowerCase()) {
      case 'application/pdf':
        return BookFormat.pdf;
      case 'application/epub+zip':
        return BookFormat.epub;
      case 'text/plain':
        return BookFormat.txt;
      default:
        return null;
    }
  }
}

/// Reading direction for books
enum ReadingDirection {
  leftToRight('Left to Right'),
  rightToLeft('Right to Left'),
  topToBottom('Top to Bottom');

  const ReadingDirection(this.displayName);
  
  final String displayName;
}

/// Page transition animations
enum PageTransition {
  slide('Slide'),
  fade('Fade'),
  curl('Page Curl'),
  none('None');

  const PageTransition(this.displayName);
  
  final String displayName;
}

/// Reading position within a book
class ReadingPosition extends Equatable {
  /// Current page number (0-based for PDF, chapter-based for EPUB)
  final int page;
  
  /// Current chapter index for EPUB books
  final int chapter;
  
  /// Scroll offset within the current page/chapter
  final double scrollOffset;
  
  /// Reading progress as percentage (0.0 to 1.0)
  final double progressPercentage;
  
  /// Character offset for text-based formats
  final int characterOffset;
  
  /// Last updated timestamp
  final DateTime lastUpdated;

  const ReadingPosition({
    required this.page,
    required this.chapter,
    required this.scrollOffset,
    required this.progressPercentage,
    required this.characterOffset,
    required this.lastUpdated,
  });

  /// Create an initial reading position
  factory ReadingPosition.initial() {
    return ReadingPosition(
      page: 0,
      chapter: 0,
      scrollOffset: 0.0,
      progressPercentage: 0.0,
      characterOffset: 0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a copy with updated values
  ReadingPosition copyWith({
    int? page,
    int? chapter,
    double? scrollOffset,
    double? progressPercentage,
    int? characterOffset,
    DateTime? lastUpdated,
  }) {
    return ReadingPosition(
      page: page ?? this.page,
      chapter: chapter ?? this.chapter,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      characterOffset: characterOffset ?? this.characterOffset,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'chapter': chapter,
      'scrollOffset': scrollOffset,
      'progressPercentage': progressPercentage,
      'characterOffset': characterOffset,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ReadingPosition.fromJson(Map<String, dynamic> json) {
    return ReadingPosition(
      page: json['page'] as int? ?? 0,
      chapter: json['chapter'] as int? ?? 0,
      scrollOffset: (json['scrollOffset'] as num?)?.toDouble() ?? 0.0,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      characterOffset: json['characterOffset'] as int? ?? 0,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        page,
        chapter,
        scrollOffset,
        progressPercentage,
        characterOffset,
        lastUpdated,
      ];
}

/// Reading settings for customizing the reader experience
class ReaderSettings extends Equatable {
  /// Font size multiplier (0.5 to 3.0)
  final double fontSize;
  
  /// Line height multiplier (1.0 to 2.5)
  final double lineHeight;
  
  /// Font family name
  final String fontFamily;
  
  /// Text color (hex string)
  final String textColor;
  
  /// Background color (hex string)
  final String backgroundColor;
  
  /// Reading direction
  final ReadingDirection readingDirection;
  
  /// Page transition animation
  final PageTransition pageTransition;
  
  /// Whether to show page numbers
  final bool showPageNumbers;
  
  /// Whether to show reading progress
  final bool showProgress;
  
  /// Whether to enable full screen mode
  final bool fullScreenMode;
  
  /// Whether to keep screen on while reading
  final bool keepScreenOn;
  
  /// Page margin in pixels
  final double pageMargin;
  
  /// Whether to enable auto-brightness adjustment
  final bool autoBrightness;
  
  /// Manual brightness level (0.0 to 1.0)
  final double brightness;

  const ReaderSettings({
    this.fontSize = 1.0,
    this.lineHeight = 1.4,
    this.fontFamily = 'System',
    this.textColor = '#000000',
    this.backgroundColor = '#FFFFFF',
    this.readingDirection = ReadingDirection.leftToRight,
    this.pageTransition = PageTransition.slide,
    this.showPageNumbers = true,
    this.showProgress = true,
    this.fullScreenMode = false,
    this.keepScreenOn = true,
    this.pageMargin = 16.0,
    this.autoBrightness = false,
    this.brightness = 1.0,
  });

  /// Create default settings
  factory ReaderSettings.defaultSettings() {
    return const ReaderSettings();
  }

  /// Create dark theme settings
  factory ReaderSettings.darkTheme() {
    return const ReaderSettings(
      textColor: '#FFFFFF',
      backgroundColor: '#121212',
      brightness: 0.3,
    );
  }

  /// Create sepia theme settings
  factory ReaderSettings.sepiaTheme() {
    return const ReaderSettings(
      textColor: '#5C4B37',
      backgroundColor: '#F4F1EA',
    );
  }

  /// Create a copy with updated values
  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    String? textColor,
    String? backgroundColor,
    ReadingDirection? readingDirection,
    PageTransition? pageTransition,
    bool? showPageNumbers,
    bool? showProgress,
    bool? fullScreenMode,
    bool? keepScreenOn,
    double? pageMargin,
    bool? autoBrightness,
    double? brightness,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.surfaceColor,
      readingDirection: readingDirection ?? this.readingDirection,
      pageTransition: pageTransition ?? this.pageTransition,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      showProgress: showProgress ?? this.showProgress,
      fullScreenMode: fullScreenMode ?? this.fullScreenMode,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      pageMargin: pageMargin ?? this.pageMargin,
      autoBrightness: autoBrightness ?? this.autoBrightness,
      brightness: brightness ?? this.brightness,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'fontFamily': fontFamily,
      'textColor': textColor,
      'backgroundColor': backgroundColor,
      'readingDirection': readingDirection.name,
      'pageTransition': pageTransition.name,
      'showPageNumbers': showPageNumbers,
      'showProgress': showProgress,
      'fullScreenMode': fullScreenMode,
      'keepScreenOn': keepScreenOn,
      'pageMargin': pageMargin,
      'autoBrightness': autoBrightness,
      'brightness': brightness,
    };
  }

  /// Create from JSON
  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    return ReaderSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 1.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.4,
      fontFamily: json['fontFamily'] as String? ?? 'System',
      textColor: json['textColor'] as String? ?? '#000000',
      backgroundColor: json['backgroundColor'] as String? ?? '#FFFFFF',
      readingDirection: ReadingDirection.values.firstWhere(
        (e) => e.name == json['readingDirection'],
        orElse: () => ReadingDirection.leftToRight,
      ),
      pageTransition: PageTransition.values.firstWhere(
        (e) => e.name == json['pageTransition'],
        orElse: () => PageTransition.slide,
      ),
      showPageNumbers: json['showPageNumbers'] as bool? ?? true,
      showProgress: json['showProgress'] as bool? ?? true,
      fullScreenMode: json['fullScreenMode'] as bool? ?? false,
      keepScreenOn: json['keepScreenOn'] as bool? ?? true,
      pageMargin: (json['pageMargin'] as num?)?.toDouble() ?? 16.0,
      autoBrightness: json['autoBrightness'] as bool? ?? false,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [
        fontSize,
        lineHeight,
        fontFamily,
        textColor,
        backgroundColor,
        readingDirection,
        pageTransition,
        showPageNumbers,
        showProgress,
        fullScreenMode,
        keepScreenOn,
        pageMargin,
        autoBrightness,
        brightness,
      ];
}

/// Book content information for the reader
class BookContent extends Equatable {
  /// Total number of pages/chapters
  final int totalPages;
  
  /// Total character count (for text-based formats)
  final int totalCharacters;
  
  /// Estimated reading time in minutes
  final int estimatedReadingTime;
  
  /// Table of contents entries
  final List<TableOfContentsEntry> tableOfContents;
  
  /// Book metadata
  final Map<String, dynamic> metadata;

  const BookContent({
    required this.totalPages,
    required this.totalCharacters,
    required this.estimatedReadingTime,
    required this.tableOfContents,
    required this.metadata,
  });

  /// Create empty content
  factory BookContent.empty() {
    return const BookContent(
      totalPages: 0,
      totalCharacters: 0,
      estimatedReadingTime: 0,
      tableOfContents: [],
      metadata: {},
    );
  }

  @override
  List<Object?> get props => [
        totalPages,
        totalCharacters,
        estimatedReadingTime,
        tableOfContents,
        metadata,
      ];
}

/// Table of contents entry
class TableOfContentsEntry extends Equatable {
  /// Entry title
  final String title;
  
  /// Page/chapter number
  final int page;
  
  /// Nesting level (0 = chapter, 1 = section, etc.)
  final int level;
  
  /// Child entries (sub-sections)
  final List<TableOfContentsEntry> children;

  const TableOfContentsEntry({
    required this.title,
    required this.page,
    required this.level,
    this.children = const [],
  });

  @override
  List<Object?> get props => [title, page, level, children];
}
