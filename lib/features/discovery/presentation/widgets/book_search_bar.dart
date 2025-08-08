import 'package:flutter/material.dart';

/// Search bar widget for book discovery
///
/// Provides search input functionality with clear button and search suggestions.
class BookSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final VoidCallback onClear;
  final String hintText;
  final bool enabled;

  const BookSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClear,
    this.hintText = 'Search books, authors, subjects...',
    this.enabled = true,
  });

  @override
  State<BookSearchBar> createState() => _BookSearchBarState();
}

class _BookSearchBarState extends State<BookSearchBar> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),

            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: widget.enabled,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _performSearch(value.trim());
                  }
                },
                onChanged: (value) {
                  // Clear results when search is cleared
                  if (value.isEmpty) {
                    widget.onClear();
                  }
                },
              ),
            ),

            // Clear button (only show when there's text)
            if (widget.controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.controller.clear();
                  widget.onClear();
                  setState(() {});
                },
                tooltip: 'Clear search',
              ),

            // Search button
            IconButton(
              icon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              onPressed: widget.enabled && !_isSearching
                  ? () {
                      final query = widget.controller.text.trim();
                      if (query.isNotEmpty) {
                        _performSearch(query);
                      }
                    }
                  : null,
              tooltip: 'Search',
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      widget.onSearch(query);
    } finally {
      // Reset searching state after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      });
    }
  }
}

/// Search suggestions widget
///
/// Shows recent searches and popular search terms
class SearchSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTap;

  const SearchSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Suggestions',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ...suggestions.take(5).map((suggestion) {
            return ListTile(
              dense: true,
              leading: const Icon(Icons.search, size: 20),
              title: Text(suggestion),
              onTap: () => onSuggestionTap(suggestion),
            );
          }),
        ],
      ),
    );
  }
}

/// Search filters widget
///
/// Provides additional search filtering options
class SearchFilters extends StatelessWidget {
  final Map<String, dynamic> filters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const SearchFilters({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Language filter
            _buildFilterSection(
              context,
              'Language',
              ['All', 'English', 'French', 'German', 'Spanish'],
              filters['language'] ?? 'All',
              (value) => _updateFilter('language', value),
            ),

            const SizedBox(height: 16),

            // Format filter
            _buildFilterSection(
              context,
              'Format',
              ['All', 'Text', 'EPUB', 'HTML', 'PDF'],
              filters['format'] ?? 'All',
              (value) => _updateFilter('format', value),
            ),

            const SizedBox(height: 16),

            // Sort order
            _buildFilterSection(
              context,
              'Sort by',
              ['Relevance', 'Title', 'Author', 'Download Count'],
              filters['sortBy'] ?? 'Relevance',
              (value) => _updateFilter('sortBy', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged(option);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _updateFilter(String key, String value) {
    final newFilters = Map<String, dynamic>.from(filters);
    newFilters[key] = value;
    onFiltersChanged(newFilters);
  }
}
