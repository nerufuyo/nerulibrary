/// Route paths constants for the application
/// 
/// Centralizes all route definitions to ensure consistency
/// and prevent typos in navigation throughout the app.
class RoutePaths {
  // Authentication Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  
  // Main App Routes
  static const String library = '/library';
  static const String discovery = '/discovery';
  static const String profile = '/profile';
  
  // Reader Routes
  static const String pdfReader = '/reader/pdf/:bookId';
  static const String epubReader = '/reader/epub/:bookId';
  
  // Utility method to build reader routes
  static String buildPdfReaderPath(String bookId) => '/reader/pdf/$bookId';
  static String buildEpubReaderPath(String bookId) => '/reader/epub/$bookId';
  static String buildBookDetailPath(String bookId) => '/library/book/$bookId';
}

/// Route names for named navigation
/// 
/// Provides string constants for route names used in navigation
/// and deep linking throughout the application.
class RouteNames {
  // Authentication Routes
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  
  // Main App Routes
  static const String library = 'library';
  static const String discovery = 'discovery';
  static const String profile = 'profile';
  
  // Detail Routes
  static const String bookDetail = 'book-detail';
  static const String search = 'search';
  static const String settings = 'settings';
  
  // Reader Routes
  static const String pdfReader = 'pdf-reader';
  static const String epubReader = 'epub-reader';
}
