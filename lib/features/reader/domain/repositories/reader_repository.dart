import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/reader_entities.dart';
import '../services/reader_service.dart';

/// Repository interface for reader functionality
/// 
/// This repository provides a unified interface for all reading operations,
/// abstracting away the specific implementation details of different file formats.
abstract class ReaderRepository {
  /// Open a book file with the specified format
  /// 
  /// Returns [BookContent] with metadata and structure information,
  /// or [Failure] if the operation fails.
  Future<Either<Failure, BookContent>> openBook(
    String filePath,
    BookFormat format,
  );

  /// Close the currently open book
  /// 
  /// Returns [true] if successful, or [Failure] if the operation fails.
  Future<Either<Failure, bool>> closeBook();

  /// Get the current reading position
  /// 
  /// Returns [ReadingPosition] or [Failure] if no book is open.
  Either<Failure, ReadingPosition> getCurrentPosition();

  /// Update the current reading position
  /// 
  /// Returns [true] if successful, or [Failure] if the operation fails.
  Future<Either<Failure, bool>> updatePosition(ReadingPosition position);

  /// Get current reader settings
  /// 
  /// Returns [ReaderSettings] or [Failure] if no book is open.
  Either<Failure, ReaderSettings> getSettings();

  /// Update reader settings
  /// 
  /// Returns [true] if successful, or [Failure] if the operation fails.
  Future<Either<Failure, bool>> updateSettings(ReaderSettings settings);

  /// Navigate to a specific page number
  /// 
  /// Returns updated [ReadingPosition] or [Failure] if navigation fails.
  Future<Either<Failure, ReadingPosition>> goToPage(int pageNumber);

  /// Navigate to the next page
  /// 
  /// Returns updated [ReadingPosition] or [Failure] if at the end or navigation fails.
  Future<Either<Failure, ReadingPosition>> nextPage();

  /// Navigate to the previous page
  /// 
  /// Returns updated [ReadingPosition] or [Failure] if at the beginning or navigation fails.
  Future<Either<Failure, ReadingPosition>> previousPage();

  /// Search for text within the book
  /// 
  /// Returns a list of [SearchResult] or [Failure] if search fails.
  Future<Either<Failure, List<SearchResult>>> searchText(
    String query, {
    bool caseSensitive = false,
  });

  /// Get text content of a specific page
  /// 
  /// Returns plain text content or [Failure] if extraction fails.
  Future<Either<Failure, String>> getPageText(int pageNumber);

  /// Get the table of contents for the book
  /// 
  /// Returns list of [TableOfContentsEntry] or [Failure] if extraction fails.
  Future<Either<Failure, List<TableOfContentsEntry>>> getTableOfContents();

  /// Calculate reading progress as a percentage
  /// 
  /// Returns progress value between 0.0 and 1.0, or [Failure] if calculation fails.
  Either<Failure, double> calculateProgress(ReadingPosition position);

  /// Estimate remaining reading time in minutes
  /// 
  /// Returns estimated time in minutes or [Failure] if calculation fails.
  Either<Failure, int> estimateRemainingTime(
    ReadingPosition position, {
    int wordsPerMinute = 250,
  });

  /// Check if a file format is supported
  /// 
  /// Returns [true] if the format is supported, [false] otherwise.
  Future<Either<Failure, bool>> isFormatSupported(String filePath);

  /// Automatically detect the format of a file
  /// 
  /// Returns [BookFormat] or [Failure] if format cannot be determined.
  Future<Either<Failure, BookFormat>> detectFormat(String filePath);

  /// Get metadata for the currently open book
  /// 
  /// Returns metadata map or [Failure] if no book is open.
  Future<Either<Failure, Map<String, dynamic>>> getBookMetadata();

  /// Save reading progress to persistent storage
  /// 
  /// Returns [true] if successful, or [Failure] if saving fails.
  Future<Either<Failure, bool>> saveProgress(
    String bookId,
    ReadingPosition position,
  );

  /// Load reading progress from persistent storage
  /// 
  /// Returns [ReadingPosition] or [Failure] if loading fails.
  Future<Either<Failure, ReadingPosition>> loadProgress(String bookId);

  /// Get list of supported book formats
  /// 
  /// Returns list of [BookFormat] supported by this repository.
  Future<Either<Failure, List<BookFormat>>> getSupportedFormats();

  /// Stream of reading position updates
  /// 
  /// Emits new [ReadingPosition] whenever the position changes.
  Stream<ReadingPosition> get positionStream;

  /// Stream of reader settings updates
  /// 
  /// Emits new [ReaderSettings] whenever settings change.
  Stream<ReaderSettings> get settingsStream;

  /// Stream of loading progress updates
  /// 
  /// Emits progress values between 0.0 and 1.0 during book loading operations.
  Stream<double> get loadingProgressStream;

  /// Get the current book format
  /// 
  /// Returns [BookFormat] if a book is open, null otherwise.
  BookFormat? get currentFormat;

  /// Check if there is an active book
  /// 
  /// Returns [true] if a book is currently open.
  bool get hasActiveBook;
}
