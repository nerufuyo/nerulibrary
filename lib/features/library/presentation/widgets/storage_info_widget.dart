import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/file_manager_providers.dart';

/// Widget displaying storage information and management options
/// 
/// Shows available and used storage space with visual indicators
/// and provides cleanup options for managing storage efficiently.
class StorageInfoWidget extends ConsumerWidget {
  const StorageInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageInfoAsync = ref.watch(storageInfoProvider);
    final storagePermissionAsync = ref.watch(storagePermissionProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Storage Management',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStorageInfo(context, storageInfoAsync),
            const SizedBox(height: 16),
            _buildPermissionInfo(context, storagePermissionAsync),
            const SizedBox(height: 16),
            _buildCleanupActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfo(BuildContext context, AsyncValue<Map<String, int>> storageInfoAsync) {
    return storageInfoAsync.when(
      data: (info) {
        final total = info['total'] ?? 1;
        final used = info['used'] ?? 0;
        final available = info['available'] ?? 0;
        final usagePercentage = total > 0 ? (used / total) : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Usage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: usagePercentage,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                usagePercentage > 0.8 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Used: ${_formatBytes(used)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Available: ${_formatBytes(available)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text(
        'Error loading storage info: $error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _buildPermissionInfo(BuildContext context, AsyncValue<bool> permissionAsync) {
    return permissionAsync.when(
      data: (hasPermission) {
        return Row(
          children: [
            Icon(
              hasPermission ? Icons.check_circle : Icons.warning,
              color: hasPermission 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(
              hasPermission 
                  ? 'Storage permissions granted' 
                  : 'Storage permissions required',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Text(
        'Permission check failed',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _buildCleanupActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cleanup Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _performCleanup(ref, 'temp'),
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Clean Temp Files'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _performCleanup(ref, 'cache'),
                icon: const Icon(Icons.cached),
                label: const Text('Clean Cache'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _performCleanup(WidgetRef ref, String type) {
    try {
      if (type == 'temp') {
        final _ = ref.refresh(cleanupTempFilesProvider);
      } else if (type == 'cache') {
        final _ = ref.refresh(cleanupCacheFilesProvider);
      }
      // Refresh storage info after cleanup
      ref.invalidate(storageInfoProvider);
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (math.log(bytes) / math.log(1024)).floor();
    final size = bytes / math.pow(1024, i);
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
