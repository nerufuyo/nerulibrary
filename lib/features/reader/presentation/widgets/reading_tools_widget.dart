import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reading_tools_providers.dart';

/// Widget for managing reading tools (bookmarks, highlights, progress)
/// 
/// Provides a tabbed interface for accessing all reading tools
/// with bookmark management, highlight tools, and progress tracking.
class ReadingToolsWidget extends ConsumerStatefulWidget {
  final String bookId;

  const ReadingToolsWidget({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<ReadingToolsWidget> createState() => _ReadingToolsWidgetState();
}

class _ReadingToolsWidgetState extends ConsumerState<ReadingToolsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = ref.watch(bookmarkNotifierProvider(widget.bookId));
    final position = ref.watch(readingPositionNotifierProvider(widget.bookId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.bookmark), text: 'Bookmarks'),
              Tab(icon: Icon(Icons.highlight), text: 'Highlights'),
              Tab(icon: Icon(Icons.track_changes), text: 'Progress'),
            ],
          ),
          
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookmarksTab(bookmarks),
                _buildHighlightsTab(),
                _buildProgressTab(position),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab(AsyncValue<List> bookmarks) {
    return bookmarks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (bookmarkList) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookmarkList.length,
        itemBuilder: (context, index) {
          // TODO: Implement bookmark list item
          return ListTile(
            leading: const Icon(Icons.bookmark),
            title: Text('Bookmark ${index + 1}'),
            subtitle: const Text('Page placeholder'),
          );
        },
      ),
    );
  }

  Widget _buildHighlightsTab() {
    return const Center(
      child: Text(
        'Highlights\nImplementation pending',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildProgressTab(AsyncValue position) {
    return position.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (positionData) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Reading Progress',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: 0.0, // TODO: Calculate actual progress
                      backgroundColor: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    const Text('0% Complete'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
