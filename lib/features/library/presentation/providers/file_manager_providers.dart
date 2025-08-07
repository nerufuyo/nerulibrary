import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/file_permission_manager.dart';
import '../../../library/data/services/file_manager_service_impl.dart';
import '../../../library/domain/services/file_manager_service.dart';

/// Provider for Dio HTTP client used for file downloads
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  
  // Configure default options
  dio.options = BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'User-Agent': 'NeruLibrary/1.0',
    },
  );
  
  // Add interceptors for logging and error handling
  dio.interceptors.add(LogInterceptor(
    requestBody: false,
    responseBody: false,
    error: true,
  ));
  
  return dio;
});

/// Provider for file permissions manager
final filePermissionManagerProvider = Provider<FilePermissionManager>((ref) {
  return FilePermissionManager();
});

/// Provider for the file manager service implementation
final fileManagerServiceProvider = Provider<FileManagerService>((ref) {
  final dio = ref.watch(dioProvider);
  final permissionManager = ref.watch(filePermissionManagerProvider);
  
  return FileManagerServiceImpl(
    dio: dio,
    permissionManager: permissionManager,
  );
});

/// Provider for watching download progress of a specific download
final downloadProgressProvider = StreamProvider.family<double, String>((ref, downloadId) {
  final fileManager = ref.watch(fileManagerServiceProvider);
  
  // Create a stream that emits download progress updates
  return Stream.periodic(const Duration(milliseconds: 500), (count) async {
    final statusResult = await fileManager.getDownloadStatus(downloadId);
    return statusResult.fold((failure) => 0.0, (downloadItem) => downloadItem.progress);
  }).asyncMap((future) => future);
});

/// Provider for all downloads
final allDownloadsProvider = FutureProvider<List<dynamic>>((ref) async {
  final fileManager = ref.watch(fileManagerServiceProvider);
  final result = await fileManager.getAllDownloads();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (downloads) => downloads,
  );
});

/// Provider for download statistics
final downloadStatisticsProvider = FutureProvider<dynamic>((ref) async {
  final fileManager = ref.watch(fileManagerServiceProvider);
  final result = await fileManager.getDownloadStatistics();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (stats) => stats,
  );
});

/// Provider for storage information
final storageInfoProvider = FutureProvider<Map<String, int>>((ref) async {
  final fileManager = ref.watch(fileManagerServiceProvider);
  final availableResult = await fileManager.getAvailableStorageSpace();
  final usedResult = await fileManager.getUsedStorageSpace();
  
  final availableSpace = availableResult.fold((failure) => 0, (space) => space);
  final usedSpace = usedResult.fold((failure) => 0, (space) => space);
  
  return {
    'available': availableSpace,
    'used': usedSpace,
    'total': availableSpace + usedSpace,
  };
});

/// Provider for cleaning temporary files
final cleanupTempFilesProvider = FutureProvider<dynamic>((ref) async {
  final fileManager = ref.watch(fileManagerServiceProvider);
  final result = await fileManager.cleanupTemporaryFiles();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (result) => result,
  );
});

/// Provider for cleaning cache files
final cleanupCacheFilesProvider = FutureProvider<dynamic>((ref) async {
  final fileManager = ref.watch(fileManagerServiceProvider);
  final result = await fileManager.cleanupCachedFiles();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (result) => result,
  );
});

/// Provider for watching storage space changes
final storageSpaceProvider = StreamProvider<int>((ref) {
  return Stream.periodic(
    const Duration(seconds: 30),
    (count) async {
      final fileManager = ref.read(fileManagerServiceProvider);
      final result = await fileManager.getAvailableStorageSpace();
      return result.fold((failure) => 0, (space) => space);
    },
  ).asyncMap((future) => future);
});

/// Provider for file permission status
final storagePermissionProvider = FutureProvider<bool>((ref) async {
  final permissionManager = ref.watch(filePermissionManagerProvider);
  final result = await permissionManager.hasStoragePermission();
  return result.fold(
    (failure) => false,
    (hasPermission) => hasPermission,
  );
});

/// Provider for external storage permission status
final externalStoragePermissionProvider = FutureProvider<bool>((ref) async {
  final permissionManager = ref.watch(filePermissionManagerProvider);
  final result = await permissionManager.hasManageExternalStoragePermission();
  return result.fold(
    (failure) => false,
    (hasPermission) => hasPermission,
  );
});
