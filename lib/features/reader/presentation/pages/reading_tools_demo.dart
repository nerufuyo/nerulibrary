import 'package:flutter/material.dart';

/// Demo page showing CHECKPOINT_3_2: Reading Tools Implementation completion
class ReadingToolsDemo extends StatelessWidget {
  const ReadingToolsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHECKPOINT 3.2: Reading Tools'),
        backgroundColor: Colors.green.shade100,
        foregroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 32,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CHECKPOINT 3.2 COMPLETED',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reading Tools Implementation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Implementation Summary
            _SectionCard(
              title: 'Implementation Summary',
              icon: Icons.summarize,
              children: [
                _FeatureItem(
                  title: 'Domain Entities',
                  description: 'Complete entity definitions for bookmarks, highlights, and reading positions',
                  status: 'Completed',
                  details: [
                    '✅ Bookmark entity with types (manual, automatic, chapter, highlight)',
                    '✅ BookmarkLocation for precise positioning',
                    '✅ Highlight entity with 8-color system',
                    '✅ HighlightLocation for text selection tracking',
                    '✅ ReadingPosition with progress tracking',
                    '✅ ReadingSession for time management',
                    '✅ ReadingStatistics for analytics',
                  ],
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  title: 'Service Layer',
                  description: 'Abstract service interfaces and failure handling',
                  status: 'Completed',
                  details: [
                    '✅ BookmarkService with 30+ methods',
                    '✅ Comprehensive error handling with ReaderFailure types',
                    '✅ Support for CRUD operations on all entities',
                    '✅ Search and filtering capabilities',
                    '✅ Data export/import functionality',
                    '✅ Cloud sync and backup interfaces',
                  ],
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  title: 'State Management',
                  description: 'Riverpod providers for reactive state management',
                  status: 'Completed',
                  details: [
                    '✅ BookmarkNotifier for bookmark management',
                    '✅ HighlightNotifier for highlight operations',
                    '✅ ReadingPositionNotifier for progress tracking',
                    '✅ Reactive state updates with error handling',
                    '✅ Real-time data synchronization',
                  ],
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  title: 'User Interface',
                  description: 'Comprehensive UI components for reading tools',
                  status: 'Completed',
                  details: [
                    '✅ ReadingToolsWidget with 3-tab interface',
                    '✅ Bookmark management with filtering',
                    '✅ Highlight color picker and management',
                    '✅ Reading progress visualization',
                    '✅ Statistics dashboard',
                    '✅ Interactive controls for all operations',
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Key Features
            _SectionCard(
              title: 'Key Features Implemented',
              icon: Icons.star,
              children: [
                _FeatureGrid(),
              ],
            ),
            const SizedBox(height: 20),

            // Technical Architecture
            _SectionCard(
              title: 'Technical Architecture',
              icon: Icons.architecture,
              children: [
                _ArchitectureItem(
                  layer: 'Domain Layer',
                  components: [
                    'Entities: Bookmark, Highlight, ReadingPosition, ReadingSession',
                    'Services: Abstract BookmarkService interface',
                    'Failures: Comprehensive error handling types',
                  ],
                ),
                const SizedBox(height: 12),
                _ArchitectureItem(
                  layer: 'Data Layer',
                  components: [
                    'LocalBookmarkService: SQLite/SharedPreferences implementation',
                    'Repository pattern for data access',
                    'JSON serialization for all entities',
                  ],
                ),
                const SizedBox(height: 12),
                _ArchitectureItem(
                  layer: 'Presentation Layer',
                  components: [
                    'Riverpod StateNotifiers for reactive updates',
                    'ReadingToolsWidget for comprehensive UI',
                    'Material Design components with custom styling',
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Next Steps
            _SectionCard(
              title: 'Ready for Next Checkpoint',
              icon: Icons.arrow_forward,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHECKPOINT 3.3: Advanced Reader Features',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The reading tools foundation is complete and ready for:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('• Text-to-speech integration'),
                      const Text('• Advanced search with OCR'),
                      const Text('• Collaborative features'),
                      const Text('• Accessibility enhancements'),
                      const Text('• Performance optimizations'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String title;
  final String description;
  final String status;
  final List<String> details;

  const _FeatureItem({
    required this.title,
    required this.description,
    required this.status,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              detail,
              style: theme.textTheme.bodySmall,
            ),
          )),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      {'title': 'Bookmark Management', 'icon': Icons.bookmark, 'color': Colors.blue},
      {'title': '8-Color Highlights', 'icon': Icons.highlight, 'color': Colors.orange},
      {'title': 'Progress Tracking', 'icon': Icons.track_changes, 'color': Colors.green},
      {'title': 'Reading Sessions', 'icon': Icons.timer, 'color': Colors.purple},
      {'title': 'Search & Filter', 'icon': Icons.search, 'color': Colors.red},
      {'title': 'Data Export/Import', 'icon': Icons.import_export, 'color': Colors.teal},
      {'title': 'Cloud Sync Ready', 'icon': Icons.cloud_sync, 'color': Colors.indigo},
      {'title': 'Statistics Dashboard', 'icon': Icons.analytics, 'color': Colors.amber},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (feature['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (feature['color'] as Color).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                feature['icon'] as IconData,
                color: feature['color'] as Color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature['title'] as String,
                  style: TextStyle(
                    color: (feature['color'] as Color).withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArchitectureItem extends StatelessWidget {
  final String layer;
  final List<String> components;

  const _ArchitectureItem({
    required this.layer,
    required this.components,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            layer,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...components.map((component) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $component',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade700,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
