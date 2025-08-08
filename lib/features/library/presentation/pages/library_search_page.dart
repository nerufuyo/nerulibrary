import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/search_entities.dart';

/// Library search page for searching within user's book collection
/// 
/// Provides comprehensive search functionality across book metadata,
/// content, bookmarks, and notes with filters and pagination.
class LibrarySearchPage extends ConsumerStatefulWidget {
  /// Initial search query
  final String initialQuery;

  const LibrarySearchPage({
    super.key,
    this.initialQuery = '',
  });

  @override
  ConsumerState<LibrarySearchPage> createState() => _LibrarySearchPageState();
}

class _LibrarySearchPageState extends ConsumerState<LibrarySearchPage> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  
  Timer? _debounceTimer;
  bool _isSearching = false;
  SearchResponse? _searchResponse;
  String _errorMessage = '';
  
  // Search configuration
  SearchFilters _filters = const SearchFilters();
  SearchSort _sort = const SearchSort();
  
  // UI state
  bool _showFilters = false;
  List<String> _recentSearches = [];
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    
    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery);
      });
    }
    
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Library'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_off),
            onPressed: _toggleFilters,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildFiltersBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// Build the search input bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search input field
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search books, content, bookmarks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            textInputAction: TextInputAction.search,
            onChanged: _onSearchQueryChanged,
            onSubmitted: _onSearchSubmitted,
          ),
          
          // Search suggestions
          if (_suggestions.isNotEmpty && _searchFocusNode.hasFocus)
            _buildSuggestions(),
        ],
      ),
    );
  }

  /// Build search suggestions list
  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.search, size: 20),
            title: Text(suggestion),
            onTap: () => _selectSuggestion(suggestion),
          );
        },
      ),
    );
  }

  /// Build filters bar
  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Metadata',
              isSelected: _filters.resultTypes?.contains(SearchResultType.metadata) ?? false,
              onSelected: (selected) => _toggleResultTypeFilter(SearchResultType.metadata),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Content',
              isSelected: _filters.resultTypes?.contains(SearchResultType.content) ?? false,
              onSelected: (selected) => _toggleResultTypeFilter(SearchResultType.content),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Bookmarks',
              isSelected: _filters.resultTypes?.contains(SearchResultType.bookmark) ?? false,
              onSelected: (selected) => _toggleResultTypeFilter(SearchResultType.bookmark),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Notes',
              isSelected: _filters.resultTypes?.contains(SearchResultType.note) ?? false,
              onSelected: (selected) => _toggleResultTypeFilter(SearchResultType.note),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  /// Build main body content
  Widget _buildBody() {
    if (_searchController.text.trim().isEmpty) {
      return _buildEmptyState();
    }

    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_searchResponse == null || _searchResponse!.results.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildResultsList();
  }

  /// Build empty state when no search is performed
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.search,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Search Your Library',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Find books, content, bookmarks, and notes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.take(10).map((search) => ActionChip(
                label: Text(search),
                onPressed: () => _selectSuggestion(search),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
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
            'Search Error',
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
            onPressed: () => _performSearch(_searchController.text),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build no results state
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No matches found for "${_searchController.text}"',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  /// Build search results list
  Widget _buildResultsList() {
    final response = _searchResponse!;
    
    return Column(
      children: [
        // Results summary
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${response.totalCount} results',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                '${response.executionTimeMs}ms',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            itemCount: response.results.length + (response.hasMoreResults ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == response.results.length) {
                return _buildLoadMoreButton();
              }
              
              final result = response.results[index];
              return _buildResultItem(result);
            },
          ),
        ),
      ],
    );
  }

  /// Build search result item
  Widget _buildResultItem(SearchResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _getResultTypeIcon(result.type),
        title: Text(
          result.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.snippet != null)
              Text(
                result.snippet!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (result.context != null)
              Text(
                result.context!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(result.relevanceScore * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              result.type.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        onTap: () => _openSearchResult(result),
      ),
    );
  }

  /// Build load more button
  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _loadMoreResults,
        child: const Text('Load More Results'),
      ),
    );
  }

  /// Get icon for search result type
  Widget _getResultTypeIcon(SearchResultType type) {
    IconData iconData;
    Color? color;
    
    switch (type) {
      case SearchResultType.metadata:
        iconData = Icons.info_outline;
        color = Colors.blue;
        break;
      case SearchResultType.content:
        iconData = Icons.article_outlined;
        color = Colors.green;
        break;
      case SearchResultType.bookmark:
        iconData = Icons.bookmark_outline;
        color = Colors.orange;
        break;
      case SearchResultType.note:
        iconData = Icons.note_outlined;
        color = Colors.purple;
        break;
      case SearchResultType.chapter:
        iconData = Icons.menu_book_outlined;
        color = Colors.teal;
        break;
      case SearchResultType.tableOfContents:
        iconData = Icons.list_outlined;
        color = Colors.indigo;
        break;
    }
    
    return Icon(iconData, color: color);
  }

  // Event handlers

  /// Handle search query changes
  void _onSearchQueryChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.trim().isNotEmpty) {
      // Get suggestions after a short delay
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _getSuggestions(query);
      });
    } else {
      setState(() {
        _suggestions.clear();
      });
    }
  }

  /// Handle search submission
  void _onSearchSubmitted(String query) {
    _searchFocusNode.unfocus();
    _performSearch(query);
  }

  /// Perform search operation
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      // TODO: Replace with actual search service call
      await Future.delayed(const Duration(seconds: 1)); // Simulate search
      
      // Mock search response
      final mockResults = [
        SearchResult(
          id: '1',
          type: SearchResultType.metadata,
          title: 'Sample Book Title',
          description: 'This is a sample book description that contains the search term.',
          relevanceScore: 0.95,
          bookId: 'book1',
          context: 'Book metadata',
        ),
        SearchResult(
          id: '2',
          type: SearchResultType.content,
          title: 'Chapter 3: Advanced Topics',
          description: 'Content from chapter discussing advanced programming concepts...',
          relevanceScore: 0.87,
          bookId: 'book1',
          context: 'Chapter 3',
          snippet: 'This chapter covers advanced programming concepts including...',
        ),
      ];

      setState(() {
        _searchResponse = SearchResponse(
          results: mockResults,
          totalCount: mockResults.length,
          pagination: const SearchPagination(),
          executionTimeMs: 250,
        );
        _isSearching = false;
      });

      // Save to search history
      _addToRecentSearches(query);
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSearching = false;
      });
    }
  }

  /// Get search suggestions
  Future<void> _getSuggestions(String partialQuery) async {
    try {
      // TODO: Replace with actual suggestions service call
      await Future.delayed(const Duration(milliseconds: 200)); // Simulate API call
      
      // Mock suggestions
      final mockSuggestions = [
        '$partialQuerying',
        '$partialQuery guide',
        '$partialQuery tutorial',
      ];

      if (mounted) {
        setState(() {
          _suggestions = mockSuggestions;
        });
      }
    } catch (e) {
      // Handle suggestion errors silently
      if (mounted) {
        setState(() {
          _suggestions.clear();
        });
      }
    }
  }

  /// Load recent searches
  Future<void> _loadRecentSearches() async {
    try {
      // TODO: Replace with actual recent searches service call
      final mockRecentSearches = [
        'flutter tutorial',
        'dart programming',
        'mobile development',
        'state management',
      ];

      setState(() {
        _recentSearches = mockRecentSearches;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  /// Add search to recent searches
  void _addToRecentSearches(String query) {
    if (_recentSearches.contains(query)) {
      _recentSearches.remove(query);
    }
    _recentSearches.insert(0, query);
    
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }
  }

  /// Select a suggestion or recent search
  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _searchFocusNode.unfocus();
    setState(() {
      _suggestions.clear();
    });
    _performSearch(suggestion);
  }

  /// Clear search input
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _suggestions.clear();
      _searchResponse = null;
      _errorMessage = '';
    });
  }

  /// Toggle filters visibility
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  /// Toggle result type filter
  void _toggleResultTypeFilter(SearchResultType type) {
    final currentTypes = _filters.resultTypes ?? [];
    final newTypes = List<SearchResultType>.from(currentTypes);
    
    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }
    
    setState(() {
      _filters = _filters.copyWith(resultTypes: newTypes.isEmpty ? null : newTypes);
    });
    
    // Re-search with new filters
    if (_searchController.text.trim().isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _filters = const SearchFilters();
    });
    
    // Re-search without filters
    if (_searchController.text.trim().isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  /// Show sort options
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSortOptionsSheet(),
    );
  }

  /// Build sort options sheet
  Widget _buildSortOptionsSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort Results',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          ...SearchSortField.values.map((field) => RadioListTile<SearchSortField>(
            title: Text(_getSortFieldLabel(field)),
            value: field,
            groupValue: _sort.field,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sort = _sort.copyWith(field: value);
                });
                Navigator.of(context).pop();
                
                // Re-search with new sort
                if (_searchController.text.trim().isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              }
            },
          )),
        ],
      ),
    );
  }

  /// Get label for sort field
  String _getSortFieldLabel(SearchSortField field) {
    switch (field) {
      case SearchSortField.relevance:
        return 'Relevance';
      case SearchSortField.title:
        return 'Title';
      case SearchSortField.dateAdded:
        return 'Date Added';
      case SearchSortField.dateModified:
        return 'Date Modified';
      case SearchSortField.position:
        return 'Position';
    }
  }

  /// Load more search results
  Future<void> _loadMoreResults() async {
    if (_searchResponse?.hasMoreResults != true) return;

    // TODO: Implement pagination
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Load more functionality - implementation pending')),
    );
  }

  /// Open search result
  void _openSearchResult(SearchResult result) {
    // TODO: Navigate to the appropriate page based on result type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open result: ${result.title}')),
    );
  }
}
