import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pdf_reader_page.dart';
import 'epub_reader_page.dart';

/// Main reader screen that displays book content
/// 
/// This screen adapts to different book formats (PDF, EPUB)
/// and provides a unified reading experience with controls.
class ReaderScreen extends ConsumerStatefulWidget {
  /// Book ID to load and display
  final String bookId;
  
  /// File path to the book
  final String filePath;
  
  /// Book format for appropriate reader selection
  final String format;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.filePath,
    required this.format,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _controlsVisible = true;
  
  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  /// Load the book (placeholder implementation)
  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      // Simulate loading time
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _controlsVisible
          ? AppBar(
              title: Text(widget.bookId),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _showSettings,
                ),
                IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: _showTableOfContents,
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: _controlsVisible
          ? _buildBottomControls()
          : null,
    );
  }

  /// Build the main body content
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading book...'),
          ],
        ),
      );
    }
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading book',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBook,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return _buildReaderContent();
  }

  /// Build the main reader content area
  Widget _buildReaderContent() {
    final format = widget.format.toLowerCase();
    
    switch (format) {
      case 'pdf':
        return _buildPdfReader();
      case 'epub':
        return _buildEpubReader();
      default:
        return const Center(
          child: Text('Unsupported format'),
        );
    }
  }

  /// Build PDF reader view
  Widget _buildPdfReader() {
    return PdfReaderPage(
      bookId: widget.bookId,
      filePath: widget.filePath,
    );
  }

  /// Build EPUB reader view
  Widget _buildEpubReader() {
    return EpubReaderPage(
      bookId: widget.bookId,
      filePath: widget.filePath,
    );
  }

  /// Build bottom navigation controls
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousPage,
            iconSize: 32,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page 1 of 100',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: 0.1,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextPage,
            iconSize: 32,
          ),
        ],
      ),
    );
  }

  /// Toggle controls visibility
  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
  }

  /// Navigate to previous page
  void _previousPage() {
    // TODO: Implement previous page navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Previous page - implementation pending')),
    );
  }

  /// Navigate to next page
  void _nextPage() {
    // TODO: Implement next page navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Next page - implementation pending')),
    );
  }

  /// Show reading settings
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildSettingsSheet(),
    );
  }

  /// Show table of contents
  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildTableOfContentsSheet(),
    );
  }

  /// Build reader settings bottom sheet
  Widget _buildSettingsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Text(
            'Reading Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          const SizedBox(height: 24),
          
          // Settings content placeholder
          const Expanded(
            child: Center(
              child: Text(
                'Settings UI implementation pending\n\n• Font size adjustment\n• Theme selection\n• Reading preferences\n• Display options',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build table of contents bottom sheet
  Widget _buildTableOfContentsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Text(
            'Table of Contents',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          const SizedBox(height: 24),
          
          // TOC content placeholder
          const Expanded(
            child: Center(
              child: Text(
                'Table of contents implementation pending\n\n• Chapter navigation\n• Section links\n• Progress indicators\n• Search within TOC',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
