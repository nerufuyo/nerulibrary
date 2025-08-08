import 'package:flutter_test/flutter_test.dart';
import 'package:nerulibrary/core/startup/app_startup_manager.dart';

void main() {
  // Initialize Flutter test binding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppStartupManager', () {
    late AppStartupManager appStartupManager;

    setUp(() {
      appStartupManager = AppStartupManager.instance;
    });

    group('Singleton Pattern', () {
      test('should return same instance when accessed multiple times', () {
        // Arrange & Act
        final instance1 = AppStartupManager.instance;
        final instance2 = AppStartupManager.instance;

        // Assert
        expect(instance1, equals(instance2));
        expect(identical(instance1, instance2), isTrue);
      });

      test(
          'should maintain singleton behavior across different access patterns',
          () {
        // Arrange & Act
        final directAccess = AppStartupManager.instance;
        final assignedInstance = AppStartupManager.instance;
        final multipleAccess = AppStartupManager.instance;

        // Assert
        expect(directAccess, equals(assignedInstance));
        expect(assignedInstance, equals(multipleAccess));
        expect(identical(directAccess, multipleAccess), isTrue);
      });
    });

    group('Initialization State', () {
      test('should start with uninitialized state', () {
        // Act & Assert
        expect(appStartupManager.isInitialized, isFalse);
      });

      test('should provide initialization future', () {
        // Act
        final initFuture = appStartupManager.initialized;

        // Assert
        expect(initFuture, isA<Future<void>>());
      });

      test(
          'should throw StateError when accessing sharedPreferences before init',
          () {
        // Act & Assert
        expect(() => appStartupManager.sharedPreferences,
            throwsA(isA<StateError>()));
      });
    });

    group('Utility Methods', () {
      test('allowFirstFrame should execute without errors', () {
        // Act & Assert
        expect(() => appStartupManager.allowFirstFrame(), returnsNormally);
      });
    });
  });
}
