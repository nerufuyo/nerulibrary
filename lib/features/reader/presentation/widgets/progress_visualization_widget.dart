import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reading_progress.dart';
import '../../domain/entities/reading_statistics.dart';
import '../../domain/entities/reading_session.dart';

/// Progress visualization widget that shows reading progress in various formats
///
/// Supports linear progress bars, circular progress indicators,
/// and detailed progress statistics with customizable themes.
class ProgressVisualizationWidget extends ConsumerWidget {
  /// Reading progress to display
  final ReadingProgress progress;

  /// Overall reading statistics
  final ReadingStatistics? statistics;

  /// Recent reading sessions for velocity calculation
  final List<ReadingSession>? recentSessions;

  /// Visualization style
  final ProgressVisualizationStyle style;

  /// Whether to show detailed information
  final bool showDetails;

  /// Custom color scheme
  final ProgressColorScheme? colorScheme;

  const ProgressVisualizationWidget({
    super.key,
    required this.progress,
    this.statistics,
    this.recentSessions,
    this.style = ProgressVisualizationStyle.linear,
    this.showDetails = true,
    this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = colorScheme ?? ProgressColorScheme.fromTheme(theme);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, colors),
            const SizedBox(height: 16),
            _buildProgressIndicator(context, colors),
            if (showDetails) ...[
              const SizedBox(height: 16),
              _buildProgressDetails(context, colors),
            ],
            if (statistics != null) ...[
              const SizedBox(height: 16),
              _buildStatistics(context, colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProgressColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Reading Progress',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
        ),
        Text(
          '${progress.progressPercentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.accent,
              ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(
      BuildContext context, ProgressColorScheme colors) {
    switch (style) {
      case ProgressVisualizationStyle.linear:
        return _buildLinearProgress(context, colors);
      case ProgressVisualizationStyle.circular:
        return _buildCircularProgress(context, colors);
      case ProgressVisualizationStyle.arc:
        return _buildArcProgress(context, colors);
      case ProgressVisualizationStyle.segmented:
        return _buildSegmentedProgress(context, colors);
    }
  }

  Widget _buildLinearProgress(
      BuildContext context, ProgressColorScheme colors) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress.progressFraction,
          backgroundColor: colors.background,
          valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          minHeight: 8.0,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page ${progress.currentPage}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                  ),
            ),
            Text(
              '${progress.pagesRemaining} pages left',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularProgress(
      BuildContext context, ProgressColorScheme colors) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          children: [
            CircularProgressIndicator(
              value: progress.progressFraction,
              strokeWidth: 8.0,
              backgroundColor: colors.background,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${progress.progressPercentage.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                  ),
                  Text(
                    '${progress.currentPage}/${progress.totalPages}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.secondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArcProgress(BuildContext context, ProgressColorScheme colors) {
    return SizedBox(
      height: 100,
      child: CustomPaint(
        painter: ArcProgressPainter(
          progress: progress.progressFraction,
          backgroundColor: colors.background,
          progressColor: colors.accent,
          strokeWidth: 12.0,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${progress.progressPercentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
              ),
              Text(
                'Complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.secondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedProgress(
      BuildContext context, ProgressColorScheme colors) {
    const segmentCount = 20;
    final completedSegments =
        (progress.progressFraction * segmentCount).floor();

    return Column(
      children: [
        Row(
          children: List.generate(segmentCount, (index) {
            final isCompleted = index < completedSegments;
            return Expanded(
              child: Container(
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isCompleted ? colors.accent : colors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '$completedSegments/$segmentCount segments complete',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.secondary,
              ),
        ),
      ],
    );
  }

  Widget _buildProgressDetails(
      BuildContext context, ProgressColorScheme colors) {
    return Column(
      children: [
        _buildDetailRow(
          context,
          'Current Page',
          '${progress.currentPage} of ${progress.totalPages}',
          colors,
        ),
        _buildDetailRow(
          context,
          'Pages Remaining',
          '${progress.pagesRemaining}',
          colors,
        ),
        _buildDetailRow(
          context,
          'Reading Time',
          '${progress.readingTimeHours.toStringAsFixed(1)} hours',
          colors,
        ),
        if (progress.lastPosition != null)
          _buildDetailRow(
            context,
            'Last Position',
            _formatLastPosition(progress.lastPosition!),
            colors,
          ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context, ProgressColorScheme colors) {
    if (statistics == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Statistics',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          context,
          'Reading Streak',
          '${statistics!.readingStreak} days',
          colors,
        ),
        _buildDetailRow(
          context,
          'Average Session',
          '${statistics!.averageSessionDuration.inMinutes} minutes',
          colors,
        ),
        _buildDetailRow(
          context,
          'Books Completed',
          '${statistics!.booksCompleted}',
          colors,
        ),
        if (recentSessions != null && recentSessions!.isNotEmpty)
          _buildDetailRow(
            context,
            'Reading Speed',
            '${_calculateAverageSpeed().toStringAsFixed(1)} pages/min',
            colors,
          ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    ProgressColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.secondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.primary,
                ),
          ),
        ],
      ),
    );
  }

  String _formatLastPosition(String position) {
    // Parse position string and format it nicely
    if (position.contains('page_')) {
      final pageMatch = RegExp(r'page_(\d+)').firstMatch(position);
      if (pageMatch != null) {
        return 'Page ${pageMatch.group(1)}';
      }
    }
    if (position.contains('chapter_')) {
      final chapterMatch = RegExp(r'chapter_(.+?):').firstMatch(position);
      if (chapterMatch != null) {
        return 'Chapter ${chapterMatch.group(1)}';
      }
    }
    return 'Unknown position';
  }

  double _calculateAverageSpeed() {
    if (recentSessions == null || recentSessions!.isEmpty) return 0.0;

    final totalSpeed = recentSessions!
        .fold(0.0, (sum, session) => sum + session.readingSpeedPagesPerMinute);

    return totalSpeed / recentSessions!.length;
  }
}

/// Custom painter for arc-style progress indicator
class ArcProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  ArcProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 * 0.75, // Start from top-left
      3.14159 * 1.5, // Sweep 270 degrees
      false,
      backgroundPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 * 0.75, // Start from top-left
      3.14159 * 1.5 * progress, // Sweep based on progress
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is ArcProgressPainter &&
        (oldDelegate.progress != progress ||
            oldDelegate.backgroundColor != backgroundColor ||
            oldDelegate.progressColor != progressColor ||
            oldDelegate.strokeWidth != strokeWidth);
  }
}

/// Progress visualization styles
enum ProgressVisualizationStyle {
  /// Linear progress bar
  linear,

  /// Circular progress indicator
  circular,

  /// Arc-style progress
  arc,

  /// Segmented progress bar
  segmented,
}

/// Color scheme for progress visualization
class ProgressColorScheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color success;
  final Color warning;

  const ProgressColorScheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.success,
    required this.warning,
  });

  factory ProgressColorScheme.fromTheme(ThemeData theme) {
    return ProgressColorScheme(
      primary: theme.colorScheme.primary,
      secondary: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      accent: theme.colorScheme.secondary,
      background: theme.colorScheme.surfaceContainerHighest,
      success: Colors.green,
      warning: Colors.orange,
    );
  }

  factory ProgressColorScheme.light() {
    return const ProgressColorScheme(
      primary: Color(0xFF1976D2),
      secondary: Color(0xFF757575),
      accent: Color(0xFF2196F3),
      background: Color(0xFFE3F2FD),
      success: Color(0xFF4CAF50),
      warning: Color(0xFFFF9800),
    );
  }

  factory ProgressColorScheme.dark() {
    return const ProgressColorScheme(
      primary: Color(0xFF90CAF9),
      secondary: Color(0xFFBDBDBD),
      accent: Color(0xFF64B5F6),
      background: Color(0xFF1E3A8A),
      success: Color(0xFF81C784),
      warning: Color(0xFFFFB74D),
    );
  }
}
