import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

/// PDF reader page for reading PDF books
/// 
/// Provides PDF viewing functionality with reading tools,
/// bookmarks, and navigation controls.
class PdfReaderPage extends ConsumerStatefulWidget {
  final String bookId;
  final String filePath;
  
  const PdfReaderPage({
    super.key,
    required this.bookId,
    required this.filePath,
  });

  @override
  ConsumerState<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends ConsumerState<PdfReaderPage> {
  final Completer<PDFViewController> _controller = Completer<PDFViewController>();
  
  int? _pages = 0;
  int _currentPage = 0;
  final bool _isReady = false;
  String _errorMessage = '';
  bool _controlsVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _controlsVisible ? AppBar(
        title: Text('PDF Reader'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ) : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // PDF Viewer
            PDFView(
              filePath: widget.filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: false,
              pageFling: true,
              pageSnap: true,
              defaultPage: _currentPage,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              onRender: (pages) {
                setState(() {
                  _pages = pages ?? 0;
                });
              },
              onError: (error) {
                setState(() {
                  _errorMessage = error.toString();
                });
                // PDF loading error handled silently
              },
              onPageError: (page, error) {
                setState(() {
                  _errorMessage = 'Page $page: ${error.toString()}';
                });
                // PDF page error handled silently
              },
              onViewCreated: (PDFViewController pdfViewController) {
                _controller.complete(pdfViewController);
              },
              onLinkHandler: (String? uri) {
                // PDF link handling - could be extended for navigation
              },
              onPageChanged: (int? page, int? total) {
                setState(() {
                  _currentPage = page ?? 0;
                });
              },
            ),
            
            // Loading indicator
            if (!_isReady)
              const Center(
                child: CircularProgressIndicator(),
              ),
            
            // Error message
            if (_errorMessage.isNotEmpty)
              Center(
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
                      'Error loading PDF',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _controlsVisible && _isReady ? _buildBottomControls() : null,
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
            onPressed: _currentPage > 0 ? _previousPage : null,
            iconSize: 32,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Page ${_currentPage + 1} of ${_pages ?? 0}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _pages != null && _pages! > 0 ? (_currentPage + 1) / _pages! : 0,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < (_pages ?? 1) - 1 ? _nextPage : null,
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
  Future<void> _previousPage() async {
    final controller = await _controller.future;
    if (_currentPage > 0) {
      await controller.setPage(_currentPage - 1);
    }
  }

  /// Navigate to next page
  Future<void> _nextPage() async {
    final controller = await _controller.future;
    if (_currentPage < (_pages ?? 1) - 1) {
      await controller.setPage(_currentPage + 1);
    }
  }

  /// Show search functionality
  void _showSearch() {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search functionality - implementation pending')),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Text(
            'PDF Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          const SizedBox(height: 24),
          
          // Settings content
          const Expanded(
            child: Center(
              child: Text(
                'PDF settings implementation pending\n\n• Zoom controls\n• Display options\n• Reading preferences\n• Page layout settings',
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
