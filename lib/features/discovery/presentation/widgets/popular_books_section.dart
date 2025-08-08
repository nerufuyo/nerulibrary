import 'package:flutter/material.dart';
import '../../domain/entities/api_entities.dart';

/// Widget for displaying popular books section
///
/// Shows trending and most downloaded books in various layouts.
class PopularBooksSection extends StatelessWidget {
  final List<BookSearchItem> books;
  final Function(BookSearchItem) onBookTap;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final String title;

  const PopularBooksSection({
    super.key,
    required this.books,
    required this.onBookTap,
    this.onLoadMore,
    this.isLoading = false,
    this.title = 'Popular Books',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        // Books list
        Expanded(
          child: books.isEmpty && !isLoading
              ? _buildEmptyState(context)
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (onLoadMore != null &&
                        !isLoading &&
                        scrollInfo.metrics.extentAfter < 300) {
                      onLoadMore!();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: books.length + (isLoading ? 3 : 0),
                    itemBuilder: (context, index) {
                      if (index >= books.length) {
                        return const PopularBookPlaceholder();
                      }

                      final book = books[index];
                      return PopularBookItem(
                        book: book,
                        rank: index + 1,
                        onTap: () => onBookTap(book),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No popular books available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for trending content',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Individual popular book item
class PopularBookItem extends StatelessWidget {
  final BookSearchItem book;
  final int rank;
  final VoidCallback onTap;

  const PopularBookItem({
    super.key,
    required this.book,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Rank indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getRankColor(context, rank),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    rank.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Book cover
              Container(
                width: 48,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: book.hasCover
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.book);
                          },
                        ),
                      )
                    : const Icon(Icons.book),
              ),
              const SizedBox(width: 12),

              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authorsString,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.subjects.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.subjects.first,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Stats column
              Column(
                children: [
                  // Download count
                  if (book.downloadCount != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDownloadCount(book.downloadCount!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Available formats
                  if (book.availableFormats.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        book.availableFormats.first.displayName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(BuildContext context, int rank) {
    if (rank <= 3) {
      return Colors.amber; // Gold for top 3
    } else if (rank <= 10) {
      return Theme.of(context).colorScheme.primary; // Primary for top 10
    } else {
      return Colors.grey; // Grey for others
    }
  }

  String _formatDownloadCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}

/// Placeholder for loading popular books
class PopularBookPlaceholder extends StatelessWidget {
  const PopularBookPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Rank placeholder
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 12),

            // Cover placeholder
            Container(
              width: 48,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            // Info placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

            // Stats placeholder
            Column(
              children: [
                Container(
                  height: 16,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal popular books carousel
class PopularBooksCarousel extends StatelessWidget {
  final List<BookSearchItem> books;
  final Function(BookSearchItem) onBookTap;
  final String title;

  const PopularBooksCarousel({
    super.key,
    required this.books,
    required this.onBookTap,
    this.title = 'Popular Books',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onBookTap(book),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book cover
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primaryContainer,
                                Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                              ],
                            ),
                          ),
                          child: book.hasCover
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    book.coverUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.book, size: 32),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Book info
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.primaryAuthor,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
