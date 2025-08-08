import 'package:flutter/material.dart';
import '../../domain/entities/api_entities.dart';

/// API Status Card widget for displaying API connection status
/// 
/// Shows the current status of API connections with appropriate
/// loading, error, and success states.
class ApiStatusCard extends StatelessWidget {
  final String? status;
  final ApiStatus? apiStatus;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ApiStatusCard({
    super.key,
    this.status,
    this.apiStatus,
    this.errorMessage,
    this.onRetry,
  });

  /// Constructor for ApiStatus objects
  const ApiStatusCard.fromApiStatus({
    super.key,
    required ApiStatus status,
    this.onRetry,
  })  : apiStatus = status,
        status = null,
        errorMessage = null;

  /// Loading state constructor
  const ApiStatusCard.loading({super.key})
      : status = 'loading',
        apiStatus = null,
        errorMessage = null,
        onRetry = null;

  /// Error state constructor
  const ApiStatusCard.error({
    super.key,
    required String error,
    this.onRetry,
  })  : status = 'error',
        apiStatus = null,
        errorMessage = error;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(),
            const SizedBox(height: 8),
            _buildStatusText(),
            if (_isErrorState() && onRetry != null) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isErrorState() {
    return status == 'error' || 
           (apiStatus != null && !apiStatus!.isAvailable);
  }

  String _getStatusString() {
    if (apiStatus != null) {
      return apiStatus!.isAvailable ? 'healthy' : 'error';
    }
    return status ?? 'unknown';
  }

  Widget _buildStatusIcon() {
    final statusString = _getStatusString();
    
    switch (statusString) {
      case 'loading':
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case 'error':
        return const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 32,
        );
      case 'healthy':
        return const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 32,
        );
      default:
        return const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 32,
        );
    }
  }

  Widget _buildStatusText() {
    final statusString = _getStatusString();
    
    switch (statusString) {
      case 'loading':
        return const Text('Checking API status...');
      case 'error':
        if (apiStatus != null) {
          return Text(
            'API Error: ${apiStatus!.errorMessage ?? 'Unknown error'}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          );
        }
        return Text(
          errorMessage ?? 'Unknown error occurred',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        );
      case 'healthy':
        if (apiStatus != null) {
          return Column(
            children: [
              Text('API Status: ${apiStatus!.provider} - Available'),
              const SizedBox(height: 4),
              Text(
                'Response time: ${apiStatus!.responseTime.inMilliseconds}ms',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                'Version: ${apiStatus!.version}',
                style: const TextStyle(color: Colors.grey),
              ),
              if (apiStatus!.hasRateLimit) ...[
                const SizedBox(height: 4),
                Text(
                  'Rate limit: ${apiStatus!.rateLimitRemaining} remaining',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ],
          );
        }
        return Text('Status: ${status ?? 'Connected'}');
      default:
        return Text('Status: ${status ?? 'Connected'}');
    }
  }
}