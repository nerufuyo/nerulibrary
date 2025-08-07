import 'package:dartz/dartz.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../errors/file_failures.dart';

/// File permission manager for handling file system permissions
/// 
/// Manages permission requests and checks for file operations including
/// storage access, external storage, and other file-related permissions.
class FilePermissionManager {
  /// Checks if storage permission is granted
  Future<Either<PermissionFailure, bool>> hasStoragePermission() async {
    try {
      final status = await ph.Permission.storage.status;
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to check storage permission: $e',
        requiredPermission: 'storage',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

  /// Requests storage permission from the user
  Future<Either<PermissionFailure, bool>> requestStoragePermission() async {
    try {
      final status = await ph.Permission.storage.request();
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to request storage permission: $e',
        requiredPermission: 'storage',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

  /// Checks if external storage permission is granted (Android 11+)
  Future<Either<PermissionFailure, bool>> hasManageExternalStoragePermission() async {
    try {
      final status = await ph.Permission.manageExternalStorage.status;
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to check manage external storage permission: $e',
        requiredPermission: 'manageExternalStorage',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

  /// Requests external storage management permission (Android 11+)
  Future<Either<PermissionFailure, bool>> requestManageExternalStoragePermission() async {
    try {
      final status = await ph.Permission.manageExternalStorage.request();
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to request manage external storage permission: $e',
        requiredPermission: 'manageExternalStorage',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

  /// Checks all required file permissions
  Future<Either<PermissionFailure, Map<String, bool>>> checkAllFilePermissions() async {
    try {
      final results = <String, bool>{};
      
      // Check storage permission
      final storageResult = await hasStoragePermission();
      storageResult.fold(
        (failure) => results['storage'] = false,
        (granted) => results['storage'] = granted,
      );

      // Check external storage permission (Android 11+)
      final externalStorageResult = await hasManageExternalStoragePermission();
      externalStorageResult.fold(
        (failure) => results['manageExternalStorage'] = false,
        (granted) => results['manageExternalStorage'] = granted,
      );

      return Right(results);
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to check file permissions: $e',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

  /// Requests all required file permissions
  Future<Either<PermissionFailure, Map<String, bool>>> requestAllFilePermissions() async {
    try {
      final results = <String, bool>{};
      
      // Request storage permission first
      final storageResult = await requestStoragePermission();
      storageResult.fold(
        (failure) => results['storage'] = false,
        (granted) => results['storage'] = granted,
      );

      // Request external storage permission if needed (Android 11+)
      if (results['storage'] == true) {
        final externalStorageResult = await requestManageExternalStoragePermission();
        externalStorageResult.fold(
          (failure) => results['manageExternalStorage'] = false,
          (granted) => results['manageExternalStorage'] = granted,
        );
      }

      return Right(results);
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to request file permissions: $e',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

  /// Ensures all required permissions are granted before file operations
  Future<Either<PermissionFailure, bool>> ensureFilePermissions() async {
    try {
      // Check current permissions
      final checkResult = await checkAllFilePermissions();
      
      return checkResult.fold(
        (failure) => Left(failure),
        (permissions) async {
          // If all permissions are granted, return success
          final allGranted = permissions.values.every((granted) => granted);
          if (allGranted) {
            return const Right(true);
          }

          // Request missing permissions
          final requestResult = await requestAllFilePermissions();
          return requestResult.fold(
            (failure) => Left(failure),
            (newPermissions) {
              final allNewGranted = newPermissions.values.every((granted) => granted);
              if (!allNewGranted) {
                return Left(PermissionFailure(
                  message: 'Required file permissions were not granted',
                  currentStatus: PermissionStatus.denied,
                ));
              }
              return const Right(true);
            },
          );
        },
      );
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to ensure file permissions: $e',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

    /// Opens the app settings page for the user to manually grant permissions
  Future<Either<PermissionFailure, bool>> openAppSettings() async {
    try {
      final opened = await ph.openAppSettings();
      return Right(opened);
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to open app settings: $e',
        requiredPermission: 'settings',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

  /// Checks storage permission status
  Future<Either<PermissionFailure, PermissionStatus>> checkStoragePermission() async {
    try {
      final status = await ph.Permission.storage.status;
      return Right(_mapPermissionStatus(status));
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to check storage permission: $e',
        requiredPermission: 'storage',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

  /// Checks external storage permission status
  Future<Either<PermissionFailure, PermissionStatus>> checkExternalStoragePermission() async {
    try {
      final status = await ph.Permission.manageExternalStorage.status;
      return Right(_mapPermissionStatus(status));
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to check external storage permission: $e',
        requiredPermission: 'externalStorage',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

  /// Checks if permission is permanently denied
  Future<Either<PermissionFailure, bool>> isPermissionPermanentlyDenied(
    ph.Permission permission,
  ) async {
    try {
      final status = await permission.status;
      return Right(status.isPermanentlyDenied);
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to check permission status: $e',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

  /// Gets the current status of a specific permission
  Future<Either<PermissionFailure, PermissionStatus>> getPermissionStatus(
    ph.Permission permission,
  ) async {
    try {
      final status = await permission.status;
      final mappedStatus = _mapPermissionStatus(status);
      return Right(mappedStatus);
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to get permission status: $e',
        currentStatus: PermissionStatus.unknown,
      ));
    }
  }

  /// Maps permission_handler status to our internal status
  PermissionStatus _mapPermissionStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return PermissionStatus.denied;
      case ph.PermissionStatus.restricted:
        return PermissionStatus.restricted;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      default:
        return PermissionStatus.unknown;
    }
  }

  /// Provides user-friendly permission rationale
  String getPermissionRationale(String permission) {
    switch (permission) {
      case 'storage':
        return 'Storage permission is required to download and save books to your device.';
      case 'manageExternalStorage':
        return 'External storage access is required to manage book files on newer Android versions.';
      default:
        return 'This permission is required for the app to function properly.';
    }
  }

  /// Gets the action needed for a permission status
  String getPermissionAction(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission is already granted.';
      case PermissionStatus.denied:
        return 'Please grant the permission when prompted.';
      case PermissionStatus.restricted:
        return 'Permission is restricted. Please contact your device administrator.';
      case PermissionStatus.permanentlyDenied:
        return 'Permission was permanently denied. Please enable it in app settings.';
      case PermissionStatus.unknown:
        return 'Permission status is unknown. Please try again.';
    }
  }
}
