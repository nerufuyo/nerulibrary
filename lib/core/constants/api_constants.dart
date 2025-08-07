/// API endpoints and configuration constants
/// 
/// Contains all external API endpoints, rate limits, and service configurations
/// for book discovery and download services.
class ApiConstants {
  // Project Gutenberg API
  static const String PROJECT_GUTENBERG_BASE_URL = 'https://www.gutenberg.org';
  static const String PROJECT_GUTENBERG_SEARCH = '/ebooks/search/';
  static const String PROJECT_GUTENBERG_EPUB = '/ebooks/{id}.epub.noimages';
  static const String PROJECT_GUTENBERG_PDF = '/ebooks/{id}.pdf';
  static const String PROJECT_GUTENBERG_TEXT = '/ebooks/{id}/pg{id}.txt';
  static const Duration PROJECT_GUTENBERG_RATE_LIMIT = Duration(seconds: 1);
  
  // Internet Archive API
  static const String INTERNET_ARCHIVE_BASE_URL = 'https://archive.org';
  static const String INTERNET_ARCHIVE_SEARCH = '/advancedsearch.php';
  static const String INTERNET_ARCHIVE_METADATA = '/metadata/{identifier}';
  static const String INTERNET_ARCHIVE_DOWNLOAD = '/download/{identifier}/{filename}';
  static const String INTERNET_ARCHIVE_SCRAPE = '/services/search/v1/scrape';
  static const int INTERNET_ARCHIVE_REQUESTS_PER_MINUTE = 100;
  
  // OpenLibrary API
  static const String OPENLIBRARY_BASE_URL = 'https://openlibrary.org';
  static const String OPENLIBRARY_SEARCH = '/search.json';
  static const String OPENLIBRARY_WORKS = '/works/{work_id}.json';
  static const String OPENLIBRARY_BOOKS = '/api/books';
  static const String OPENLIBRARY_AUTHORS = '/authors/{author_id}.json';
  static const int OPENLIBRARY_REQUESTS_PER_MINUTE = 100;
  
  // DOAB (Directory of Open Access Books) API
  static const String DOAB_BASE_URL = 'https://directory.doabooks.org';
  static const String DOAB_SEARCH = '/rest/search';
  static const String DOAB_BOOKS = '/rest/books/{book_id}';
  static const String DOAB_SUBJECTS = '/rest/subjects';
  static const Duration DOAB_RATE_LIMIT = Duration(milliseconds: 500);
  
  // Common Query Parameters
  static const String QUERY_PARAM_SEARCH = 'q';
  static const String QUERY_PARAM_FORMAT = 'format';
  static const String QUERY_PARAM_LIMIT = 'limit';
  static const String QUERY_PARAM_OFFSET = 'offset';
  static const String QUERY_PARAM_PAGE = 'page';
  
  // Response Formats
  static const String FORMAT_JSON = 'json';
  static const String FORMAT_XML = 'xml';
  static const String FORMAT_EPUB = 'epub';
  static const String FORMAT_PDF = 'pdf';
  static const String FORMAT_TXT = 'txt';
  
  // Default Values
  static const int DEFAULT_SEARCH_LIMIT = 20;
  static const int DEFAULT_MAX_RETRIES = 3;
  static const Duration DEFAULT_RETRY_DELAY = Duration(seconds: 2);
  
  // Error Codes
  static const int HTTP_BAD_REQUEST = 400;
  static const int HTTP_UNAUTHORIZED = 401;
  static const int HTTP_FORBIDDEN = 403;
  static const int HTTP_NOT_FOUND = 404;
  static const int HTTP_TOO_MANY_REQUESTS = 429;
  static const int HTTP_INTERNAL_SERVER_ERROR = 500;
  static const int HTTP_BAD_GATEWAY = 502;
  static const int HTTP_SERVICE_UNAVAILABLE = 503;
  
  // Private constructor to prevent instantiation
  ApiConstants._();
}
