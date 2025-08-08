import 'package:flutter_test/flutter_test.dart';
import 'package:nerulibrary/core/services/performance_service.dart';

void main() {
  // Initialize Flutter test binding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PerformanceService', () {
    late PerformanceService performanceService;

    setUp(() {
      performanceService = PerformanceService.instance;
    });

    tearDown(() {
      // Clean up after each test
      performanceService.dispose();
    });

    group('Singleton Pattern', () {
      test('should return same instance when accessed multiple times', () {
        // Arrange & Act
        final instance1 = PerformanceService.instance;
        final instance2 = PerformanceService.instance;

        // Assert
        expect(instance1, equals(instance2));
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Metric Recording', () {
      test('should record performance metrics correctly', () {
        // Arrange
        final metric = PerformanceMetric(
          name: 'test_operation',
          value: 150.0,
          unit: 'ms',
          timestamp: DateTime.now(),
          metadata: {'category': 'test'},
        );

        // Act
        performanceService.recordMetric(metric);
        final summary = performanceService.getPerformanceSummary();

        // Assert
        expect(summary.recentMetrics, contains(metric));
        expect(summary.recentMetrics.length, greaterThan(0));
      });

      test('should handle multiple metric recordings', () {
        // Arrange
        final metrics = List.generate(
            3,
            (index) => PerformanceMetric(
                  name: 'operation_$index',
                  value: (index * 100.0),
                  unit: 'ms',
                  timestamp: DateTime.now(),
                  metadata: {'index': index.toString()},
                ));

        // Act
        for (final metric in metrics) {
          performanceService.recordMetric(metric);
        }
        final summary = performanceService.getPerformanceSummary();

        // Assert
        expect(
            summary.recentMetrics.length, greaterThanOrEqualTo(metrics.length));
        for (final metric in metrics) {
          expect(summary.recentMetrics, contains(metric));
        }
      });
    });

    group('Performance Summary', () {
      test('should provide comprehensive performance summary', () {
        // Arrange
        performanceService.initialize();

        // Act
        final summary = performanceService.getPerformanceSummary();

        // Assert
        expect(summary, isA<PerformanceSummary>());
        expect(summary.currentMemoryUsage, isA<int>());
        expect(summary.maxMemoryUsage, isA<int>());
        expect(summary.recentMetrics, isA<List<PerformanceMetric>>());
        expect(summary.isPerformant, isA<bool>());
      });

      test('should format memory usage correctly', () {
        // Arrange
        performanceService.initialize();

        // Act
        final summary = performanceService.getPerformanceSummary();

        // Assert
        expect(summary.formattedCurrentMemory, matches(r'\d+\.\d+MB'));
        expect(summary.formattedMaxMemory, matches(r'\d+\.\d+MB'));
      });
    });

    group('Service Lifecycle', () {
      test('should initialize without errors', () {
        // Act & Assert
        expect(() => performanceService.initialize(), returnsNormally);
      });

      test('should mark app ready and record startup time', () {
        // Arrange
        performanceService.initialize();

        // Act
        performanceService.markAppReady();
        final summary = performanceService.getPerformanceSummary();

        // Assert
        expect(summary.startupTime, isNotNull);
        final startupMetrics = summary.recentMetrics
            .where((m) => m.name == 'app_startup_time')
            .toList();
        expect(startupMetrics, isNotEmpty);
      });

      test('should handle timing operations correctly', () {
        // Arrange
        const operationName = 'test_operation';

        // Act
        performanceService.startTiming(operationName);
        performanceService
            .stopTiming(operationName, metadata: {'test': 'true'});

        final summary = performanceService.getPerformanceSummary();

        // Assert
        final operationMetrics = summary.recentMetrics
            .where((m) => m.name == operationName)
            .toList();
        expect(operationMetrics, isNotEmpty);
        expect(operationMetrics.first.metadata['test'], equals('true'));
      });

      test('should dispose resources properly', () {
        // Arrange
        performanceService.initialize();

        // Act & Assert
        expect(() => performanceService.dispose(), returnsNormally);
      });

      test('should handle battery optimization settings', () {
        // Arrange
        performanceService.initialize();

        // Act & Assert
        expect(() => performanceService.setBatteryOptimization(false),
            returnsNormally);
        expect(() => performanceService.setBatteryOptimization(true),
            returnsNormally);
      });

      test('should optimize image loading settings', () {
        // Act & Assert
        expect(
            () => performanceService.optimizeImageLoading(), returnsNormally);
      });
    });
  });
}
