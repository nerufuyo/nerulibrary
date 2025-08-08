import 'package:flutter/material.dart';
import '../../domain/entities/api_entities.dart';

/// Grid view for displaying books
///
/// Shows books in a responsive grid layout with thumbnails, titles, and basic info.
class BookGridView extends StatelessWidget {
  final List<BookSearchItem> books;
  final Function(BookSearchItem) onBookTap;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final int crossAxisCount;

  const BookGridView({
    super.key,
    required this.books,
    required this.onBookTap,
    this.onLoadMore,
    this.isLoading = false,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        // Load more when reaching the bottom
        if (onLoadMore != null &&
            !isLoading &&
            scrollInfo.metrics.extentAfter < 300) {
          onLoadMore!();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: books.length + (isLoading ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= books.length) {
            // Loading placeholders
            return const BookItemPlaceholder();
          }

          final book = books[index];
          return BookGridItem(
            book: book,
            onTap: () => onBookTap(book),
          );
        },
      ),
    );
  }
}

/// Individual book item in the grid
class BookGridItem extends StatelessWidget {
  final BookSearchItem book;
  final VoidCallback onTap;

  const BookGridItem({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover (placeholder)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
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
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderCover(context);
                        },
                      )
                    : _buildPlaceholderCover(context),
              ),
            ),

            // Book info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Author
                    Text(
                      book.authorsString,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Formats and download count
                    Row(
                      children: [
                        // Format indicator
                        if (book.availableFormats.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
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

                        const Spacer(),

                        // Download count
                        if (book.downloadCount != null)
                          Row(
                            children: [
                              Icon(
                                Icons.download,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _formatDownloadCount(book.downloadCount!),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 32,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 8),
          Text(
            book.title.split(' ').take(2).join('\n'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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

/// Placeholder for loading book items
class BookItemPlaceholder extends StatelessWidget {
  const BookItemPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
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
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
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

/// List view variant for books
class BookListView extends StatelessWidget {
  final List<BookSearchItem> books;
  final Function(BookSearchItem) onBookTap;
  final VoidCallback? onLoadMore;
  final bool isLoading;

  const BookListView({
    super.key,
    required this.books,
    required this.onBookTap,
    this.onLoadMore,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (onLoadMore != null &&
            !isLoading &&
            scrollInfo.metrics.extentAfter < 300) {
          onLoadMore!();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: books.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= books.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final book = books[index];
          return BookListItem(
            book: book,
            onTap: () => onBookTap(book),
          );
        },
      ),
    );
  }
}

/// List item for books
class BookListItem extends StatelessWidget {
  final BookSearchItem book;
  final VoidCallback onTap;

  const BookListItem({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
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
        title: Text(
          book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.authorsString,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (book.subjects.isNotEmpty)
              Text(
                book.subjects.first,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (book.availableFormats.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
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
            if (book.downloadCount != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.download,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formatDownloadCount(book.downloadCount!),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
