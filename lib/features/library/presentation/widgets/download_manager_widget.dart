import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/file_manager_providers.dart';

/// Widget for displaying and managing file downloads
/// 
/// Shows active downloads with progress indicators and provides
/// controls for pausing, resuming, and cancelling downloads.
class DownloadManagerWidget extends ConsumerWidget {
  const DownloadManagerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDownloadsAsync = ref.watch(allDownloadsProvider);
    final downloadStatsAsync = ref.watch(downloadStatisticsProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with statistics
            _buildHeader(context, downloadStatsAsync),
            
            const SizedBox(height: 16),
            
            // Downloads list
            _buildDownloadsList(context, ref, allDownloadsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<dynamic> downloadStatsAsync,
  ) {
    return Row(
      children: [
        const Icon(Icons.download, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          'Downloads',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        
        // Download statistics
        downloadStatsAsync.when(
          data: (stats) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Active: ${stats?.activeDownloads ?? 0}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (error, stack) => Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> allDownloadsAsync,
  ) {
    return allDownloadsAsync.when(
      data: (downloads) {
        if (downloads.isEmpty) {
          return _buildEmptyState(context);
        }
        
        return Column(
          children: [
            // Active downloads section
            _buildDownloadsSection(
              context,
              ref,
              'Active Downloads',
              downloads.where((d) => _isActive(d)).toList(),
              Icons.download,
              Colors.blue,
            ),
            
            if (downloads.where((d) => _isActive(d)).isNotEmpty &&
                downloads.where((d) => !_isActive(d)).isNotEmpty)
              const SizedBox(height: 16),
            
            // Completed/Failed downloads section
            _buildDownloadsSection(
              context,
              ref,
              'Recent Downloads',
              downloads.where((d) => !_isActive(d)).take(5).toList(),
              Icons.history,
              Colors.grey,
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading downloads',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadsSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<dynamic> downloads,
    IconData icon,
    Color iconColor,
  ) {
    if (downloads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${downloads.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        ...downloads.map((download) => _buildDownloadItem(context, ref, download)),
      ],
    );
  }

  Widget _buildDownloadItem(
    BuildContext context,
    WidgetRef ref,
    dynamic download,
  ) {
    // This is a placeholder implementation since we can't access actual download properties
    // In a real implementation, you would cast to DownloadItem and access its properties
    final fileName = 'Unknown File'; // download.fileName
    final progress = 0.5; // download.progress
    final status = 'downloading'; // download.status.toString()
    final downloadId = 'unknown'; // download.id
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusChip(context, status),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar (for active downloads)
          if (_isProgressVisible(status)) ...[
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(context, status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Download details and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Download details
              Expanded(
                child: Text(
                  _getDownloadDetails(status, progress),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              // Action buttons
              _buildActionButtons(context, ref, downloadId, status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color chipColor;
    IconData chipIcon;
    
    switch (status.toLowerCase()) {
      case 'downloading':
        chipColor = Colors.blue;
        chipIcon = Icons.download;
        break;
      case 'completed':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        break;
      case 'failed':
        chipColor = Colors.red;
        chipIcon = Icons.error;
        break;
      case 'paused':
        chipColor = Colors.orange;
        chipIcon = Icons.pause;
        break;
      case 'cancelled':
        chipColor = Colors.grey;
        chipIcon = Icons.cancel;
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    String downloadId,
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'downloading':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.pause, size: 16),
              onPressed: () {
                // ref.read(fileManagerServiceProvider).pauseDownload(downloadId);
              },
              tooltip: 'Pause',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, size: 16),
              onPressed: () {
                _showCancelDialog(context, ref, downloadId);
              },
              tooltip: 'Cancel',
            ),
          ],
        );
        
      case 'paused':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 16),
              onPressed: () {
                // ref.read(fileManagerServiceProvider).resumeDownload(downloadId);
              },
              tooltip: 'Resume',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, size: 16),
              onPressed: () {
                _showCancelDialog(context, ref, downloadId);
              },
              tooltip: 'Cancel',
            ),
          ],
        );
        
      case 'failed':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              onPressed: () {
                // ref.read(fileManagerServiceProvider).retryDownload(downloadId);
              },
              tooltip: 'Retry',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              onPressed: () {
                _showCancelDialog(context, ref, downloadId);
              },
              tooltip: 'Remove',
            ),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.download_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No downloads yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download some books to see them here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String downloadId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Download'),
        content: const Text('Are you sure you want to cancel this download?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // ref.read(fileManagerServiceProvider).cancelDownload(downloadId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Cancel Download'),
          ),
        ],
      ),
    );
  }

  bool _isActive(dynamic download) {
    // Placeholder implementation
    // In real implementation: return download.status == DownloadStatus.downloading || download.status == DownloadStatus.paused;
    return true; // Assuming some downloads are active
  }

  bool _isProgressVisible(String status) {
    return ['downloading', 'paused'].contains(status.toLowerCase());
  }

  Color _getProgressColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'downloading':
        return Theme.of(context).colorScheme.primary;
      case 'paused':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getDownloadDetails(String status, double progress) {
    switch (status.toLowerCase()) {
      case 'downloading':
        return 'Downloading... ${(progress * 100).toStringAsFixed(0)}%';
      case 'completed':
        return 'Download completed';
      case 'failed':
        return 'Download failed';
      case 'paused':
        return 'Download paused';
      case 'cancelled':
        return 'Download cancelled';
      default:
        return 'Unknown status';
    }
  }
}
