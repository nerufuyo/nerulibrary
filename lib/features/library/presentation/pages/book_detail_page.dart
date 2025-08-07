import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Book detail page showing information about a specific book
/// 
/// Displays book metadata, description, download options,
/// and reading actions for a selected book.
class BookDetailPage extends ConsumerWidget {
  final String bookId;
  
  const BookDetailPage({
    super.key,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
      ),
      body: Center(
        child: Text('Book ID: $bookId'),
      ),
    );
  }
}
