import 'package:equatable/equatable.dart';

import 'author.dart';
import 'category.dart';

/// Book entity representing a book in the library
/// 
/// Contains all book information including metadata, file details,
/// and relationships with authors and categories.
class Book extends Equatable {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? language;
  final String? isbn;
  final DateTime? publicationDate;
  final int? pageCount;
  final String? filePath;
  final int? fileSize;
  final BookFormat format;
  final String? coverUrl;
  final String? coverPath;
  final String? downloadUrl;
  final BookSource source;
  final String? sourceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? downloadedAt;
  final DateTime? lastOpenedAt;
  final List<Author> authors;
  final List<Category> categories;

  const Book({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.language,
    this.isbn,
    this.publicationDate,
    this.pageCount,
    this.filePath,
    this.fileSize,
    required this.format,
    this.coverUrl,
    this.coverPath,
    this.downloadUrl,
    required this.source,
    this.sourceId,
    required this.createdAt,
    required this.updatedAt,
    this.downloadedAt,
    this.lastOpenedAt,
    this.authors = const [],
    this.categories = const [],
  });

  /// Create a copy of this book with updated fields
  Book copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? language,
    String? isbn,
    DateTime? publicationDate,
    int? pageCount,
    String? filePath,
    int? fileSize,
    BookFormat? format,
    String? coverUrl,
    String? coverPath,
    String? downloadUrl,
    BookSource? source,
    String? sourceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? downloadedAt,
    DateTime? lastOpenedAt,
    List<Author>? authors,
    List<Category>? categories,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      language: language ?? this.language,
      isbn: isbn ?? this.isbn,
      publicationDate: publicationDate ?? this.publicationDate,
      pageCount: pageCount ?? this.pageCount,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      format: format ?? this.format,
      coverUrl: coverUrl ?? this.coverUrl,
      coverPath: coverPath ?? this.coverPath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      authors: authors ?? this.authors,
      categories: categories ?? this.categories,
    );
  }

  /// Check if book is downloaded locally
  bool get isDownloaded => filePath != null && downloadedAt != null;

  /// Check if book has cover image
  bool get hasCover => coverUrl != null || coverPath != null;

  /// Get book file size in MB
  double? get fileSizeMB {
    if (fileSize == null) return null;
    return fileSize! / (1024 * 1024);
  }

  /// Get primary author name
  String get primaryAuthorName {
    if (authors.isEmpty) return 'Unknown Author';
    return authors.first.name;
  }

  /// Get all author names as comma-separated string
  String get allAuthorsNames {
    if (authors.isEmpty) return 'Unknown Author';
    return authors.map((author) => author.name).join(', ');
  }

  /// Get primary category name
  String get primaryCategoryName {
    if (categories.isEmpty) return 'Uncategorized';
    return categories.first.name;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        description,
        language,
        isbn,
        publicationDate,
        pageCount,
        filePath,
        fileSize,
        format,
        coverUrl,
        coverPath,
        downloadUrl,
        source,
        sourceId,
        createdAt,
        updatedAt,
        downloadedAt,
        lastOpenedAt,
        authors,
        categories,
      ];

  @override
  String toString() => 'Book(id: $id, title: $title, format: $format)';
}

/// Book format enumeration
enum BookFormat {
  epub('epub'),
  pdf('pdf'),
  txt('txt'),
  mobi('mobi'),
  azw('azw'),
  unknown('unknown');

  const BookFormat(this.value);
  final String value;

  /// Create BookFormat from string value
  static BookFormat fromString(String value) {
    switch (value.toLowerCase()) {
      case 'epub':
        return BookFormat.epub;
      case 'pdf':
        return BookFormat.pdf;
      case 'txt':
        return BookFormat.txt;
      case 'mobi':
        return BookFormat.mobi;
      case 'azw':
        return BookFormat.azw;
      default:
        return BookFormat.unknown;
    }
  }

  /// Get file extension for this format
  String get fileExtension {
    switch (this) {
      case BookFormat.epub:
        return '.epub';
      case BookFormat.pdf:
        return '.pdf';
      case BookFormat.txt:
        return '.txt';
      case BookFormat.mobi:
        return '.mobi';
      case BookFormat.azw:
        return '.azw';
      case BookFormat.unknown:
        return '';
    }
  }

  /// Check if format is readable by the app
  bool get isReadable {
    switch (this) {
      case BookFormat.epub:
      case BookFormat.pdf:
      case BookFormat.txt:
        return true;
      case BookFormat.mobi:
      case BookFormat.azw:
      case BookFormat.unknown:
        return false;
    }
  }
}

/// Book source enumeration
enum BookSource {
  projectGutenberg('project_gutenberg'),
  internetArchive('internet_archive'),
  openLibrary('open_library'),
  doab('doab'),
  local('local'),
  manual('manual'),
  unknown('unknown');

  const BookSource(this.value);
  final String value;

  /// Create BookSource from string value
  static BookSource fromString(String value) {
    switch (value.toLowerCase()) {
      case 'project_gutenberg':
        return BookSource.projectGutenberg;
      case 'internet_archive':
        return BookSource.internetArchive;
      case 'open_library':
        return BookSource.openLibrary;
      case 'doab':
        return BookSource.doab;
      case 'local':
        return BookSource.local;
      case 'manual':
        return BookSource.manual;
      default:
        return BookSource.unknown;
    }
  }

  /// Get display name for the source
  String get displayName {
    switch (this) {
      case BookSource.projectGutenberg:
        return 'Project Gutenberg';
      case BookSource.internetArchive:
        return 'Internet Archive';
      case BookSource.openLibrary:
        return 'Open Library';
      case BookSource.doab:
        return 'DOAB';
      case BookSource.local:
        return 'Local';
      case BookSource.manual:
        return 'Manual';
      case BookSource.unknown:
        return 'Unknown';
    }
  }

  /// Check if source supports search
  bool get supportsSearch {
    switch (this) {
      case BookSource.projectGutenberg:
      case BookSource.internetArchive:
      case BookSource.openLibrary:
      case BookSource.doab:
        return true;
      case BookSource.local:
      case BookSource.manual:
      case BookSource.unknown:
        return false;
    }
  }
}
