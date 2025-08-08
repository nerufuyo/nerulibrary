import '../constants/api_constants.dart';

/// API endpoint URL builder and management
///
/// Provides utility methods to build complete API URLs
/// for different book sources and handle endpoint configuration.
class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  /// Helper method to build complete URLs with query parameters
  static String _buildUrl(
    String baseUrl,
    String path,
    Map<String, String> params,
  ) {
    final uri = Uri.parse(baseUrl + path);
    final newUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...params,
    });
    return newUri.toString();
  }

  /// Validate if a URL is properly formatted
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Extract domain from URL
  static String? getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  /// Check if URL is HTTPS
  static bool isSecureUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme.toLowerCase() == 'https';
    } catch (e) {
      return false;
    }
  }
}

/// Project Gutenberg API endpoints
class ProjectGutenbergEndpoints {
  static String get baseUrl => ApiConstants.projectGutenbergBaseUrl;

  /// Build search URL
  static String search({
    required String query,
    String format = ApiConstants.formatJson,
    int limit = ApiConstants.defaultSearchLimit,
  }) {
    final params = <String, String>{
      ApiConstants.queryParamSearch: query,
      ApiConstants.queryParamFormat: format,
      ApiConstants.queryParamLimit: limit.toString(),
    };

    return ApiEndpoints._buildUrl(
      baseUrl,
      ApiConstants.projectGutenbergSearch,
      params,
    );
  }

  /// Build EPUB download URL
  static String epubDownload(String bookId) {
    return baseUrl +
        ApiConstants.projectGutenbergEpub.replaceAll('{id}', bookId);
  }

  /// Build PDF download URL
  static String pdfDownload(String bookId) {
    return baseUrl +
        ApiConstants.projectGutenbergPdf.replaceAll('{id}', bookId);
  }

  /// Build text download URL
  static String textDownload(String bookId) {
    return baseUrl +
        ApiConstants.projectGutenbergText.replaceAll('{id}', bookId);
  }
}

/// Internet Archive API endpoints
class InternetArchiveEndpoints {
  static String get baseUrl => ApiConstants.internetArchiveBaseUrl;

  /// Build advanced search URL
  static String search({
    required String query,
    String format = ApiConstants.formatJson,
    int rows = ApiConstants.defaultSearchLimit,
    int page = 1,
  }) {
    final params = <String, String>{
      ApiConstants.queryParamSearch: 'mediatype:texts AND ($query)',
      'output': format,
      'rows': rows.toString(),
      'page': page.toString(),
    };

    return ApiEndpoints._buildUrl(
      baseUrl,
      ApiConstants.internetArchiveSearch,
      params,
    );
  }

  /// Build metadata URL
  static String metadata(String identifier) {
    return baseUrl +
        ApiConstants.internetArchiveMetadata
            .replaceAll('{identifier}', identifier);
  }

  /// Build download URL
  static String download(String identifier, String filename) {
    return baseUrl +
        ApiConstants.internetArchiveDownload
            .replaceAll('{identifier}', identifier)
            .replaceAll('{filename}', filename);
  }
}

/// OpenLibrary API endpoints
class OpenLibraryEndpoints {
  static String get baseUrl => ApiConstants.openlibraryBaseUrl;

  /// Build search URL
  static String search({
    required String query,
    int limit = ApiConstants.defaultSearchLimit,
    int offset = 0,
  }) {
    final params = <String, String>{
      ApiConstants.queryParamSearch: query,
      ApiConstants.queryParamLimit: limit.toString(),
      ApiConstants.queryParamOffset: offset.toString(),
    };

    return ApiEndpoints._buildUrl(
      baseUrl,
      ApiConstants.openlibrarySearch,
      params,
    );
  }

  /// Build works URL
  static String works(String workId) {
    return baseUrl +
        ApiConstants.openlibraryWorks.replaceAll('{work_id}', workId);
  }

  /// Build cover image URL
  static String coverImage({
    required String coverId,
    String size = 'M', // S, M, L
  }) {
    return '$baseUrl/covers/b/id/$coverId-$size.jpg';
  }
}
