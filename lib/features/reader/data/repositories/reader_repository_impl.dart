import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/reader_entities.dart';
import '../../domain/failures/reader_failures.dart';
import '../../domain/repositories/reader_repository.dart';
import '../../domain/services/reader_service.dart';
import '../services/epub_reader_service_impl.dart';
import '../services/pdf_reader_service_impl.dart';

/// Implementation of reader repository that manages different reader services
/// 
/// This repository acts as a facade for different reader implementations,
/// automatically selecting the appropriate service based on file format.
class ReaderRepositoryImpl implements ReaderRepository {
  /// PDF reader service implementation
  final PdfReaderServiceImpl _pdfReaderService;
  
  /// EPUB reader service implementation  
  final EpubReaderServiceImpl _epubReaderService;
  
  /// Currently active reader service
  ReaderService? _activeService;
  
  /// Current book format
  BookFormat? _currentFormat;

  ReaderRepositoryImpl({
    PdfReaderServiceImpl? pdfReaderService,
    EpubReaderServiceImpl? epubReaderService,
  })  : _pdfReaderService = pdfReaderService ?? PdfReaderServiceImpl(),
        _epubReaderService = epubReaderService ?? EpubReaderServiceImpl();

  @override
  Future<Either<Failure, BookContent>> openBook(
    String filePath,
    BookFormat format,
  ) async {
    try {
      // Select appropriate service based on format
      final service = _getServiceForFormat(format);
      if (service == null) {
        return Left(UnsupportedFormatFailure(
          message: 'No service available for format: ${format.name}',
          fileExtension: format.extension,
        ));
      }

      // Close current book if any
      if (_activeService != null) {
        await _activeService!.closeBook();
      }

      // Open the book with the selected service
      final result = await service.openBook(filePath, format);
      
      result.fold(
        (failure) => null,
        (content) {
          _activeService = service;
          _currentFormat = format;
        },
      );

      return result;
    } catch (e) {
      return Left(ReaderFailures.unexpectedError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> closeBook() async {
    try {
      if (_activeService == null) {
        return const Right(true);
      }

      final result = await _activeService!.closeBook();
      if (result.isRight()) {
        _activeService = null;
        _currentFormat = null;
      }

      return result;
    } catch (e) {
      return Left(ReaderFailures.unexpectedError(e.toString()));
    }
  }

  @override
  Either<Failure, ReadingPosition> getCurrentPosition() {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.getCurrentPosition();
  }

  @override
  Future<Either<Failure, bool>> updatePosition(ReadingPosition position) async {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.updatePosition(position);
  }

  @override
  Either<Failure, ReaderSettings> getSettings() {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.getSettings();
  }

  @override
  Future<Either<Failure, bool>> updateSettings(ReaderSettings settings) async {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.updateSettings(settings);
  }

  @override
  Future<Either<Failure, ReadingPosition>> goToPage(int pageNumber) async {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.goToPage(pageNumber);
  }

  @override
  Future<Either<Failure, ReadingPosition>> nextPage() async {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.nextPage();
  }

  @override
  Future<Either<Failure, ReadingPosition>> previousPage() async {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.previousPage();
  }

  @override
  Future<Either<Failure, List<SearchResult>>> searchText(
    String query, {
    bool caseSensitive = false,
  }) async {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.searchText(query, caseSensitive: caseSensitive);
  }

  @override
  Future<Either<Failure, String>> getPageText(int pageNumber) async {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.getPageText(pageNumber);
  }

  @override
  Future<Either<Failure, List<TableOfContentsEntry>>> getTableOfContents() async {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.getTableOfContents();
  }

  @override
  Either<Failure, double> calculateProgress(ReadingPosition position) {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.calculateProgress(position);
  }

  @override
  Either<Failure, int> estimateRemainingTime(
    ReadingPosition position, {
    int wordsPerMinute = 250,
  }) {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.estimateRemainingTime(position, wordsPerMinute: wordsPerMinute);
  }

  @override
  Future<Either<Failure, bool>> isFormatSupported(String filePath) async {
    try {
      // Try PDF first
      final pdfSupported = await _pdfReaderService.isFormatSupported(filePath);
      if (pdfSupported.isRight() && pdfSupported.getOrElse(() => false)) {
        return const Right(true);
      }

      // Try EPUB
      final epubSupported = await _epubReaderService.isFormatSupported(filePath);
      if (epubSupported.isRight() && epubSupported.getOrElse(() => false)) {
        return const Right(true);
      }

      return const Right(false);
    } catch (e) {
      return Left(ReaderFailures.unexpectedError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookFormat>> detectFormat(String filePath) async {
    try {
      final extension = filePath.toLowerCase();
      
      if (extension.endsWith('.pdf')) {
        return const Right(BookFormat.pdf);
      } else if (extension.endsWith('.epub')) {
        return const Right(BookFormat.epub);
      }

      return Left(UnsupportedFormatFailure(
        message: 'Unable to detect format for file',
        fileExtension: extension.split('.').last,
      ));
    } catch (e) {
      return Left(ReaderFailures.unexpectedError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBookMetadata() async {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.getBookMetadata();
  }

  @override
  Future<Either<Failure, bool>> saveProgress(
    String bookId,
    ReadingPosition position,
  ) async {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.saveProgress(bookId, position);
  }

  @override
  Future<Either<Failure, ReadingPosition>> loadProgress(String bookId) async {
    if (_activeService == null) {
      return Left(BookOpenFailure(message: 'No book is currently open'));
    }
    return _activeService!.loadProgress(bookId);
  }

  @override
  Future<Either<Failure, List<BookFormat>>> getSupportedFormats() async {
    return const Right([BookFormat.pdf, BookFormat.epub]);
  }

  @override
  Stream<ReadingPosition> get positionStream {
    if (_activeService == null) {
      return const Stream.empty();
    }
    return _activeService!.positionStream;
  }

  @override
  Stream<ReaderSettings> get settingsStream {
    if (_activeService == null) {
      return const Stream.empty();
    }
    return _activeService!.settingsStream;
  }

  @override
  Stream<double> get loadingProgressStream {
    if (_activeService == null) {
      return const Stream.empty();
    }
    return _activeService!.loadingProgressStream;
  }

  @override
  BookFormat? get currentFormat => _currentFormat;

  @override
  bool get hasActiveBook => _activeService != null;

  /// Get the appropriate service for the given format
  ReaderService? _getServiceForFormat(BookFormat format) {
    switch (format) {
      case BookFormat.pdf:
        return _pdfReaderService;
      case BookFormat.epub:
        return _epubReaderService;
      case BookFormat.txt:
        // TXT format not yet implemented
        return null;
    }
  }

  /// Dispose all services and cleanup resources
  void dispose() {
    if (kDebugMode) {
      debugPrint('Disposing ReaderRepository');
    }
    
    _pdfReaderService.dispose();
    _epubReaderService.dispose();
    _activeService = null;
    _currentFormat = null;
  }
}
