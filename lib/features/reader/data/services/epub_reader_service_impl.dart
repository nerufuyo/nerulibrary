import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:epubx/epubx.dart' as epub;

import '../../../../core/errors/failures.dart';
import '../../domain/entities/reader_entities.dart';
import '../../domain/failures/reader_failures.dart';
import '../../domain/services/reader_service.dart';

/// EPUB reader implementation using epubx package
/// 
/// Provides comprehensive EPUB reading functionality including
/// chapter navigation, text extraction, search, and content rendering.
class EpubReaderServiceImpl implements EpubReaderService {
  /// Current EPUB book instance
  epub.EpubBook? _epubBook;
  
  /// Current reading position
  ReadingPosition _currentPosition = ReadingPosition.initial();
  
  /// Current reader settings
  ReaderSettings _currentSettings = ReaderSettings.defaultSettings();
  
  /// Stream controllers for reactive updates
  final StreamController<ReadingPosition> _positionController = StreamController<ReadingPosition>.broadcast();
  final StreamController<ReaderSettings> _settingsController = StreamController<ReaderSettings>.broadcast();
  final StreamController<double> _loadingController = StreamController<double>.broadcast();
  
  /// List of chapters extracted from EPUB
  final List<EpubChapter> _chapters = [];
  
  /// Table of contents entries
  final List<TableOfContentsEntry> _tableOfContents = [];
  
  /// Whether the EPUB is currently loaded
  bool _isLoaded = false;

  @override
  Future<Either<Failure, BookContent>> openBook(
    String filePath,
    BookFormat format,
  ) async {
    try {
      // Validate format
      if (format != BookFormat.epub) {
        return Left(UnsupportedFormatFailure(
          message: 'Expected EPUB format',
          fileExtension: format.extension,
        ));
      }

      // Check file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return Left(ReaderFailures.fileNotFound(filePath));
      }

      _loadingController.add(0.1);

      // Read EPUB file
      final bytes = await file.readAsBytes();
      _epubBook = await epub.EpubReader.readBook(bytes);

      _loadingController.add(0.4);

      // Extract chapters
      await _extractChapters();

      _loadingController.add(0.6);

      // Extract table of contents
      await _extractTableOfContents();

      _loadingController.add(0.8);

      // Calculate content information
      final totalCharacters = _calculateTotalCharacters();
      final estimatedTime = _estimateReadingTime(totalCharacters);

      // Create book content
      final content = BookContent(
        totalPages: _chapters.length,
        totalCharacters: totalCharacters,
        estimatedReadingTime: estimatedTime,
        tableOfContents: _tableOfContents,
        metadata: _extractMetadata(),
      );

      _isLoaded = true;

      _loadingController.add(1.0);

      return Right(content);
    } catch (e) {
      return Left(ReaderFailures.epubParsingFailed(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> closeBook() async {
    try {
      _epubBook = null;
      _currentPosition = ReadingPosition.initial();
      _chapters.clear();
      _tableOfContents.clear();
      _isLoaded = false;

      return const Right(true);
    } catch (e) {
      return Left(ReaderFileFailure(
        message: 'Failed to close EPUB: $e',
        operation: 'close',
      ));
    }
  }

  @override
  Either<Failure, ReadingPosition> getCurrentPosition() {
    if (!_isLoaded) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return Right(_currentPosition);
  }

  @override
  Future<Either<Failure, bool>> updatePosition(ReadingPosition position) async {
    try {
      if (!_isLoaded) {
        return Left(BookOpenFailure(message: 'No book is currently open'));
      }

      // Validate chapter number
      if (position.chapter < 0 || position.chapter >= _chapters.length) {
        return Left(NavigationFailure(
          message: 'Invalid chapter number',
          requestedPage: position.chapter,
          totalPages: _chapters.length,
        ));
      }

      _currentPosition = position.copyWith(lastUpdated: DateTime.now());
      _positionController.add(_currentPosition);

      return const Right(true);
    } catch (e) {
      return Left(ProgressFailure(
        message: 'Failed to update position: $e',
        operation: 'update',
      ));
    }
  }

  @override
  Either<Failure, ReaderSettings> getSettings() {
    return Right(_currentSettings);
  }

  @override
  Future<Either<Failure, bool>> updateSettings(ReaderSettings settings) async {
    try {
      _currentSettings = settings;
      _settingsController.add(_currentSettings);
      return const Right(true);
    } catch (e) {
      return Left(SettingsFailure(
        message: 'Failed to update settings: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, ReadingPosition>> goToPage(int pageNumber) async {
    // For EPUB, pages correspond to chapters
    return goToChapter(pageNumber);
  }

  @override
  Future<Either<Failure, ReadingPosition>> nextPage() async {
    final currentChapter = _currentPosition.chapter;
    return goToChapter(currentChapter + 1);
  }

  @override
  Future<Either<Failure, ReadingPosition>> previousPage() async {
    final currentChapter = _currentPosition.chapter;
    return goToChapter(currentChapter - 1);
  }

  @override
  Future<Either<Failure, List<SearchResult>>> searchText(
    String query, {
    bool caseSensitive = false,
  }) async {
    try {
      if (!_isLoaded) {
        return Left(BookOpenFailure(message: 'No book is currently open'));
      }

      final results = <SearchResult>[];
      final searchQuery = caseSensitive ? query : query.toLowerCase();

      for (int i = 0; i < _chapters.length; i++) {
        final chapter = _chapters[i];
        final chapterText = caseSensitive 
            ? chapter.htmlContent 
            : chapter.htmlContent.toLowerCase();

        int startIndex = 0;
        while (true) {
          final index = chapterText.indexOf(searchQuery, startIndex);
          if (index == -1) break;

          final result = SearchResult.fromMatch(
            fullText: chapter.htmlContent,
            matchPosition: index,
            pageNumber: i,
            chapterNumber: i,
          );

          results.add(result);
          startIndex = index + searchQuery.length;
        }
      }

      return Right(results);
    } catch (e) {
      return Left(SearchFailure(
        message: 'Search failed: $e',
        query: query,
        scope: 'entire book',
      ));
    }
  }

  @override
  Future<Either<Failure, String>> getPageText(int pageNumber) async {
    try {
      if (!_isLoaded) {
        return Left(BookOpenFailure(message: 'No book is currently open'));
      }

      if (pageNumber < 0 || pageNumber >= _chapters.length) {
        return Left(ReaderFailures.pageOutOfRange(pageNumber, _chapters.length));
      }

      // Strip HTML tags to get plain text
      final htmlContent = _chapters[pageNumber].htmlContent;
      final plainText = _stripHtmlTags(htmlContent);

      return Right(plainText);
    } catch (e) {
      return Left(ContentExtractionFailure(
        message: 'Failed to extract text: $e',
        contentType: 'text',
        sourceLocation: 'chapter $pageNumber',
      ));
    }
  }

  @override
  Future<Either<Failure, List<TableOfContentsEntry>>> getTableOfContents() async {
    try {
      if (!_isLoaded) {
        return Left(BookOpenFailure(message: 'No book is currently open'));
      }

      return Right(_tableOfContents);
    } catch (e) {
      return Left(ContentExtractionFailure(
        message: 'Failed to get table of contents: $e',
        contentType: 'table of contents',
      ));
    }
  }

  @override
  Either<Failure, double> calculateProgress(ReadingPosition position) {
    if (!_isLoaded || _chapters.isEmpty) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }

    final progress = (position.chapter + 1) / _chapters.length;
    return Right(progress.clamp(0.0, 1.0));
  }

  @override
  Either<Failure, int> estimateRemainingTime(
    ReadingPosition position, {
    int wordsPerMinute = 250,
  }) {
    if (!_isLoaded || _chapters.isEmpty) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }

    int remainingWords = 0;
    for (int i = position.chapter + 1; i < _chapters.length; i++) {
      final chapterText = _stripHtmlTags(_chapters[i].htmlContent);
      remainingWords += _countWords(chapterText);
    }

    final remainingMinutes = (remainingWords / wordsPerMinute).ceil();
    return Right(remainingMinutes);
  }

  @override
  Future<Either<Failure, bool>> isFormatSupported(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const Right(false);
      }

      final extension = filePath.toLowerCase();
      return Right(extension.endsWith('.epub'));
    } catch (e) {
      return Left(ReaderFileFailure(
        message: 'Failed to check format: $e',
        filePath: filePath,
        operation: 'validate',
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBookMetadata() async {
    if (!_isLoaded) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return Right(_extractMetadata());
  }

  @override
  Future<Either<Failure, bool>> saveProgress(
    String bookId,
    ReadingPosition position,
  ) async {
    try {
      // This would integrate with the database layer
      return const Right(true);
    } catch (e) {
      return Left(ReaderFailures.saveProgressFailed(bookId, e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReadingPosition>> loadProgress(String bookId) async {
    try {
      // This would integrate with the database layer
      return Right(ReadingPosition.initial());
    } catch (e) {
      return Left(ReaderFailures.loadProgressFailed(bookId, e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getChapterHtml(int chapterIndex) async {
    try {
      if (!_isLoaded) {
        return Left(BookOpenFailure(message: 'No book is currently open'));
      }

      if (chapterIndex < 0 || chapterIndex >= _chapters.length) {
        return Left(EpubReaderFailure(
          message: 'Invalid chapter index',
          chapterIndex: chapterIndex,
        ));
      }

      return Right(_chapters[chapterIndex].htmlContent);
    } catch (e) {
      return Left(ContentExtractionFailure(
        message: 'Failed to get chapter HTML: $e',
        contentType: 'html',
        sourceLocation: 'chapter $chapterIndex',
      ));
    }
  }

  @override
  Future<Either<Failure, List<EpubChapter>>> getChapters() async {
    try {
      if (!_isLoaded) {
        return Left(BookOpenFailure(message: 'No book is currently open'));
      }

      return Right(_chapters);
    } catch (e) {
      return Left(ContentExtractionFailure(
        message: 'Failed to get chapters: $e',
        contentType: 'chapters',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> applyCustomCss(String css) async {
    try {
      if (!_isLoaded) {
        return Left(BookOpenFailure(message: 'No book is currently open'));
      }

      // This would be implemented in the UI layer where HTML is rendered
      return const Right(true);
    } catch (e) {
      return Left(EpubReaderFailure(
        message: 'Failed to apply custom CSS: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, List<int>>> getEmbeddedImage(String imagePath) async {
    try {
      if (!_isLoaded || _epubBook == null) {
        return Left(BookOpenFailure(message: 'No book is currently open'));
      }

      final image = _epubBook!.Content?.Images?[imagePath];
      if (image?.Content != null) {
        return Right(image!.Content!);
      }

      return Left(ContentExtractionFailure(
        message: 'Image not found',
        contentType: 'image',
        sourceLocation: imagePath,
      ));
    } catch (e) {
      return Left(ContentExtractionFailure(
        message: 'Failed to get embedded image: $e',
        contentType: 'image',
        sourceLocation: imagePath,
      ));
    }
  }

  @override
  Future<Either<Failure, ReadingPosition>> goToChapter(int chapterIndex) async {
    try {
      if (!_isLoaded) {
        return Left(BookOpenFailure(message: 'No book is currently open'));
      }

      if (chapterIndex < 0 || chapterIndex >= _chapters.length) {
        return Left(NavigationFailure(
          message: 'Invalid chapter index',
          requestedPage: chapterIndex,
          totalPages: _chapters.length,
          direction: 'goto',
        ));
      }

      final newPosition = _currentPosition.copyWith(
        chapter: chapterIndex,
        page: chapterIndex, // For EPUB, page corresponds to chapter
        progressPercentage: chapterIndex / _chapters.length,
        lastUpdated: DateTime.now(),
      );

      await updatePosition(newPosition);
      return Right(newPosition);
    } catch (e) {
      return Left(NavigationFailure(
        message: 'Failed to navigate to chapter: $e',
        requestedPage: chapterIndex,
        direction: 'goto',
      ));
    }
  }

  @override
  Stream<ReadingPosition> get positionStream => _positionController.stream;

  @override
  Stream<ReaderSettings> get settingsStream => _settingsController.stream;

  @override
  Stream<double> get loadingProgressStream => _loadingController.stream;

  /// Extract chapters from the EPUB book
  Future<void> _extractChapters() async {
    if (_epubBook?.Chapters == null) return;

    _chapters.clear();
    
    for (int i = 0; i < _epubBook!.Chapters!.length; i++) {
      final epubChapter = _epubBook!.Chapters![i];
      
      final chapter = EpubChapter(
        title: epubChapter.Title ?? 'Chapter ${i + 1}',
        htmlContent: epubChapter.HtmlContent ?? '',
        index: i,
        anchor: epubChapter.Anchor ?? '',
        subChapters: [], // Would extract sub-chapters if needed
      );
      
      _chapters.add(chapter);
    }
  }

  /// Extract table of contents from the EPUB
  Future<void> _extractTableOfContents() async {
    _tableOfContents.clear();
    
    // Create basic TOC from chapters since epubx navigation access is complex
    for (int i = 0; i < _chapters.length; i++) {
      _tableOfContents.add(TableOfContentsEntry(
        title: _chapters[i].title,
        page: i,
        level: 0,
      ));
    }
  }

  /// Calculate total character count in the book
  int _calculateTotalCharacters() {
    int totalChars = 0;
    for (final chapter in _chapters) {
      final plainText = _stripHtmlTags(chapter.htmlContent);
      totalChars += plainText.length;
    }
    return totalChars;
  }

  /// Estimate reading time based on character count
  int _estimateReadingTime(int characterCount) {
    const charactersPerMinute = 1250; // ~250 words * 5 chars per word
    return (characterCount / charactersPerMinute).ceil();
  }

  /// Extract metadata from EPUB
  Map<String, dynamic> _extractMetadata() {
    if (_epubBook == null) return {};

    return {
      'title': _epubBook!.Title ?? 'Unknown Title',
      'author': _epubBook!.Author ?? 'Unknown Author',
      'publisher': _epubBook!.AuthorList?.join(', ') ?? '',
      'description': '', // Description property not available in epubx 4.0.0
      'language': 'en', // Language property not available in epubx 4.0.0  
      'identifier': _epubBook!.Schema?.Package?.Metadata?.Identifiers?.first.Id ?? '',
      'format': 'EPUB',
      'chapters': _chapters.length,
      'totalCharacters': _calculateTotalCharacters(),
    };
  }

  /// Remove HTML tags from content
  String _stripHtmlTags(String htmlContent) {
    return htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Count words in text
  int _countWords(String text) {
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  /// Dispose resources
  void dispose() {
    _positionController.close();
    _settingsController.close();
    _loadingController.close();
  }
}
