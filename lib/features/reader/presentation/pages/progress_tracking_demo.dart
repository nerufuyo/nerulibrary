import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/progress_visualization_widget.dart';
import '../providers/progress_tracking_providers.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/entities/reading_statistics.dart';
import '../../domain/entities/reading_session.dart';

/// Demo page for progress tracking features
///
/// Showcases all progress tracking components including:
/// - Progress visualization in different styles
/// - Reading session management
/// - Statistics tracking
/// - Time estimation
class ProgressTrackingDemo extends ConsumerStatefulWidget {
  const ProgressTrackingDemo({super.key});

  @override
  ConsumerState<ProgressTrackingDemo> createState() =>
      _ProgressTrackingDemoState();
}

class _ProgressTrackingDemoState extends ConsumerState<ProgressTrackingDemo>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Demo data
  final String demoBookId = 'demo_book_123';
  final String demoUserId = 'demo_user_456';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize demo data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDemoData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeDemoData() {
    // Load demo statistics
    ref.read(readingStatisticsProvider.notifier).loadStatistics(demoUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking Demo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
            Tab(text: 'Session', icon: Icon(Icons.timer)),
            Tab(text: 'Statistics', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Visualization', icon: Icon(Icons.pie_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProgressTab(),
          _buildSessionTab(),
          _buildStatisticsTab(),
          _buildVisualizationTab(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    final progressState = ref.watch(progressTrackingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Reading Progress Management'),
          const SizedBox(height: 16),

          // Demo progress creation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Demo Progress',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _createDemoProgress(25.0),
                          child: const Text('25% Progress'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _createDemoProgress(50.0),
                          child: const Text('50% Progress'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _createDemoProgress(75.0),
                          child: const Text('75% Progress'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Current progress display
          progressState.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stackTrace) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.error,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 8),
                    Text('Error: ${error.toString()}'),
                  ],
                ),
              ),
            ),
            data: (progress) => progress != null
                ? _buildProgressCard(progress)
                : const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                          'No progress data available. Create demo progress above.'),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Progress sync demo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cross-Format Sync',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Sync progress between PDF and EPUB versions of the same book.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _demonstrateSyncAcrossFormats,
                    child: const Text('Demo Format Sync'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTab() {
    final currentSession = ref.watch(currentSessionProvider);
    final isReading = ref.watch(isCurrentlyReadingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Reading Session Management'),
          const SizedBox(height: 16),

          // Session controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Controls',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isReading ? null : _startReadingSession,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Session'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isReading ? _pauseReadingSession : null,
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isReading ? _endReadingSession : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Current session info
          if (currentSession != null) _buildCurrentSessionCard(currentSession),

          const SizedBox(height: 16),

          // Session history
          _buildSessionHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final statisticsState = ref.watch(readingStatisticsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Reading Statistics'),
          const SizedBox(height: 16),
          statisticsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading statistics: ${error.toString()}'),
              ),
            ),
            data: (statistics) => Column(
              children: [
                _buildStatisticsCard(statistics),
                const SizedBox(height: 16),
                _buildGoalsCard(statistics),
                const SizedBox(height: 16),
                _buildVelocityCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationTab() {
    final progressState = ref.watch(progressTrackingProvider);
    final statisticsState = ref.watch(readingStatisticsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Progress Visualization'),
          const SizedBox(height: 16),
          progressState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${error.toString()}'),
              ),
            ),
            data: (progress) {
              if (progress == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                        'No progress to visualize. Go to Progress tab to create demo data.'),
                  ),
                );
              }

              return statisticsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    _buildVisualizationCards(progress, null),
                data: (statistics) =>
                    _buildVisualizationCards(progress, statistics),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationCards(
      ReadingProgress progress, ReadingStatistics? statistics) {
    return Column(
      children: [
        // Linear progress
        ProgressVisualizationWidget(
          progress: progress,
          statistics: statistics,
          style: ProgressVisualizationStyle.linear,
        ),
        const SizedBox(height: 16),

        // Circular progress
        ProgressVisualizationWidget(
          progress: progress,
          statistics: statistics,
          style: ProgressVisualizationStyle.circular,
        ),
        const SizedBox(height: 16),

        // Arc progress
        ProgressVisualizationWidget(
          progress: progress,
          statistics: statistics,
          style: ProgressVisualizationStyle.arc,
        ),
        const SizedBox(height: 16),

        // Segmented progress
        ProgressVisualizationWidget(
          progress: progress,
          statistics: statistics,
          style: ProgressVisualizationStyle.segmented,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildProgressCard(ReadingProgress progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.progressFraction,
              minHeight: 8.0,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Page ${progress.currentPage} of ${progress.totalPages}'),
                Text('${progress.progressPercentage.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
                'Reading Time: ${progress.readingTimeHours.toStringAsFixed(1)} hours'),
            Text('Pages Remaining: ${progress.pagesRemaining}'),
            if (progress.lastPosition != null)
              Text('Last Position: ${progress.lastPosition}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSessionCard(ReadingSession session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Session',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text('Started: ${_formatTime(session.startTime)}'),
            Text('Duration: ${_formatDuration(session.duration)}'),
            Text('Starting Page: ${session.startPage}'),
            Text('Device: ${session.deviceType}'),
            Text('Format: ${session.bookFormat}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
                'Session history will be loaded from database in real implementation.'),
            ElevatedButton(
              onPressed: () {
                // Demo: Show sessions for book
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loading session history...')),
                );
              },
              child: const Text('Load Session History'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(ReadingStatistics statistics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Sessions', '${statistics.totalSessions}'),
            _buildStatRow('Total Reading Time',
                '${statistics.totalReadingTime.inHours}h ${statistics.totalReadingTime.inMinutes % 60}m'),
            _buildStatRow('Pages Read', '${statistics.totalPagesRead}'),
            _buildStatRow('Books Completed', '${statistics.booksCompleted}'),
            _buildStatRow('Reading Streak', '${statistics.readingStreak} days'),
            _buildStatRow('Average Session',
                '${statistics.averageSessionDuration.inMinutes} minutes'),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard(ReadingStatistics statistics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Goals',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (statistics.dailyGoalMinutes != null) ...[
              Text('Daily Goal: ${statistics.dailyGoalMinutes} minutes'),
              Text('Goal Met: ${statistics.isDailyGoalMet ? 'Yes' : 'No'}'),
            ] else
              const Text('No daily goal set'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setDailyGoal(30),
                    child: const Text('Set 30min Goal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setDailyGoal(60),
                    child: const Text('Set 60min Goal'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVelocityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Velocity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final velocityAsync =
                    ref.watch(userReadingVelocityProvider(demoUserId));
                return velocityAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => Text('Error: $error'),
                  data: (velocity) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Current Velocity: ${velocity.toStringAsFixed(2)} pages/minute'),
                      const SizedBox(height: 8),
                      Text(_interpretVelocity(velocity)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _createDemoProgress(double progressPercentage) {
    final totalPages = 300;
    final currentPage = ((progressPercentage / 100.0) * totalPages).round();

    ref.read(progressTrackingProvider.notifier).updateProgress(
      bookId: demoBookId,
      bookFormat: 'pdf',
      positionData: {
        'currentPage': currentPage,
        'readingTimeMinutes':
            (progressPercentage * 2).round(), // 2 minutes per percent
      },
      bookMetadata: {
        'totalPages': totalPages,
      },
    );
  }

  void _startReadingSession() {
    ref.read(progressTrackingProvider.notifier).startReadingSession(
      bookId: demoBookId,
      userId: demoUserId,
      startPage: 1,
      startProgressPercentage: 0.0,
      deviceType: 'mobile',
      bookFormat: 'pdf',
      metadata: {'demo': true},
    );
  }

  void _pauseReadingSession() {
    ref.read(progressTrackingProvider.notifier).pauseSession();
  }

  void _endReadingSession() {
    ref.read(progressTrackingProvider.notifier).endReadingSession(
          endPage: 10,
          endProgressPercentage: 3.33,
        );
  }

  void _demonstrateSyncAcrossFormats() {
    // Demo: Create multiple progress records and sync them
    final pdfProgress = ReadingProgress(
      id: 'pdf_progress',
      bookId: demoBookId,
      currentPage: 150,
      totalPages: 300,
      progressPercentage: 50.0,
      readingTimeMinutes: 120,
      lastPosition: 'pdf:page_150',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    final epubProgress = ReadingProgress(
      id: 'epub_progress',
      bookId: demoBookId,
      currentPage: 80,
      totalPages: 200,
      progressPercentage: 40.0,
      readingTimeMinutes: 100,
      lastPosition: 'epub:chapter_8:progress_0.20',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

    ref.read(progressTrackingProvider.notifier).syncProgressAcrossFormats(
      bookId: demoBookId,
      progressRecords: [pdfProgress, epubProgress],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Synchronized progress across PDF and EPUB formats')),
    );
  }

  void _setDailyGoal(int minutes) {
    ref.read(readingStatisticsProvider.notifier).updateDailyGoal(minutes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Daily goal set to $minutes minutes')),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hoursh $minutesm';
    }
    return '$minutesm';
  }

  String _interpretVelocity(double velocity) {
    if (velocity == 0.0) return 'No reading data available';
    if (velocity < 1.0) return 'Slow reader - take your time!';
    if (velocity < 2.0) return 'Average reading speed';
    if (velocity < 3.0) return 'Fast reader!';
    return 'Speed reader - impressive!';
  }
}
