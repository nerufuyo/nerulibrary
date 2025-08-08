/// API endpoints and configuration constants
///
/// Contains all external API endpoints, rate limits, and service configurations
/// for book discovery and download services.
class ApiConstants {
  // Project Gutenberg API
  static const String projectGutenbergBaseUrl = 'https://www.gutenberg.org';
  static const String projectGutenbergSearch = '/ebooks/search/';
  static const String projectGutenbergEpub = '/ebooks/{id}.epub.noimages';
  static const String projectGutenbergPdf = '/ebooks/{id}.pdf';
  static const String projectGutenbergText = '/ebooks/{id}/pg{id}.txt';
  static const Duration projectGutenbergRateLimit = Duration(seconds: 1);

  // Internet Archive API
  static const String internetArchiveBaseUrl = 'https://archive.org';
  static const String internetArchiveSearch = '/advancedsearch.php';
  static const String internetArchiveMetadata = '/metadata/{identifier}';
  static const String internetArchiveDownload =
      '/download/{identifier}/{filename}';
  static const String internetArchiveScrape = '/services/search/v1/scrape';
  static const int internetArchiveRequestsPerMinute = 100;

  // OpenLibrary API
  static const String openlibraryBaseUrl = 'https://openlibrary.org';
  static const String openlibrarySearch = '/search.json';
  static const String openlibraryWorks = '/works/{work_id}.json';
  static const String openlibraryBooks = '/api/books';
  static const String openlibraryAuthors = '/authors/{author_id}.json';
  static const int openlibraryRequestsPerMinute = 100;

  // DOAB (Directory of Open Access Books) API
  static const String doabBaseUrl = 'https://directory.doabooks.org';
  static const String doabSearch = '/rest/search';
  static const String doabBooks = '/rest/books/{book_id}';
  static const String doabSubjects = '/rest/subjects';
  static const Duration doabRateLimit = Duration(milliseconds: 500);

  // Common Query Parameters
  static const String queryParamSearch = 'q';
  static const String queryParamFormat = 'format';
  static const String queryParamLimit = 'limit';
  static const String queryParamOffset = 'offset';
  static const String queryParamPage = 'page';

  // Response Formats
  static const String formatJson = 'json';
  static const String formatXml = 'xml';
  static const String formatEpub = 'epub';
  static const String formatPdf = 'pdf';
  static const String formatTxt = 'txt';

  // Default Values
  static const int defaultSearchLimit = 20;
  static const int defaultMaxRetries = 3;
  static const Duration defaultRetryDelay = Duration(seconds: 2);

  // Error Codes
  static const int httpBadRequest = 400;
  static const int httpUnauthorized = 401;
  static const int httpForbidden = 403;
  static const int httpNotFound = 404;
  static const int httpTooManyRequests = 429;
  static const int httpInternalServerError = 500;
  static const int httpBadGateway = 502;
  static const int httpServiceUnavailable = 503;

  // Private constructor to prevent instantiation
  ApiConstants._();
}
