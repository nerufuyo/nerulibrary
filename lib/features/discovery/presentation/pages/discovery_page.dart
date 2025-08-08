import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/discovery_providers.dart';
import '../widgets/book_search_bar.dart';
import '../widgets/book_grid_view.dart';
import '../widgets/popular_books_section.dart';
import '../widgets/api_status_card.dart';
import '../../domain/entities/api_entities.dart';

/// Main discovery page for browsing and searching books
///
/// This page demonstrates the API integration capabilities including:
/// - Book search functionality
/// - Popular books display
/// - API status monitoring
/// - Error handling and loading states
class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({super.key});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load popular books on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(popularBooksProvider.notifier).loadPopularBooks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Books'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Search', icon: Icon(Icons.search)),
            Tab(text: 'Popular', icon: Icon(Icons.trending_up)),
            Tab(text: 'API Status', icon: Icon(Icons.info)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildPopularTab(),
          _buildApiStatusTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    final searchResult = ref.watch(bookSearchProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: BookSearchBar(
            controller: _searchController,
            onSearch: (query) {
              ref.read(searchQueryProvider.notifier).updateQuery(query);
              ref.read(bookSearchProvider.notifier).searchBooks(query: query);
            },
            onClear: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).clearQuery();
              ref.read(bookSearchProvider.notifier).clearResults();
            },
          ),
        ),

        // Search results
        Expanded(
          child: searchResult.when(
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Searching Project Gutenberg...'),
                ],
              ),
            ),
            error: (error, stackTrace) => _buildErrorWidget(
              error: error.toString(),
              onRetry: () {
                if (searchQuery.isNotEmpty) {
                  ref
                      .read(bookSearchProvider.notifier)
                      .searchBooks(query: searchQuery);
                }
              },
            ),
            data: (result) {
              if (result == null) {
                return _buildEmptySearchState();
              }

              if (result.isEmpty) {
                return _buildNoResultsState(searchQuery);
              }

              return BookGridView(
                books: result.books,
                onBookTap: (book) => _showBookDetail(context, book),
                onLoadMore: result.hasNextPage
                    ? () => ref.read(bookSearchProvider.notifier).loadNextPage()
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularTab() {
    final popularBooks = ref.watch(popularBooksProvider);

    return popularBooks.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading popular books...'),
          ],
        ),
      ),
      error: (error, stackTrace) => _buildErrorWidget(
        error: error.toString(),
        onRetry: () => ref.read(popularBooksProvider.notifier).refresh(),
      ),
      data: (result) {
        if (result == null || result.isEmpty) {
          return const Center(child: Text('No popular books available'));
        }

        return PopularBooksSection(
          books: result.books,
          onBookTap: (book) => _showBookDetail(context, book),
          onLoadMore: result.hasNextPage
              ? () => ref.read(popularBooksProvider.notifier).loadNextPage()
              : null,
        );
      },
    );
  }

  Widget _buildApiStatusTab() {
    final apiStatus = ref.watch(apiStatusProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Status',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          apiStatus.when(
            loading: () => const ApiStatusCard.loading(),
            error: (error, stackTrace) => ApiStatusCard.error(
              error: error.toString(),
              onRetry: () => ref.invalidate(apiStatusProvider),
            ),
            data: (status) => ApiStatusCard.fromApiStatus(status: status),
          ),

          const SizedBox(height: 24),

          // API Features
          Text(
            'API Features',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          _buildFeaturesList(),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    // Simplified features list without ApiFeature enum
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Full-text Search'),
            trailing: const Text(
              'Supported',
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Multiple Formats'),
            trailing: const Text(
              'Supported',
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Subject Browsing'),
            trailing: const Text(
              'Supported',
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Popular Content'),
            trailing: const Text(
              'Supported',
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Cover Images'),
            trailing: const Text(
              'Not Available',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Search for books',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Enter a title, author, or subject to discover books from Project Gutenberg',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try different keywords or check your spelling',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).clearQuery();
              ref.read(bookSearchProvider.notifier).clearResults();
            },
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget({
    required String error,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookDetail(BuildContext context, BookSearchItem book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => _BookDetailSheet(
          book: book,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// Bottom sheet for displaying book details
class _BookDetailSheet extends ConsumerWidget {
  final BookSearchItem book;
  final ScrollController scrollController;

  const _BookDetailSheet({
    required this.book,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Book info
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by ${book.authorsString}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),

                  if (book.hasDescription) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(book.description!),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    'Available Formats',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: book.availableFormats.map((format) {
                      return Chip(label: Text(format.displayName));
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  if (book.subjects.isNotEmpty) ...[
                    Text(
                      'Subjects',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: book.subjects.take(5).map((subject) {
                        return Chip(
                          label: Text(subject),
                          backgroundColor: Colors.blue[50],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (book.downloadCount != null) ...[
                    Text(
                      'Downloads: ${book.downloadCount}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Download buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement download functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Download functionality will be implemented in next phase'),
                          ),
                        );
                      },
                      child: const Text('Download Book'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
