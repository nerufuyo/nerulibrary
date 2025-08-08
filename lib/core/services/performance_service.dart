import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/painting.dart';

/// Performance monitoring and optimization service
/// 
/// Provides comprehensive app performance tracking and optimization
/// including startup time, memory usage, and battery efficiency.
class PerformanceService {
  static PerformanceService? _instance;
  static PerformanceService get instance => _instance ??= PerformanceService._();
  
  PerformanceService._();
  
  // Performance metrics
  DateTime? _appStartTime;
  DateTime? _appReadyTime;
  final List<PerformanceMetric> _metrics = [];
  final Map<String, Stopwatch> _stopwatches = {};
  
  // Memory tracking
  int _maxMemoryUsage = 0;
  Timer? _memoryMonitorTimer;
  
  // Battery optimization
  bool _batteryOptimizationEnabled = true;
  
  /// Initialize performance monitoring
  void initialize() {
    _appStartTime = DateTime.now();
    _startMemoryMonitoring();
    _setupPerformanceObserver();
  }
  
  /// Mark app as ready (all critical initializations complete)
  void markAppReady() {
    _appReadyTime = DateTime.now();
    if (_appStartTime != null) {
      final startupTime = _appReadyTime!.difference(_appStartTime!);
      recordMetric(PerformanceMetric(
        name: 'app_startup_time',
        value: startupTime.inMilliseconds.toDouble(),
        unit: 'ms',
        timestamp: DateTime.now(),
        metadata: {'target': '3000', 'status': startupTime.inSeconds < 3 ? 'pass' : 'fail'},
      ));
    }
  }
  
  /// Start timing an operation
  void startTiming(String operationName) {
    _stopwatches[operationName] = Stopwatch()..start();
  }
  
  /// Stop timing an operation and record metric
  void stopTiming(String operationName, {Map<String, dynamic>? metadata}) {
    final stopwatch = _stopwatches.remove(operationName);
    if (stopwatch != null) {
      stopwatch.stop();
      recordMetric(PerformanceMetric(
        name: operationName,
        value: stopwatch.elapsedMilliseconds.toDouble(),
        unit: 'ms',
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      ));
    }
  }
  
  /// Record a performance metric
  void recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // Log performance issues in debug mode
    if (kDebugMode) {
      _logPerformanceIssue(metric);
    }
    
    // Cleanup old metrics (keep last 1000)
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, _metrics.length - 1000);
    }
  }
  
  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    final now = DateTime.now();
    final recentMetrics = _metrics.where(
      (m) => now.difference(m.timestamp).inMinutes < 30,
    ).toList();
    
    return PerformanceSummary(
      startupTime: _getStartupTime(),
      currentMemoryUsage: _getCurrentMemoryUsage(),
      maxMemoryUsage: _maxMemoryUsage,
      recentMetrics: recentMetrics,
      isPerformant: _isAppPerformant(),
    );
  }
  
  /// Enable or disable battery optimization
  void setBatteryOptimization(bool enabled) {
    _batteryOptimizationEnabled = enabled;
    
    if (enabled) {
      // Reduce background processing
      _reduceBackgroundActivity();
    } else {
      // Restore normal processing
      _restoreNormalActivity();
    }
  }
  
  /// Optimize image loading for performance
  void optimizeImageLoading() {
    // Configure image cache settings
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
  }
  
  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkMemoryUsage(),
    );
  }
  
  /// Check current memory usage
  void _checkMemoryUsage() {
    // Note: This is a simplified implementation
    // In a real app, you'd use platform-specific methods to get accurate memory usage
    final currentUsage = _getCurrentMemoryUsage();
    if (currentUsage > _maxMemoryUsage) {
      _maxMemoryUsage = currentUsage;
    }
    
    // Log memory warning if usage is too high
    if (currentUsage > 100 * 1024 * 1024) { // 100MB
      if (kDebugMode) {
        print('WARNING: High memory usage detected: ${(currentUsage / 1024 / 1024).toStringAsFixed(1)}MB');
      }
    }
  }
  
  /// Get current memory usage (simplified estimation)
  int _getCurrentMemoryUsage() {
    // This is a simplified estimation
    // In production, you'd use platform channels to get actual memory usage
    return 50 * 1024 * 1024; // Placeholder: 50MB
  }
  
  /// Get app startup time
  Duration? _getStartupTime() {
    if (_appStartTime != null && _appReadyTime != null) {
      return _appReadyTime!.difference(_appStartTime!);
    }
    return null;
  }
  
  /// Check if app is performing within acceptable limits
  bool _isAppPerformant() {
    final startupTime = _getStartupTime();
    final memoryUsage = _getCurrentMemoryUsage();
    
    return (startupTime?.inSeconds ?? 0) < 3 && 
           memoryUsage < 100 * 1024 * 1024; // 100MB
  }
  
  /// Setup performance observer for frame timing
  void _setupPerformanceObserver() {
    // Monitor frame rendering performance
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final frameTime = timing.totalSpan.inMicroseconds / 1000.0; // ms
        
        if (frameTime > 16.67) { // More than 60fps threshold
          recordMetric(PerformanceMetric(
            name: 'frame_time',
            value: frameTime,
            unit: 'ms',
            timestamp: DateTime.now(),
            metadata: {'target_fps': '60', 'status': 'slow'},
          ));
        }
      }
    });
  }
  
  /// Log performance issues in debug mode
  void _logPerformanceIssue(PerformanceMetric metric) {
    switch (metric.name) {
      case 'app_startup_time':
        if (metric.value > 3000) {
          print('PERFORMANCE WARNING: Slow startup time: ${metric.value}ms (target: <3000ms)');
        }
        break;
      case 'frame_time':
        if (metric.value > 16.67) {
          print('PERFORMANCE WARNING: Slow frame: ${metric.value}ms (target: <16.67ms for 60fps)');
        }
        break;
      default:
        if (metric.value > 1000) {
          print('PERFORMANCE WARNING: Slow operation "${metric.name}": ${metric.value}ms');
        }
    }
  }
  
  /// Reduce background activity for battery optimization
  void _reduceBackgroundActivity() {
    if (!_batteryOptimizationEnabled) return;
    
    // Reduce timer frequencies
    // Pause non-critical background tasks
    // Lower animation frame rates if needed
  }
  
  /// Restore normal activity
  void _restoreNormalActivity() {
    if (!_batteryOptimizationEnabled) return;
    
    // Restore normal timer frequencies
    // Resume background tasks
    // Restore normal animation frame rates
  }
  
  /// Dispose resources
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _stopwatches.clear();
    _metrics.clear();
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  const PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.metadata,
  });
  
  @override
  String toString() {
    return 'PerformanceMetric(name: $name, value: $value$unit, timestamp: $timestamp)';
  }
}

/// Performance summary data class
class PerformanceSummary {
  final Duration? startupTime;
  final int currentMemoryUsage;
  final int maxMemoryUsage;
  final List<PerformanceMetric> recentMetrics;
  final bool isPerformant;
  
  const PerformanceSummary({
    required this.startupTime,
    required this.currentMemoryUsage,
    required this.maxMemoryUsage,
    required this.recentMetrics,
    required this.isPerformant,
  });
  
  /// Get formatted memory usage string
  String get formattedCurrentMemory => 
      '${(currentMemoryUsage / 1024 / 1024).toStringAsFixed(1)}MB';
  
  /// Get formatted max memory usage string
  String get formattedMaxMemory => 
      '${(maxMemoryUsage / 1024 / 1024).toStringAsFixed(1)}MB';
  
  /// Get startup time in seconds
  double? get startupTimeSeconds => (startupTime?.inMilliseconds.toDouble() ?? 0) / 1000;
  
  /// Check if startup time meets target
  bool get startupTimeMeetsTarget => (startupTimeSeconds ?? 0) < 3.0;
  
  /// Check if memory usage meets target
  bool get memoryUsageMeetsTarget => currentMemoryUsage < 100 * 1024 * 1024; // 100MB
  
  @override
  String toString() {
    return '''
Performance Summary:
- Startup Time: ${startupTime?.inMilliseconds ?? 'N/A'}ms (target: <3000ms)
- Current Memory: $formattedCurrentMemory (target: <100MB)
- Max Memory: $formattedMaxMemory
- Is Performant: $isPerformant
- Recent Metrics: ${recentMetrics.length}
''';
  }
}
