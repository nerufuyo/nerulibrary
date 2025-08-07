import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/reader_entities.dart';

/// Abstract service interface for book readers
/// 
/// Defines the contract for reading different book formats including
/// PDF, EPUB, and text files. Handles reading position, settings,
/// and content extraction.
abstract class ReaderService {
  /// Opens a book file and prepares it for reading
  /// 
  /// [filePath] - Path to the book file
  /// [format] - Expected book format
  /// Returns [BookContent] with book information or [Failure] on error
  Future<Either<Failure, BookContent>> openBook(
    String filePath,
    BookFormat format,
  );

  /// Closes the currently opened book and releases resources
  Future<Either<Failure, bool>> closeBook();

  /// Gets the current reading position
  Either<Failure, ReadingPosition> getCurrentPosition();

  /// Updates the reading position
  /// 
  /// [position] - New reading position
  /// Returns success status or [Failure] on error
  Future<Either<Failure, bool>> updatePosition(ReadingPosition position);

  /// Gets the current reader settings
  Either<Failure, ReaderSettings> getSettings();

  /// Updates reader settings
  /// 
  /// [settings] - New reader settings
  /// Returns success status or [Failure] on error
  Future<Either<Failure, bool>> updateSettings(ReaderSettings settings);

  /// Navigates to a specific page
  /// 
  /// [pageNumber] - Target page number (0-based)
  /// Returns updated position or [Failure] on error
  Future<Either<Failure, ReadingPosition>> goToPage(int pageNumber);

  /// Navigates to the next page
  /// Returns updated position or [Failure] on error
  Future<Either<Failure, ReadingPosition>> nextPage();

  /// Navigates to the previous page
  /// Returns updated position or [Failure] on error
  Future<Either<Failure, ReadingPosition>> previousPage();

  /// Searches for text within the book
  /// 
  /// [query] - Search query
  /// [caseSensitive] - Whether search should be case sensitive
  /// Returns list of search results or [Failure] on error
  Future<Either<Failure, List<SearchResult>>> searchText(
    String query, {
    bool caseSensitive = false,
  });

  /// Gets text content from a specific page/chapter
  /// 
  /// [pageNumber] - Page number to extract text from
  /// Returns text content or [Failure] on error
  Future<Either<Failure, String>> getPageText(int pageNumber);

  /// Gets the table of contents
  Future<Either<Failure, List<TableOfContentsEntry>>> getTableOfContents();

  /// Calculates reading progress percentage
  /// 
  /// [position] - Current reading position
  /// Returns progress percentage (0.0 to 1.0) or [Failure] on error
  Either<Failure, double> calculateProgress(ReadingPosition position);

  /// Estimates remaining reading time
  /// 
  /// [position] - Current reading position
  /// [wordsPerMinute] - Reading speed in words per minute (default: 250)
  /// Returns estimated time in minutes or [Failure] on error
  Either<Failure, int> estimateRemainingTime(
    ReadingPosition position, {
    int wordsPerMinute = 250,
  });

  /// Validates if the file format is supported
  /// 
  /// [filePath] - Path to the file to validate
  /// Returns validation result or [Failure] on error
  Future<Either<Failure, bool>> isFormatSupported(String filePath);

  /// Gets book metadata (title, author, etc.)
  Future<Either<Failure, Map<String, dynamic>>> getBookMetadata();

  /// Saves reading progress to persistent storage
  /// 
  /// [bookId] - Unique identifier for the book
  /// [position] - Current reading position
  /// Returns success status or [Failure] on error
  Future<Either<Failure, bool>> saveProgress(
    String bookId,
    ReadingPosition position,
  );

  /// Loads reading progress from persistent storage
  /// 
  /// [bookId] - Unique identifier for the book
  /// Returns saved position or [Failure] if not found
  Future<Either<Failure, ReadingPosition>> loadProgress(String bookId);

  /// Stream of reading position updates
  Stream<ReadingPosition> get positionStream;

  /// Stream of reader settings updates
  Stream<ReaderSettings> get settingsStream;

  /// Stream of book loading progress (0.0 to 1.0)
  Stream<double> get loadingProgressStream;
}

/// Search result within a book
class SearchResult {
  /// The text snippet containing the search term
  final String snippet;
  
  /// Page number where the result was found
  final int pageNumber;
  
  /// Chapter number where the result was found
  final int chapterNumber;
  
  /// Character position within the page/chapter
  final int characterPosition;
  
  /// Context before the search term
  final String contextBefore;
  
  /// Context after the search term
  final String contextAfter;

  const SearchResult({
    required this.snippet,
    required this.pageNumber,
    required this.chapterNumber,
    required this.characterPosition,
    required this.contextBefore,
    required this.contextAfter,
  });

  /// Create from text match
  factory SearchResult.fromMatch({
    required String fullText,
    required int matchPosition,
    required int pageNumber,
    required int chapterNumber,
    int contextLength = 50,
  }) {
    final startContext = (matchPosition - contextLength).clamp(0, fullText.length);
    final endContext = (matchPosition + contextLength).clamp(0, fullText.length);
    
    return SearchResult(
      snippet: fullText.substring(startContext, endContext),
      pageNumber: pageNumber,
      chapterNumber: chapterNumber,
      characterPosition: matchPosition,
      contextBefore: fullText.substring(startContext, matchPosition),
      contextAfter: fullText.substring(matchPosition, endContext),
    );
  }
}

/// PDF-specific reader service interface
abstract class PdfReaderService extends ReaderService {
  /// Gets the PDF page as an image for rendering
  /// 
  /// [pageNumber] - Page number to render (0-based)
  /// [quality] - Rendering quality (1.0 = original, 2.0 = 2x resolution)
  /// Returns image data or [Failure] on error
  Future<Either<Failure, List<int>>> renderPageAsImage(
    int pageNumber, {
    double quality = 1.0,
  });

  /// Gets PDF page dimensions
  /// 
  /// [pageNumber] - Page number to get dimensions for
  /// Returns page size or [Failure] on error
  Future<Either<Failure, PageSize>> getPageSize(int pageNumber);

  /// Zooms to a specific area of the page
  /// 
  /// [pageNumber] - Target page number
  /// [zoomLevel] - Zoom factor (1.0 = normal, 2.0 = 2x zoom)
  /// [centerX] - X coordinate to center zoom on (0.0 to 1.0)
  /// [centerY] - Y coordinate to center zoom on (0.0 to 1.0)
  /// Returns success status or [Failure] on error
  Future<Either<Failure, bool>> zoomToArea(
    int pageNumber,
    double zoomLevel,
    double centerX,
    double centerY,
  );
}

/// EPUB-specific reader service interface
abstract class EpubReaderService extends ReaderService {
  /// Gets the HTML content of a chapter
  /// 
  /// [chapterIndex] - Chapter index to get content for
  /// Returns HTML content or [Failure] on error
  Future<Either<Failure, String>> getChapterHtml(int chapterIndex);

  /// Gets the list of chapters
  Future<Either<Failure, List<EpubChapter>>> getChapters();

  /// Applies custom CSS styling to the content
  /// 
  /// [css] - CSS string to apply
  /// Returns success status or [Failure] on error
  Future<Either<Failure, bool>> applyCustomCss(String css);

  /// Gets embedded images from the EPUB
  /// 
  /// [imagePath] - Path to the image within the EPUB
  /// Returns image data or [Failure] on error
  Future<Either<Failure, List<int>>> getEmbeddedImage(String imagePath);

  /// Navigates to a specific chapter
  /// 
  /// [chapterIndex] - Target chapter index
  /// Returns updated position or [Failure] on error
  Future<Either<Failure, ReadingPosition>> goToChapter(int chapterIndex);
}

/// Page size information for PDF pages
class PageSize {
  final double width;
  final double height;
  final double aspectRatio;

  const PageSize({
    required this.width,
    required this.height,
  }) : aspectRatio = width / height;

  /// Create from dimensions
  factory PageSize.fromDimensions(double width, double height) {
    return PageSize(width: width, height: height);
  }
}

/// EPUB chapter information
class EpubChapter {
  final String title;
  final String htmlContent;
  final int index;
  final String anchor;
  final List<EpubChapter> subChapters;

  const EpubChapter({
    required this.title,
    required this.htmlContent,
    required this.index,
    required this.anchor,
    this.subChapters = const [],
  });
}
