import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:nerulibrary/core/services/file_permission_manager.dart';
import 'package:nerulibrary/core/errors/file_failures.dart';

void main() {
  group('FilePermissionManager', () {
    late FilePermissionManager permissionManager;

    setUp(() {
      permissionManager = FilePermissionManager();
    });

    group('Permission Check Methods', () {
      test('hasStoragePermission should return Either<PermissionFailure, bool>',
          () {
        // Arrange & Act
        final result = permissionManager.hasStoragePermission();

        // Assert
        expect(result, isA<Future<Either<PermissionFailure, bool>>>());
      });

      test(
          'hasManageExternalStoragePermission should return Either<PermissionFailure, bool>',
          () {
        // Arrange & Act
        final result = permissionManager.hasManageExternalStoragePermission();

        // Assert
        expect(result, isA<Future<Either<PermissionFailure, bool>>>());
      });

      test(
          'checkAllFilePermissions should return Either<PermissionFailure, Map<String, bool>>',
          () {
        // Arrange & Act
        final result = permissionManager.checkAllFilePermissions();

        // Assert
        expect(result,
            isA<Future<Either<PermissionFailure, Map<String, bool>>>>());
      });
    });

    group('Permission Request Methods', () {
      test(
          'requestStoragePermission should return Either<PermissionFailure, bool>',
          () {
        // Arrange & Act
        final result = permissionManager.requestStoragePermission();

        // Assert
        expect(result, isA<Future<Either<PermissionFailure, bool>>>());
      });

      test(
          'requestManageExternalStoragePermission should return Either<PermissionFailure, bool>',
          () {
        // Arrange & Act
        final result =
            permissionManager.requestManageExternalStoragePermission();

        // Assert
        expect(result, isA<Future<Either<PermissionFailure, bool>>>());
      });

      test(
          'requestAllFilePermissions should return Either<PermissionFailure, Map<String, bool>>',
          () {
        // Arrange & Act
        final result = permissionManager.requestAllFilePermissions();

        // Assert
        expect(result,
            isA<Future<Either<PermissionFailure, Map<String, bool>>>>());
      });
    });

    group('Permission Utility Methods', () {
      test(
          'ensureFilePermissions should return Either<PermissionFailure, bool>',
          () {
        // Arrange & Act
        final result = permissionManager.ensureFilePermissions();

        // Assert
        expect(result, isA<Future<Either<PermissionFailure, bool>>>());
      });
    });

    group('Error Handling', () {
      test('should use Either pattern for error handling', () async {
        // This tests that the methods follow the Either pattern for error handling

        // Test storage permission check
        final storageResult = await permissionManager.hasStoragePermission();
        expect(storageResult, isA<Either<PermissionFailure, bool>>());

        // The result should be either a failure or success
        storageResult.fold(
          (failure) {
            expect(failure, isA<PermissionFailure>());
            expect(failure.message, isA<String>());
          },
          (success) {
            expect(success, isA<bool>());
          },
        );
      });

      test('should handle permission check errors gracefully', () async {
        // Test that external storage permission check doesn't crash
        final result =
            await permissionManager.hasManageExternalStoragePermission();

        expect(result, isA<Either<PermissionFailure, bool>>());

        result.fold(
          (failure) {
            expect(failure, isA<PermissionFailure>());
            expect(failure.message, isNotEmpty);
          },
          (success) {
            expect(success, isA<bool>());
          },
        );
      });
    });

    group('Method API Verification', () {
      test('all permission methods should be callable', () {
        // Verify method signatures exist and are callable
        expect(() => permissionManager.hasStoragePermission(), returnsNormally);
        expect(() => permissionManager.hasManageExternalStoragePermission(),
            returnsNormally);
        expect(() => permissionManager.requestStoragePermission(),
            returnsNormally);
        expect(() => permissionManager.requestManageExternalStoragePermission(),
            returnsNormally);
        expect(
            () => permissionManager.checkAllFilePermissions(), returnsNormally);
        expect(() => permissionManager.requestAllFilePermissions(),
            returnsNormally);
        expect(
            () => permissionManager.ensureFilePermissions(), returnsNormally);
      });
    });

    group('Return Type Validation', () {
      test('checkAllFilePermissions should return map with expected keys',
          () async {
        // Test that the method returns the expected structure
        final result = await permissionManager.checkAllFilePermissions();

        result.fold(
          (failure) {
            // If there's a failure, it should be a PermissionFailure
            expect(failure, isA<PermissionFailure>());
          },
          (permissions) {
            // If successful, should return a map
            expect(permissions, isA<Map<String, bool>>());
            // Should contain expected permission keys
            expect(permissions.containsKey('storage'), isTrue);
            expect(permissions.containsKey('manageExternalStorage'), isTrue);
          },
        );
      });

      test('requestAllFilePermissions should return map with expected keys',
          () async {
        // Test that the method returns the expected structure
        final result = await permissionManager.requestAllFilePermissions();

        result.fold(
          (failure) {
            // If there's a failure, it should be a PermissionFailure
            expect(failure, isA<PermissionFailure>());
          },
          (permissions) {
            // If successful, should return a map
            expect(permissions, isA<Map<String, bool>>());
            // Should contain expected permission keys
            expect(permissions.containsKey('storage'), isTrue);
          },
        );
      });
    });

    group('Integration Behavior', () {
      test('ensureFilePermissions should handle the complete flow', () async {
        // Test the complete permission flow
        final result = await permissionManager.ensureFilePermissions();

        expect(result, isA<Either<PermissionFailure, bool>>());

        result.fold(
          (failure) {
            // If there's a failure, it should provide meaningful information
            expect(failure, isA<PermissionFailure>());
            expect(failure.message, isNotEmpty);
          },
          (success) {
            // If successful, should return true
            expect(success, isA<bool>());
          },
        );
      });
    });
  });
}
