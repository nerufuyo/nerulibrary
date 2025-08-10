import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/auth_required_wrapper.dart';

/// Example book card widget showing how to implement optional authentication
///
/// This demonstrates how to wrap save/favorite actions with authentication
/// requirements while allowing guests to read books.
class BookCard extends ConsumerWidget {
  final String bookId;
  final String title;
  final String author;
  final String? coverUrl;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onSave;

  const BookCard({
    super.key,
    required this.bookId,
    required this.title,
    required this.author,
    this.coverUrl,
    this.isFavorite = false,
    this.onTap,
    this.onFavorite,
    this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap, // Reading doesn't require authentication
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: coverUrl != null
                    ? Image.network(
                        coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(context),
                      )
                    : _buildPlaceholder(context),
              ),
            ),
            
            // Book Info and Actions
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Author
                    Text(
                      author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Action Buttons
                    Row(
                      children: [
                        // Favorite Button (requires auth)
                        if (onFavorite != null)
                          FavoriteAuthWrapper(
                            bookTitle: title,
                            onFavorite: onFavorite!,
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: isFavorite 
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        
                        const SizedBox(width: 8),
                        
                        // Save Button (requires auth)
                        if (onSave != null)
                          SaveBookAuthWrapper(
                            bookTitle: title,
                            onSave: onSave!,
                            child: Icon(
                              Icons.bookmark_border,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        
                        const Spacer(),
                        
                        // Read Button (no auth required)
                        Icon(
                          Icons.play_arrow,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
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

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Icon(
        Icons.book,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Example floating action button for adding books
/// This shows how to wrap the add book action with authentication
class AddBookFAB extends ConsumerWidget {
  final VoidCallback onAddBook;

  const AddBookFAB({
    super.key,
    required this.onAddBook,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthRequiredWrapper(
      onAction: onAddBook,
      authMessage: 'Please log in to add books to your library. '
          'This will allow you to organize and sync your collection across devices.',
      child: FloatingActionButton(
        onPressed: () {}, // The wrapper handles the actual tap
        child: const Icon(Icons.add),
      ),
    );
  }
}
