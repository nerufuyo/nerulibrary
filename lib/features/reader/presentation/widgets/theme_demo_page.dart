import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_providers.dart';
import '../../domain/entities/reading_theme.dart';

/// Demo page to showcase the theme system functionality
class ThemeDemoPage extends ConsumerWidget {
  const ThemeDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfig = ref.watch(themeNotifierProvider);
    final availableThemes = ref.watch(availableThemesProvider);
    final availableFonts = ref.watch(availableFontFamiliesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme System Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              ref.read(themeNotifierProvider.notifier).toggleThemeMode();
            },
          ),
        ],
      ),
      body: themeConfig.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(themeNotifierProvider.notifier).resetToDefault();
                },
                child: const Text('Reset to Default'),
              ),
            ],
          ),
        ),
        data: (config) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Configuration Display
              Card(
                color: config.readingTheme.backgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Reading Experience',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: config.readingTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This is how your reading text would appear with the current theme settings. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                        style: TextStyle(
                          fontSize: config.fontSettings.fontSize,
                          fontFamily: config.fontSettings.fontFamily,
                          color: config.readingTheme.textColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.palette,
                            color: config.readingTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Theme: ${config.readingTheme.name}',
                            style: TextStyle(
                              color: config.readingTheme.secondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.font_download,
                            color: config.readingTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Font: ${config.fontSettings.fontFamily} ${config.fontSettings.fontSize.toInt()}pt',
                            style: TextStyle(
                              color: config.readingTheme.secondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Theme Selection
              const Text(
                'Reading Themes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              availableThemes.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error loading themes: $error'),
                data: (themes) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: themes.map((theme) => _ThemeCard(
                    theme: theme,
                    isSelected: theme.name == config.readingTheme.name,
                    onTap: () {
                      ref.read(themeNotifierProvider.notifier).setReadingTheme(theme);
                    },
                  )).toList(),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Font Controls
              const Text(
                'Font Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Font Size Controls
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Font Size',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              ref.read(themeNotifierProvider.notifier).decreaseFontSize();
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '${config.fontSettings.fontSize.toInt()}pt',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(themeNotifierProvider.notifier).increaseFontSize();
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Font Family Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Font Family',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      availableFonts.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Error loading fonts: $error'),
                        data: (fonts) => DropdownButton<String>(
                          value: config.fontSettings.fontFamily,
                          isExpanded: true,
                          items: fonts.map((font) => DropdownMenuItem(
                            value: font,
                            child: Text(
                              font,
                              style: TextStyle(fontFamily: font),
                            ),
                          )).toList(),
                          onChanged: (font) {
                            if (font != null) {
                              ref.read(themeNotifierProvider.notifier).setFontFamily(font);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Reset Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(themeNotifierProvider.notifier).resetToDefault();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset to Default'),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying theme selection cards
class _ThemeCard extends StatelessWidget {
  final ReadingTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 80,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              theme.name,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.textColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
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
