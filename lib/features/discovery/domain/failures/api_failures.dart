import '../../../../core/errors/failures.dart';

/// Base class for all API-related failures
abstract class ApiFailure extends Failure {
  const ApiFailure({required super.message});
}

/// Network-related API failures
class NetworkApiFailure extends ApiFailure {
  const NetworkApiFailure({required super.message});

  @override
  String toString() => 'NetworkApiFailure: $message';
}

/// HTTP status code failures
class HttpApiFailure extends ApiFailure {
  final int statusCode;
  final Map<String, dynamic>? response;

  const HttpApiFailure({
    required super.message,
    required this.statusCode,
    this.response,
  });

  @override
  String toString() => 'HttpApiFailure($statusCode): $message';
}

/// JSON parsing failures
class ParseApiFailure extends ApiFailure {
  final String originalData;

  const ParseApiFailure({
    required super.message,
    required this.originalData,
  });

  @override
  String toString() => 'ParseApiFailure: $message';
}

/// Rate limiting failures
class RateLimitApiFailure extends ApiFailure {
  final Duration retryAfter;
  final String apiProvider;

  const RateLimitApiFailure({
    required super.message,
    required this.retryAfter,
    required this.apiProvider,
  });

  @override
  String toString() =>
      'RateLimitApiFailure($apiProvider): $message (retry after: ${retryAfter.inSeconds}s)';
}

/// Timeout failures
class TimeoutApiFailure extends ApiFailure {
  final Duration timeout;

  const TimeoutApiFailure({
    required super.message,
    required this.timeout,
  });

  @override
  String toString() =>
      'TimeoutApiFailure: $message (timeout: ${timeout.inSeconds}s)';
}

/// Book not found failures
class BookNotFoundApiFailure extends ApiFailure {
  final String bookId;
  final String apiProvider;

  const BookNotFoundApiFailure({
    required super.message,
    required this.bookId,
    required this.apiProvider,
  });

  @override
  String toString() =>
      'BookNotFoundApiFailure($apiProvider): $message (bookId: $bookId)';
}

/// Invalid format request failures
class InvalidFormatApiFailure extends ApiFailure {
  final String requestedFormat;
  final List<String> availableFormats;

  const InvalidFormatApiFailure({
    required super.message,
    required this.requestedFormat,
    required this.availableFormats,
  });

  @override
  String toString() =>
      'InvalidFormatApiFailure: $message (requested: $requestedFormat, available: $availableFormats)';
}

/// Data validation failures
class ValidationApiFailure extends ApiFailure {
  final Map<String, dynamic>? invalidData;
  final List<String> validationErrors;

  const ValidationApiFailure({
    required super.message,
    this.invalidData,
    required this.validationErrors,
  });

  @override
  String toString() =>
      'ValidationApiFailure: $message (errors: $validationErrors)';
}

/// API service unavailable failures
class ServiceUnavailableApiFailure extends ApiFailure {
  final String apiProvider;
  final Duration? estimatedRecovery;

  const ServiceUnavailableApiFailure({
    required super.message,
    required this.apiProvider,
    this.estimatedRecovery,
  });

  @override
  String toString() => 'ServiceUnavailableApiFailure($apiProvider): $message';
}

/// Authentication/authorization failures
class AuthenticationApiFailure extends ApiFailure {
  final String apiProvider;

  const AuthenticationApiFailure({
    required super.message,
    required this.apiProvider,
  });

  @override
  String toString() => 'AuthenticationApiFailure($apiProvider): $message';
}

/// Unknown API failures
class UnknownApiFailure extends ApiFailure {
  final dynamic originalError;

  const UnknownApiFailure({
    required super.message,
    this.originalError,
  });

  @override
  String toString() => 'UnknownApiFailure: $message (original: $originalError)';
}
