import '../../../../core/errors/failures.dart';

/// Reader-specific failure types
/// 
/// Extends base [Failure] class to provide specific error handling
/// for book reading operations including format-specific errors.

/// Base failure class for all reader-related errors
abstract class ReaderFailure extends Failure {
  const ReaderFailure({required super.message});
}

/// Failure when book file cannot be opened or read
class BookOpenFailure extends ReaderFailure {
  /// Path to the file that failed to open
  final String? filePath;
  
  /// Specific error details
  final String? details;

  const BookOpenFailure({
    required String message,
    this.filePath,
    this.details,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, filePath, details];

  @override
  String toString() => 'BookOpenFailure: $message${filePath != null ? ' (file: $filePath)' : ''}';
}

/// Failure when book format is not supported
class UnsupportedFormatFailure extends ReaderFailure {
  /// File extension of the unsupported format
  final String? fileExtension;
  
  /// List of supported formats
  final List<String>? supportedFormats;

  const UnsupportedFormatFailure({
    required String message,
    this.fileExtension,
    this.supportedFormats,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, fileExtension, supportedFormats];

  @override
  String toString() => 'UnsupportedFormatFailure: $message${fileExtension != null ? ' (extension: $fileExtension)' : ''}';
}

/// Failure related to file operations
class ReaderFileFailure extends ReaderFailure {
  /// Path to the file that caused the failure
  final String? filePath;
  
  /// The operation that failed
  final String operation;
  
  /// Additional error details
  final String? details;

  const ReaderFileFailure({
    required String message,
    required this.operation,
    this.filePath,
    this.details,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, operation, filePath, details];

  @override
  String toString() => 'ReaderFileFailure: $message (operation: $operation)${filePath != null ? ' (file: $filePath)' : ''}';
}

/// Failure when PDF-specific operations fail
class PdfReaderFailure extends ReaderFailure {
  /// Page number where the failure occurred
  final int? pageNumber;
  
  /// Total pages in the document
  final int? totalPages;
  
  /// PDF-specific error code
  final String? errorCode;

  const PdfReaderFailure({
    required String message,
    this.pageNumber,
    this.totalPages,
    this.errorCode,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, pageNumber, totalPages, errorCode];

  @override
  String toString() => 'PdfReaderFailure: $message${pageNumber != null ? ' (page: $pageNumber)' : ''}';
}

/// Failure when EPUB-specific operations fail
class EpubReaderFailure extends ReaderFailure {
  /// Chapter index where the failure occurred
  final int? chapterIndex;
  
  /// Total chapters in the book
  final int? totalChapters;
  
  /// EPUB-specific error details
  final String? epubDetails;

  const EpubReaderFailure({
    required String message,
    this.chapterIndex,
    this.totalChapters,
    this.epubDetails,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, chapterIndex, totalChapters, epubDetails];

  @override
  String toString() => 'EpubReaderFailure: $message${chapterIndex != null ? ' (chapter: $chapterIndex)' : ''}';
}

/// Failure during page navigation
class NavigationFailure extends ReaderFailure {
  /// The page number that was requested
  final int? requestedPage;
  
  /// Total pages available
  final int? totalPages;
  
  /// Direction of navigation (next, previous, goto)
  final String? direction;

  const NavigationFailure({
    required String message,
    this.requestedPage,
    this.totalPages,
    this.direction,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, requestedPage, totalPages, direction];

  @override
  String toString() => 'NavigationFailure: $message${requestedPage != null ? ' (requested: $requestedPage)' : ''}';
}

/// Failure during text search operations
class SearchFailure extends ReaderFailure {
  /// The search query that failed
  final String query;
  
  /// Search scope (page, chapter, entire book)
  final String? scope;
  
  /// Search-specific error details
  final String? searchDetails;

  const SearchFailure({
    required String message,
    required this.query,
    this.scope,
    this.searchDetails,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, query, scope, searchDetails];

  @override
  String toString() => 'SearchFailure: $message (query: "$query")';
}

/// Failure during content extraction
class ContentExtractionFailure extends ReaderFailure {
  /// Type of content that failed to extract
  final String contentType;
  
  /// Location in the document where extraction failed
  final String? sourceLocation;
  
  /// Content-specific error details
  final String? extractionDetails;

  const ContentExtractionFailure({
    required String message,
    required this.contentType,
    this.sourceLocation,
    this.extractionDetails,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, contentType, sourceLocation, extractionDetails];

  @override
  String toString() => 'ContentExtractionFailure: $message (type: $contentType)';
}

/// Failure related to reader settings
class SettingsFailure extends ReaderFailure {
  /// The setting that failed to update
  final String? settingName;
  
  /// The value that was attempted
  final dynamic attemptedValue;

  const SettingsFailure({
    required String message,
    this.settingName,
    this.attemptedValue,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, settingName, attemptedValue];

  @override
  String toString() => 'SettingsFailure: $message${settingName != null ? ' (setting: $settingName)' : ''}';
}

/// Failure when reading progress operations fail
class ProgressFailure extends ReaderFailure {
  /// The operation that failed (save, load, update)
  final String operation;
  
  /// Book ID associated with the progress
  final String? bookId;
  
  /// Progress-specific error details
  final String? progressDetails;

  const ProgressFailure({
    required String message,
    required this.operation,
    this.bookId,
    this.progressDetails,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, operation, bookId, progressDetails];

  @override
  String toString() => 'ProgressFailure: $message (operation: $operation)';
}

/// Failure when memory operations exceed limits
class MemoryFailure extends ReaderFailure {
  /// Operation that caused memory issue
  final String operation;
  
  /// Memory usage in bytes (if available)
  final int? memoryUsage;
  
  /// Memory limit in bytes (if available)
  final int? memoryLimit;

  const MemoryFailure({
    required String message,
    required this.operation,
    this.memoryUsage,
    this.memoryLimit,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, operation, memoryUsage, memoryLimit];

  @override
  String toString() => 'MemoryFailure: $message (operation: $operation)';
}

/// Utility class with factory methods for common reader failures
class ReaderFailures {
  /// Factory method for file not found errors
  static Failure fileNotFound(String filePath) {
    return BookOpenFailure(
      message: 'File not found',
      filePath: filePath,
    );
  }

  /// Factory method for unsupported format errors
  static Failure unsupportedFormat(String extension, List<String> supportedFormats) {
    return UnsupportedFormatFailure(
      message: 'Unsupported file format',
      fileExtension: extension,
      supportedFormats: supportedFormats,
    );
  }

  /// Factory method for page out of range errors
  static Failure pageOutOfRange(int requestedPage, int totalPages) {
    return NavigationFailure(
      message: 'Page number out of range',
      requestedPage: requestedPage,
      totalPages: totalPages,
    );
  }

  /// Factory method for PDF parsing errors
  static Failure pdfParsingFailed(String details) {
    return PdfReaderFailure(
      message: 'Failed to parse PDF document',
      errorCode: 'PARSE_ERROR',
    );
  }

  /// Factory method for PDF rendering errors
  static Failure pdfRenderingFailed(int pageNumber, String details) {
    return PdfReaderFailure(
      message: 'Failed to render PDF page',
      pageNumber: pageNumber,
      errorCode: 'RENDER_ERROR',
    );
  }

  /// Factory method for EPUB parsing errors
  static Failure epubParsingFailed(String details) {
    return EpubReaderFailure(
      message: 'Failed to parse EPUB document',
      epubDetails: details,
    );
  }

  /// Factory method for search timeout errors
  static Failure searchTimeout(String query) {
    return SearchFailure(
      message: 'Search operation timed out',
      query: query,
      searchDetails: 'Operation exceeded time limit',
    );
  }

  /// Factory method for memory limit exceeded errors
  static Failure memoryLimitExceeded(String operation, int memoryUsage) {
    return MemoryFailure(
      message: 'Memory limit exceeded',
      operation: operation,
      memoryUsage: memoryUsage,
    );
  }

  /// Factory method for save progress errors
  static Failure saveProgressFailed(String bookId, String error) {
    return ProgressFailure(
      message: 'Failed to save progress for book $bookId: $error',
      operation: 'save',
      bookId: bookId,
    );
  }

  /// Factory method for load progress errors
  static Failure loadProgressFailed(String bookId, String error) {
    return ProgressFailure(
      message: 'Failed to load progress for book $bookId: $error',
      operation: 'load',
      bookId: bookId,
    );
  }

  /// Factory method for general unexpected errors
  static Failure unexpectedError(String message) {
    return ReaderFileFailure(
      message: 'Unexpected error: $message',
      operation: 'general',
    );
  }
}
