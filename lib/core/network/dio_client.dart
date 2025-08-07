import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart' as app_exceptions;

/// HTTP client configuration and management
/// 
/// Handles HTTP requests with proper error handling, timeouts, retries,
/// and network connectivity checks. Provides centralized HTTP operations.
class DioClient {
  static DioClient? _instance;
  static DioClient get instance => _instance ??= DioClient._();
  
  late final Dio _dio;
  final Connectivity _connectivity = Connectivity();
  
  DioClient._() {
    _dio = Dio();
    _setupDio();
  }
  
  /// Get the configured Dio instance
  Dio get dio => _dio;
  
  /// Setup Dio configuration
  void _setupDio() {
    final appConfig = AppConfig.instance;
    
    _dio.options = BaseOptions(
      connectTimeout: appConfig.connectionTimeout,
      receiveTimeout: appConfig.receiveTimeout,
      sendTimeout: appConfig.networkTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': '${appConfig.appName}/${appConfig.appVersion}',
      },
    );
    
    // Add request interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
    
    // Add logging in debug mode
    if (appConfig.debugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
        ),
      );
    }
  }
  
  /// Handle request interceptor
  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add any additional headers or modifications here
    handler.next(options);
  }
  
  /// Handle response interceptor
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    // Handle successful responses
    handler.next(response);
  }
  
  /// Handle error interceptor
  void _onError(DioException error, ErrorInterceptorHandler handler) {
    final appException = _handleDioError(error);
    handler.reject(
      DioException(
        requestOptions: error.requestOptions,
        error: appException,
        type: error.type,
        response: error.response,
        message: appException.message,
      ),
    );
  }
  
  /// Convert DioException to app-specific exceptions
  app_exceptions.AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return app_exceptions.NetworkException(
          'Request timeout. Please check your internet connection.',
          code: 'TIMEOUT',
        );
        
      case DioExceptionType.badResponse:
        return _handleHttpError(error.response);
        
      case DioExceptionType.cancel:
        return app_exceptions.NetworkException(
          'Request was cancelled.',
          code: 'CANCELLED',
        );
        
      case DioExceptionType.connectionError:
        return app_exceptions.NetworkException(
          'No internet connection. Please check your network settings.',
          code: 'NO_CONNECTION',
        );
        
      case DioExceptionType.badCertificate:
        return app_exceptions.NetworkException(
          'Invalid SSL certificate.',
          code: 'BAD_CERTIFICATE',
        );
        
      case DioExceptionType.unknown:
        return app_exceptions.NetworkException(
          'An unexpected error occurred: ${error.message}',
          code: 'UNKNOWN',
        );
    }
  }
  
  /// Handle HTTP response errors
  app_exceptions.AppException _handleHttpError(Response? response) {
    if (response == null) {
      return app_exceptions.NetworkException('No response received');
    }
    
    final statusCode = response.statusCode ?? 0;
    final data = response.data;
    
    String message;
    switch (statusCode) {
      case ApiConstants.HTTP_BAD_REQUEST:
        message = 'Invalid request. Please check your input.';
        break;
      case ApiConstants.HTTP_UNAUTHORIZED:
        message = 'Authentication required. Please sign in.';
        break;
      case ApiConstants.HTTP_FORBIDDEN:
        message = 'Access denied. You don\'t have permission.';
        break;
      case ApiConstants.HTTP_NOT_FOUND:
        message = 'Resource not found.';
        break;
      case ApiConstants.HTTP_TOO_MANY_REQUESTS:
        message = 'Too many requests. Please try again later.';
        break;
      case ApiConstants.HTTP_INTERNAL_SERVER_ERROR:
        message = 'Server error. Please try again later.';
        break;
      case ApiConstants.HTTP_BAD_GATEWAY:
        message = 'Service temporarily unavailable.';
        break;
      case ApiConstants.HTTP_SERVICE_UNAVAILABLE:
        message = 'Service unavailable. Please try again later.';
        break;
      default:
        message = 'HTTP Error $statusCode';
    }
    
    // Try to extract error message from response
    if (data is Map<String, dynamic>) {
      final errorMessage = data['error'] ?? 
                          data['message'] ?? 
                          data['detail'];
      if (errorMessage != null) {
        message = errorMessage.toString();
      }
    }
    
    return app_exceptions.ApiException(
      message,
      statusCode: statusCode,
      responseData: data is Map<String, dynamic> ? data : null,
      code: statusCode.toString(),
    );
  }
  
  /// Check network connectivity
  Future<bool> isConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
  
  /// Make a GET request with error handling
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _ensureConnectivity();
    
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      if (e is DioException) {
        rethrow;
      }
      throw app_exceptions.NetworkException(
        'GET request failed: ${e.toString()}',
      );
    }
  }
  
  /// Make a POST request with error handling
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _ensureConnectivity();
    
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      if (e is DioException) {
        rethrow;
      }
      throw app_exceptions.NetworkException(
        'POST request failed: ${e.toString()}',
      );
    }
  }
  
  /// Make a PUT request with error handling
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _ensureConnectivity();
    
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      if (e is DioException) {
        rethrow;
      }
      throw app_exceptions.NetworkException(
        'PUT request failed: ${e.toString()}',
      );
    }
  }
  
  /// Make a DELETE request with error handling
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureConnectivity();
    
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      if (e is DioException) {
        rethrow;
      }
      throw app_exceptions.NetworkException(
        'DELETE request failed: ${e.toString()}',
      );
    }
  }
  
  /// Download file with progress tracking
  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Options? options,
  }) async {
    await _ensureConnectivity();
    
    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        options: options,
      );
    } catch (e) {
      if (e is DioException) {
        rethrow;
      }
      throw app_exceptions.NetworkException(
        'Download failed: ${e.toString()}',
      );
    }
  }
  
  /// Ensure network connectivity before making requests
  Future<void> _ensureConnectivity() async {
    if (!await isConnected()) {
      throw app_exceptions.NetworkException(
        'No internet connection available.',
        code: 'NO_CONNECTION',
      );
    }
  }
  
  /// Update base URL
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }
  
  /// Add authentication header
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  /// Remove authentication header
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
  
  /// Add custom header
  void addHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }
  
  /// Remove custom header
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }
}
