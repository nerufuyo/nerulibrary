import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart';

import '../../data/services/epub_reader_service_impl.dart';
import '../../domain/entities/reader_entities.dart';

/// EPUB reader page for reading EPUB books
/// 
/// Provides EPUB viewing functionality with reading tools,
/// bookmarks, and navigation controls.
class EpubReaderPage extends ConsumerStatefulWidget {
  final String bookId;
  final String filePath;
  
  const EpubReaderPage({
    super.key,
    required this.bookId,
    required this.filePath,
  });

  @override
  ConsumerState<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends ConsumerState<EpubReaderPage> {
  EpubBook? _epubBook;
  List<EpubChapter> _chapters = [];
  int _currentChapterIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _controlsVisible = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadEpubBook();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load the EPUB book
  Future<void> _loadEpubBook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final service = EpubReaderServiceImpl();
      final result = await service.openBook(widget.filePath, BookFormat.epub);
      
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
        },
        (book) async {
          // Get chapters
          final chaptersResult = await service.getTableOfContents();
          chaptersResult.fold(
            (failure) {
              setState(() {
                _isLoading = false;
                _errorMessage = failure.message;
              });
            },
            (chapters) {
              setState(() {
                _epubBook = book as EpubBook?;
                _chapters = chapters.map((toc) => 
                  EpubChapter()..Title = toc.title
                ).toList();
                _isLoading = false;
              });
            },
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _controlsVisible ? AppBar(
        title: Text(_epubBook?.Title ?? 'EPUB Reader'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showTableOfContents,
          ),
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
        child: _buildBody(),
      ),
      bottomNavigationBar: _controlsVisible && !_isLoading && _chapters.isNotEmpty 
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
            Text('Loading EPUB book...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
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
              'Error loading EPUB',
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEpubBook,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_chapters.isEmpty) {
      return const Center(
        child: Text('No chapters found in this EPUB book'),
      );
    }

    return _buildChapterContent();
  }

  /// Build chapter content view
  Widget _buildChapterContent() {
    final currentChapter = _chapters[_currentChapterIndex];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter title
            if (currentChapter.Title?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  currentChapter.Title!,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            // Chapter content placeholder
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.book,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EPUB Content Renderer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'HTML content rendering implementation pending.\n\nChapter: ${currentChapter.Title}\nTotal chapters: ${_chapters.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Features to implement:\n• HTML to Flutter widget conversion\n• Image rendering\n• Text styling preservation\n• Hyperlink handling\n• Text selection and copy',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            onPressed: _currentChapterIndex > 0 ? _previousChapter : null,
            iconSize: 32,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chapter ${_currentChapterIndex + 1} of ${_chapters.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _chapters.isNotEmpty ? (_currentChapterIndex + 1) / _chapters.length : 0,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentChapterIndex < _chapters.length - 1 ? _nextChapter : null,
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

  /// Navigate to previous chapter
  void _previousChapter() {
    if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Navigate to next chapter
  void _nextChapter() {
    if (_currentChapterIndex < _chapters.length - 1) {
      setState(() {
        _currentChapterIndex++;
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Show table of contents
  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildTableOfContentsSheet(),
    );
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
          
          // Chapters list
          Expanded(
            child: ListView.builder(
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                final chapter = _chapters[index];
                final isCurrentChapter = index == _currentChapterIndex;
                
                return ListTile(
                  title: Text(
                    chapter.Title ?? 'Chapter ${index + 1}',
                    style: TextStyle(
                      fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentChapter 
                          ? Theme.of(context).colorScheme.primary 
                          : null,
                    ),
                  ),
                  leading: Icon(
                    isCurrentChapter ? Icons.play_arrow : Icons.article,
                    color: isCurrentChapter 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey,
                  ),
                  onTap: () {
                    setState(() {
                      _currentChapterIndex = index;
                    });
                    Navigator.of(context).pop();
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
            'EPUB Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          const SizedBox(height: 24),
          
          // Settings content
          const Expanded(
            child: Center(
              child: Text(
                'EPUB settings implementation pending\n\n• Font size adjustment\n• Font family selection\n• Reading themes\n• Text spacing\n• Margin settings',
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
