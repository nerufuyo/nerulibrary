import '../../domain/entities/book.dart';

/// Book data model for database mapping
/// 
/// Handles conversion between database records and Book entities
/// with proper serialization and deserialization logic.
class BookModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? language;
  final String? isbn;
  final String? publicationDate;
  final int? pageCount;
  final String? filePath;
  final int? fileSize;
  final String format;
  final String? coverUrl;
  final String? coverPath;
  final String? downloadUrl;
  final String source;
  final String? sourceId;
  final int createdAt;
  final int updatedAt;
  final int? downloadedAt;
  final int? lastOpenedAt;

  const BookModel({
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
  });

  /// Create BookModel from database map
  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      description: map['description'] as String?,
      language: map['language'] as String?,
      isbn: map['isbn'] as String?,
      publicationDate: map['publication_date'] as String?,
      pageCount: map['page_count'] as int?,
      filePath: map['file_path'] as String?,
      fileSize: map['file_size'] as int?,
      format: map['format'] as String,
      coverUrl: map['cover_url'] as String?,
      coverPath: map['cover_path'] as String?,
      downloadUrl: map['download_url'] as String?,
      source: map['source'] as String,
      sourceId: map['source_id'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      downloadedAt: map['downloaded_at'] as int?,
      lastOpenedAt: map['last_opened_at'] as int?,
    );
  }

  /// Convert BookModel to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'language': language,
      'isbn': isbn,
      'publication_date': publicationDate,
      'page_count': pageCount,
      'file_path': filePath,
      'file_size': fileSize,
      'format': format,
      'cover_url': coverUrl,
      'cover_path': coverPath,
      'download_url': downloadUrl,
      'source': source,
      'source_id': sourceId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'downloaded_at': downloadedAt,
      'last_opened_at': lastOpenedAt,
    };
  }

  /// Create BookModel from Book entity
  factory BookModel.fromEntity(Book book) {
    return BookModel(
      id: book.id,
      title: book.title,
      subtitle: book.subtitle,
      description: book.description,
      language: book.language,
      isbn: book.isbn,
      publicationDate: book.publicationDate?.toIso8601String(),
      pageCount: book.pageCount,
      filePath: book.filePath,
      fileSize: book.fileSize,
      format: book.format.value,
      coverUrl: book.coverUrl,
      coverPath: book.coverPath,
      downloadUrl: book.downloadUrl,
      source: book.source.value,
      sourceId: book.sourceId,
      createdAt: book.createdAt.millisecondsSinceEpoch,
      updatedAt: book.updatedAt.millisecondsSinceEpoch,
      downloadedAt: book.downloadedAt?.millisecondsSinceEpoch,
      lastOpenedAt: book.lastOpenedAt?.millisecondsSinceEpoch,
    );
  }

  /// Convert BookModel to Book entity
  Book toEntity() {
    return Book(
      id: id,
      title: title,
      subtitle: subtitle,
      description: description,
      language: language,
      isbn: isbn,
      publicationDate: publicationDate != null 
          ? DateTime.tryParse(publicationDate!) 
          : null,
      pageCount: pageCount,
      filePath: filePath,
      fileSize: fileSize,
      format: BookFormat.fromString(format),
      coverUrl: coverUrl,
      coverPath: coverPath,
      downloadUrl: downloadUrl,
      source: BookSource.fromString(source),
      sourceId: sourceId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      downloadedAt: downloadedAt != null 
          ? DateTime.fromMillisecondsSinceEpoch(downloadedAt!) 
          : null,
      lastOpenedAt: lastOpenedAt != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastOpenedAt!) 
          : null,
      authors: const [], // Will be loaded separately
      categories: const [], // Will be loaded separately
    );
  }

  /// Create copy with updated fields
  BookModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? language,
    String? isbn,
    String? publicationDate,
    int? pageCount,
    String? filePath,
    int? fileSize,
    String? format,
    String? coverUrl,
    String? coverPath,
    String? downloadUrl,
    String? source,
    String? sourceId,
    int? createdAt,
    int? updatedAt,
    int? downloadedAt,
    int? lastOpenedAt,
  }) {
    return BookModel(
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
    );
  }

  @override
  String toString() => 'BookModel(id: $id, title: $title)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
