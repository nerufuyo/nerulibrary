/// Represents the result of a book search operation
class SearchResult {
  final List<BookSearchItem> books;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final String query;
  final String apiProvider;
  final DateTime searchTime;

  const SearchResult({
    required this.books,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.query,
    required this.apiProvider,
    required this.searchTime,
  });

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
  bool get isEmpty => books.isEmpty;
  bool get isNotEmpty => books.isNotEmpty;

  SearchResult copyWith({
    List<BookSearchItem>? books,
    int? totalCount,
    int? currentPage,
    int? totalPages,
    String? query,
    String? apiProvider,
    DateTime? searchTime,
  }) {
    return SearchResult(
      books: books ?? this.books,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      query: query ?? this.query,
      apiProvider: apiProvider ?? this.apiProvider,
      searchTime: searchTime ?? this.searchTime,
    );
  }

  @override
  String toString() {
    return 'SearchResult(books: ${books.length}, totalCount: $totalCount, currentPage: $currentPage, provider: $apiProvider)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult &&
        other.books == books &&
        other.totalCount == totalCount &&
        other.currentPage == currentPage &&
        other.totalPages == totalPages &&
        other.query == query &&
        other.apiProvider == apiProvider;
  }

  @override
  int get hashCode {
    return Object.hash(
      books,
      totalCount,
      currentPage,
      totalPages,
      query,
      apiProvider,
    );
  }
}

/// Represents a book item in search results
class BookSearchItem {
  final String id;
  final String title;
  final List<String> authors;
  final String? description;
  final String? language;
  final List<String> subjects;
  final DateTime? publishDate;
  final String? coverUrl;
  final List<BookFormat> availableFormats;
  final int? downloadCount;
  final double? rating;
  final String apiProvider;
  final Map<String, dynamic> metadata;

  const BookSearchItem({
    required this.id,
    required this.title,
    required this.authors,
    this.description,
    this.language,
    required this.subjects,
    this.publishDate,
    this.coverUrl,
    required this.availableFormats,
    this.downloadCount,
    this.rating,
    required this.apiProvider,
    required this.metadata,
  });

  bool get hasEpub => availableFormats.contains(BookFormat.epub);
  bool get hasPdf => availableFormats.contains(BookFormat.pdf);
  bool get hasText => availableFormats.contains(BookFormat.text);
  bool get hasDescription => description != null && description!.isNotEmpty;
  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  String get primaryAuthor =>
      authors.isNotEmpty ? authors.first : 'Unknown Author';
  String get authorsString => authors.join(', ');

  BookSearchItem copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? description,
    String? language,
    List<String>? subjects,
    DateTime? publishDate,
    String? coverUrl,
    List<BookFormat>? availableFormats,
    int? downloadCount,
    double? rating,
    String? apiProvider,
    Map<String, dynamic>? metadata,
  }) {
    return BookSearchItem(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      description: description ?? this.description,
      language: language ?? this.language,
      subjects: subjects ?? this.subjects,
      publishDate: publishDate ?? this.publishDate,
      coverUrl: coverUrl ?? this.coverUrl,
      availableFormats: availableFormats ?? this.availableFormats,
      downloadCount: downloadCount ?? this.downloadCount,
      rating: rating ?? this.rating,
      apiProvider: apiProvider ?? this.apiProvider,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'BookSearchItem(id: $id, title: $title, authors: $authorsString, provider: $apiProvider)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookSearchItem &&
        other.id == id &&
        other.title == title &&
        other.apiProvider == apiProvider;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, apiProvider);
  }
}

/// Represents detailed information about a book
class BookDetail {
  final String id;
  final String title;
  final List<BookAuthor> authors;
  final String? description;
  final String? fullDescription;
  final String? language;
  final List<String> subjects;
  final List<String> genres;
  final DateTime? publishDate;
  final String? publisher;
  final String? isbn;
  final List<String> coverUrls;
  final List<BookFormat> availableFormats;
  final Map<BookFormat, String> downloadUrls;
  final int? pageCount;
  final int? downloadCount;
  final double? rating;
  final int? ratingCount;
  final String apiProvider;
  final Map<String, dynamic> metadata;
  final DateTime fetchedAt;

  const BookDetail({
    required this.id,
    required this.title,
    required this.authors,
    this.description,
    this.fullDescription,
    this.language,
    required this.subjects,
    required this.genres,
    this.publishDate,
    this.publisher,
    this.isbn,
    required this.coverUrls,
    required this.availableFormats,
    required this.downloadUrls,
    this.pageCount,
    this.downloadCount,
    this.rating,
    this.ratingCount,
    required this.apiProvider,
    required this.metadata,
    required this.fetchedAt,
  });

  bool get hasEpub => availableFormats.contains(BookFormat.epub);
  bool get hasPdf => availableFormats.contains(BookFormat.pdf);
  bool get hasText => availableFormats.contains(BookFormat.text);
  bool get hasDescription => description != null && description!.isNotEmpty;
  bool get hasFullDescription =>
      fullDescription != null && fullDescription!.isNotEmpty;
  bool get hasCover => coverUrls.isNotEmpty;
  bool get hasRating => rating != null && rating! > 0;

  String get primaryAuthor =>
      authors.isNotEmpty ? authors.first.name : 'Unknown Author';
  String get authorsString => authors.map((a) => a.name).join(', ');
  String get primaryCoverUrl => coverUrls.isNotEmpty ? coverUrls.first : '';
  String get effectiveDescription => fullDescription ?? description ?? '';

  String? getDownloadUrl(BookFormat format) => downloadUrls[format];

  BookDetail copyWith({
    String? id,
    String? title,
    List<BookAuthor>? authors,
    String? description,
    String? fullDescription,
    String? language,
    List<String>? subjects,
    List<String>? genres,
    DateTime? publishDate,
    String? publisher,
    String? isbn,
    List<String>? coverUrls,
    List<BookFormat>? availableFormats,
    Map<BookFormat, String>? downloadUrls,
    int? pageCount,
    int? downloadCount,
    double? rating,
    int? ratingCount,
    String? apiProvider,
    Map<String, dynamic>? metadata,
    DateTime? fetchedAt,
  }) {
    return BookDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      description: description ?? this.description,
      fullDescription: fullDescription ?? this.fullDescription,
      language: language ?? this.language,
      subjects: subjects ?? this.subjects,
      genres: genres ?? this.genres,
      publishDate: publishDate ?? this.publishDate,
      publisher: publisher ?? this.publisher,
      isbn: isbn ?? this.isbn,
      coverUrls: coverUrls ?? this.coverUrls,
      availableFormats: availableFormats ?? this.availableFormats,
      downloadUrls: downloadUrls ?? this.downloadUrls,
      pageCount: pageCount ?? this.pageCount,
      downloadCount: downloadCount ?? this.downloadCount,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      apiProvider: apiProvider ?? this.apiProvider,
      metadata: metadata ?? this.metadata,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  String toString() {
    return 'BookDetail(id: $id, title: $title, authors: $authorsString, provider: $apiProvider)';
  }
}

/// Represents download information for a book
class DownloadInfo {
  final String bookId;
  final BookFormat format;
  final String downloadUrl;
  final String? filename;
  final int? fileSize;
  final String? mimeType;
  final DateTime? expiresAt;
  final Map<String, String> headers;
  final String apiProvider;

  const DownloadInfo({
    required this.bookId,
    required this.format,
    required this.downloadUrl,
    this.filename,
    this.fileSize,
    this.mimeType,
    this.expiresAt,
    required this.headers,
    required this.apiProvider,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get hasFileSize => fileSize != null && fileSize! > 0;
  String get fileSizeFormatted =>
      hasFileSize ? _formatFileSize(fileSize!) : 'Unknown size';

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  DownloadInfo copyWith({
    String? bookId,
    BookFormat? format,
    String? downloadUrl,
    String? filename,
    int? fileSize,
    String? mimeType,
    DateTime? expiresAt,
    Map<String, String>? headers,
    String? apiProvider,
  }) {
    return DownloadInfo(
      bookId: bookId ?? this.bookId,
      format: format ?? this.format,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      filename: filename ?? this.filename,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      expiresAt: expiresAt ?? this.expiresAt,
      headers: headers ?? this.headers,
      apiProvider: apiProvider ?? this.apiProvider,
    );
  }

  @override
  String toString() {
    return 'DownloadInfo(bookId: $bookId, format: $format, size: $fileSizeFormatted, provider: $apiProvider)';
  }
}

/// Represents API status information
class ApiStatus {
  final String provider;
  final bool isAvailable;
  final Duration responseTime;
  final String? errorMessage;
  final int? rateLimitRemaining;
  final Duration? rateLimitReset;
  final String version;
  final DateTime checkedAt;

  const ApiStatus({
    required this.provider,
    required this.isAvailable,
    required this.responseTime,
    this.errorMessage,
    this.rateLimitRemaining,
    this.rateLimitReset,
    required this.version,
    required this.checkedAt,
  });

  bool get hasRateLimit => rateLimitRemaining != null;
  bool get isRateLimited => hasRateLimit && rateLimitRemaining! <= 0;
  bool get isFast => responseTime.inMilliseconds < 1000;
  bool get isSlow => responseTime.inMilliseconds > 5000;

  ApiStatus copyWith({
    String? provider,
    bool? isAvailable,
    Duration? responseTime,
    String? errorMessage,
    int? rateLimitRemaining,
    Duration? rateLimitReset,
    String? version,
    DateTime? checkedAt,
  }) {
    return ApiStatus(
      provider: provider ?? this.provider,
      isAvailable: isAvailable ?? this.isAvailable,
      responseTime: responseTime ?? this.responseTime,
      errorMessage: errorMessage ?? this.errorMessage,
      rateLimitRemaining: rateLimitRemaining ?? this.rateLimitRemaining,
      rateLimitReset: rateLimitReset ?? this.rateLimitReset,
      version: version ?? this.version,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  @override
  String toString() {
    return 'ApiStatus(provider: $provider, available: $isAvailable, responseTime: ${responseTime.inMilliseconds}ms)';
  }
}

/// Represents book author information
class BookAuthor {
  final String id;
  final String name;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? biography;
  final List<String> aliases;
  final String? wikipediaUrl;
  final Map<String, dynamic> metadata;

  const BookAuthor({
    required this.id,
    required this.name,
    this.birthDate,
    this.deathDate,
    this.biography,
    required this.aliases,
    this.wikipediaUrl,
    required this.metadata,
  });

  bool get isAlive => deathDate == null;
  bool get hasBiography => biography != null && biography!.isNotEmpty;
  String get displayName =>
      aliases.isNotEmpty ? '${name} (${aliases.first})' : name;

  String get lifeSpan {
    final birth = birthDate?.year.toString() ?? '?';
    final death = deathDate?.year.toString() ?? (isAlive ? 'present' : '?');
    return '$birth - $death';
  }

  BookAuthor copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    DateTime? deathDate,
    String? biography,
    List<String>? aliases,
    String? wikipediaUrl,
    Map<String, dynamic>? metadata,
  }) {
    return BookAuthor(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      biography: biography ?? this.biography,
      aliases: aliases ?? this.aliases,
      wikipediaUrl: wikipediaUrl ?? this.wikipediaUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'BookAuthor(id: $id, name: $name, lifeSpan: $lifeSpan)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookAuthor && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}

/// Supported book formats
enum BookFormat {
  epub,
  pdf,
  text,
  mobi,
  html,
  xml;

  String get extension {
    switch (this) {
      case BookFormat.epub:
        return '.epub';
      case BookFormat.pdf:
        return '.pdf';
      case BookFormat.text:
        return '.txt';
      case BookFormat.mobi:
        return '.mobi';
      case BookFormat.html:
        return '.html';
      case BookFormat.xml:
        return '.xml';
    }
  }

  String get mimeType {
    switch (this) {
      case BookFormat.epub:
        return 'application/epub+zip';
      case BookFormat.pdf:
        return 'application/pdf';
      case BookFormat.text:
        return 'text/plain';
      case BookFormat.mobi:
        return 'application/x-mobipocket-ebook';
      case BookFormat.html:
        return 'text/html';
      case BookFormat.xml:
        return 'application/xml';
    }
  }

  String get displayName {
    switch (this) {
      case BookFormat.epub:
        return 'EPUB';
      case BookFormat.pdf:
        return 'PDF';
      case BookFormat.text:
        return 'Text';
      case BookFormat.mobi:
        return 'MOBI';
      case BookFormat.html:
        return 'HTML';
      case BookFormat.xml:
        return 'XML';
    }
  }

  static BookFormat? fromString(String format) {
    final normalizedFormat = format.toLowerCase().trim();
    switch (normalizedFormat) {
      case 'epub':
      case 'application/epub+zip':
        return BookFormat.epub;
      case 'pdf':
      case 'application/pdf':
        return BookFormat.pdf;
      case 'txt':
      case 'text':
      case 'text/plain':
        return BookFormat.text;
      case 'mobi':
      case 'application/x-mobipocket-ebook':
        return BookFormat.mobi;
      case 'html':
      case 'text/html':
        return BookFormat.html;
      case 'xml':
      case 'application/xml':
        return BookFormat.xml;
      default:
        return null;
    }
  }
}
