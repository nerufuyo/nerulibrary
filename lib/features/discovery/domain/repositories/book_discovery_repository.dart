import 'package:dartz/dartz.dart';

import '../entities/api_entities.dart';
import '../failures/api_failures.dart';

/// Abstract repository interface for book discovery APIs
///
/// This interface defines the contract that all API implementations must follow.
/// It provides a consistent way to interact with different book API providers
/// such as Project Gutenberg, Internet Archive, and OpenLibrary.
abstract class BookDiscoveryRepository {
  /// Search books with query string
  ///
  /// Returns paginated results with metadata from the API provider.
  /// The [query] parameter supports different search types depending on the provider.
  ///
  /// Parameters:
  /// - [query]: Search term or query string
  /// - [page]: Page number for pagination (default: 1)
  /// - [limit]: Number of results per page (default: 20, max: 100)
  /// - [filters]: Optional filters for advanced search
  ///
  /// Returns [Either] containing [ApiFailure] on error or [SearchResult] on success.
  Future<Either<ApiFailure, SearchResult>> searchBooks({
    required String query,
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  });

  /// Get detailed book information
  ///
  /// Retrieves comprehensive metadata for a specific book identified by [bookId].
  /// The format and content of [bookId] depends on the API provider.
  ///
  /// Parameters:
  /// - [bookId]: Unique identifier for the book in the API provider's system
  ///
  /// Returns [Either] containing [ApiFailure] on error or [BookDetail] on success.
  Future<Either<ApiFailure, BookDetail>> getBookDetail(String bookId);

  /// Get download URL for book file
  ///
  /// Retrieves download information for a specific book and format.
  /// Some providers may require additional authentication or have rate limits.
  ///
  /// Parameters:
  /// - [bookId]: Unique identifier for the book
  /// - [format]: Desired book format (EPUB, PDF, etc.)
  ///
  /// Returns [Either] containing [ApiFailure] on error or [DownloadInfo] on success.
  Future<Either<ApiFailure, DownloadInfo>> getDownloadUrl({
    required String bookId,
    required BookFormat format,
  });

  /// Validate API connectivity and rate limits
  ///
  /// Checks if the API is available and returns status information including
  /// rate limit details, response time, and any error conditions.
  ///
  /// Returns [Either] containing [ApiFailure] on error or [ApiStatus] on success.
  Future<Either<ApiFailure, ApiStatus>> checkApiStatus();

  /// Get author information
  ///
  /// Retrieves detailed information about an author identified by [authorId].
  /// This may not be available for all API providers.
  ///
  /// Parameters:
  /// - [authorId]: Unique identifier for the author in the API provider's system
  ///
  /// Returns [Either] containing [ApiFailure] on error or [BookAuthor] on success.
  Future<Either<ApiFailure, BookAuthor>> getAuthorDetail(String authorId);

  /// Get books by author
  ///
  /// Retrieves all books by a specific author with pagination support.
  ///
  /// Parameters:
  /// - [authorId]: Unique identifier for the author
  /// - [page]: Page number for pagination (default: 1)
  /// - [limit]: Number of results per page (default: 20)
  ///
  /// Returns [Either] containing [ApiFailure] on error or [SearchResult] on success.
  Future<Either<ApiFailure, SearchResult>> getBooksByAuthor({
    required String authorId,
    int page = 1,
    int limit = 20,
  });

  /// Get books by subject/genre
  ///
  /// Retrieves books matching a specific subject or genre with pagination support.
  ///
  /// Parameters:
  /// - [subject]: Subject or genre identifier
  /// - [page]: Page number for pagination (default: 1)
  /// - [limit]: Number of results per page (default: 20)
  ///
  /// Returns [Either] containing [ApiFailure] on error or [SearchResult] on success.
  Future<Either<ApiFailure, SearchResult>> getBooksBySubject({
    required String subject,
    int page = 1,
    int limit = 20,
  });

  /// Get popular/trending books
  ///
  /// Retrieves currently popular or trending books based on download counts,
  /// ratings, or other provider-specific metrics.
  ///
  /// Parameters:
  /// - [page]: Page number for pagination (default: 1)
  /// - [limit]: Number of results per page (default: 20)
  /// - [timeframe]: Time period for popularity calculation (optional)
  ///
  /// Returns [Either] containing [ApiFailure] on error or [SearchResult] on success.
  Future<Either<ApiFailure, SearchResult>> getPopularBooks({
    int page = 1,
    int limit = 20,
    String? timeframe,
  });

  /// Get recently added books
  ///
  /// Retrieves recently added books to the API provider's collection.
  ///
  /// Parameters:
  /// - [page]: Page number for pagination (default: 1)
  /// - [limit]: Number of results per page (default: 20)
  /// - [days]: Number of days to look back (optional)
  ///
  /// Returns [Either] containing [ApiFailure] on error or [SearchResult] on success.
  Future<Either<ApiFailure, SearchResult>> getRecentBooks({
    int page = 1,
    int limit = 20,
    int? days,
  });

  /// Get available subjects/genres
  ///
  /// Retrieves a list of all available subjects or genres from the API provider.
  /// This can be used for browsing and filtering purposes.
  ///
  /// Returns [Either] containing [ApiFailure] on error or [List<String>] on success.
  Future<Either<ApiFailure, List<String>>> getAvailableSubjects();

  /// Get available languages
  ///
  /// Retrieves a list of all available languages from the API provider.
  /// Language codes typically follow ISO 639-1 or ISO 639-2 standards.
  ///
  /// Returns [Either] containing [ApiFailure] on error or [List<String>] on success.
  Future<Either<ApiFailure, List<String>>> getAvailableLanguages();

  /// Search suggestions/autocomplete
  ///
  /// Provides search suggestions based on partial query input.
  /// This helps users discover relevant search terms.
  ///
  /// Parameters:
  /// - [partial]: Partial search query
  /// - [limit]: Maximum number of suggestions (default: 10)
  ///
  /// Returns [Either] containing [ApiFailure] on error or [List<String>] on success.
  Future<Either<ApiFailure, List<String>>> getSearchSuggestions({
    required String partial,
    int limit = 10,
  });

  /// Get API provider name
  ///
  /// Returns the human-readable name of the API provider.
  String get providerName;

  /// Get API base URL
  ///
  /// Returns the base URL for the API provider.
  String get baseUrl;

  /// Check if the provider supports a specific feature
  ///
  /// Different providers may have different capabilities.
  /// This method helps determine what features are available.
  bool supportsFeature(ApiFeature feature);
}

/// Enumeration of API features that providers may or may not support
enum ApiFeature {
  /// Full-text search within book content
  fullTextSearch,

  /// Advanced filtering options
  advancedFilters,

  /// Author information and biography
  authorDetails,

  /// Book ratings and reviews
  ratingsAndReviews,

  /// Download statistics
  downloadStats,

  /// Multiple book formats
  multipleFormats,

  /// Cover images
  coverImages,

  /// Subject/genre browsing
  subjectBrowsing,

  /// Language filtering
  languageFiltering,

  /// Recently added content
  recentContent,

  /// Popular/trending content
  popularContent,

  /// Search suggestions
  searchSuggestions,

  /// Pagination support
  pagination,

  /// Rate limiting information
  rateLimitInfo,
}

/// Mix-in interface for repositories that support caching
mixin CacheableRepository {
  /// Clear all cached data for this repository
  Future<void> clearCache();

  /// Clear cached data older than the specified duration
  Future<void> clearExpiredCache(Duration maxAge);

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats();

  /// Warm up cache with popular content
  Future<void> warmUpCache();
}

/// Mix-in interface for repositories that support offline functionality
mixin OfflineRepository {
  /// Check if offline mode is available
  bool get isOfflineModeAvailable;

  /// Get offline content
  Future<Either<ApiFailure, SearchResult>> getOfflineContent({
    int page = 1,
    int limit = 20,
  });

  /// Cache content for offline use
  Future<Either<ApiFailure, void>> cacheForOffline(String bookId);

  /// Remove content from offline cache
  Future<Either<ApiFailure, void>> removeFromOfflineCache(String bookId);

  /// Get offline storage usage
  Future<Map<String, dynamic>> getOfflineStorageStats();
}
