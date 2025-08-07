import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/theme_service_impl.dart';
import '../../domain/entities/font_settings.dart';
import '../../domain/entities/reading_theme.dart';
import '../../domain/entities/theme_configuration.dart';
import '../../domain/services/theme_service.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// Provider for theme service implementation
final themeServiceProvider = Provider<ThemeService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeServiceImpl(prefs: prefs);
});

/// Provider for current theme configuration
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, AsyncValue<ThemeConfiguration>>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeNotifier(themeService);
});

/// Theme state notifier
class ThemeNotifier extends StateNotifier<AsyncValue<ThemeConfiguration>> {
  final ThemeService _themeService;

  ThemeNotifier(this._themeService) : super(const AsyncValue.loading()) {
    _loadThemeConfiguration();
  }

  /// Load initial theme configuration
  Future<void> _loadThemeConfiguration() async {
    final result = await _themeService.getCurrentThemeConfiguration();
    
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (config) => AsyncValue.data(config),
    );
  }

  /// Set reading theme
  Future<void> setReadingTheme(ReadingTheme theme) async {
    state = const AsyncValue.loading();
    
    final result = await _themeService.setReadingTheme(theme);
    
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) async {
        final configResult = await _themeService.getCurrentThemeConfiguration();
        state = configResult.fold(
          (failure) => AsyncValue.error(failure, StackTrace.current),
          (config) => AsyncValue.data(config),
        );
      },
    );
  }

  /// Set font settings
  Future<void> setFontSettings(FontSettings fontSettings) async {
    state = const AsyncValue.loading();
    
    final result = await _themeService.setFontSettings(fontSettings);
    
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) async {
        final configResult = await _themeService.getCurrentThemeConfiguration();
        state = configResult.fold(
          (failure) => AsyncValue.error(failure, StackTrace.current),
          (config) => AsyncValue.data(config),
        );
      },
    );
  }

  /// Set global theme mode
  Future<void> setGlobalThemeMode(ThemeMode themeMode) async {
    state = const AsyncValue.loading();
    
    final result = await _themeService.setGlobalThemeMode(themeMode);
    
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) async {
        final configResult = await _themeService.getCurrentThemeConfiguration();
        state = configResult.fold(
          (failure) => AsyncValue.error(failure, StackTrace.current),
          (config) => AsyncValue.data(config),
        );
      },
    );
  }

  /// Toggle theme mode
  Future<void> toggleThemeMode() async {
    state = const AsyncValue.loading();
    
    final result = await _themeService.toggleThemeMode();
    
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) async {
        final configResult = await _themeService.getCurrentThemeConfiguration();
        state = configResult.fold(
          (failure) => AsyncValue.error(failure, StackTrace.current),
          (config) => AsyncValue.data(config),
        );
      },
    );
  }

  /// Increase font size
  Future<void> increaseFontSize() async {
    final result = await _themeService.increaseFontSize();
    
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) async {
        final configResult = await _themeService.getCurrentThemeConfiguration();
        state = configResult.fold(
          (failure) => AsyncValue.error(failure, StackTrace.current),
          (config) => AsyncValue.data(config),
        );
      },
    );
  }

  /// Decrease font size
  Future<void> decreaseFontSize() async {
    final result = await _themeService.decreaseFontSize();
    
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) async {
        final configResult = await _themeService.getCurrentThemeConfiguration();
        state = configResult.fold(
          (failure) => AsyncValue.error(failure, StackTrace.current),
          (config) => AsyncValue.data(config),
        );
      },
    );
  }

  /// Set font family
  Future<void> setFontFamily(String fontFamily) async {
    final result = await _themeService.setFontFamily(fontFamily);
    
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) async {
        final configResult = await _themeService.getCurrentThemeConfiguration();
        state = configResult.fold(
          (failure) => AsyncValue.error(failure, StackTrace.current),
          (config) => AsyncValue.data(config),
        );
      },
    );
  }

  /// Reset to default configuration
  Future<void> resetToDefault() async {
    state = const AsyncValue.loading();
    
    final result = await _themeService.resetToDefault();
    
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) async {
        final configResult = await _themeService.getCurrentThemeConfiguration();
        state = configResult.fold(
          (failure) => AsyncValue.error(failure, StackTrace.current),
          (config) => AsyncValue.data(config),
        );
      },
    );
  }
}

/// Provider for available reading themes
final availableThemesProvider = FutureProvider<List<ReadingTheme>>((ref) async {
  final themeService = ref.read(themeServiceProvider);
  final result = await themeService.getAvailableThemes();
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (themes) => themes,
  );
});

/// Provider for available font families
final availableFontFamiliesProvider = FutureProvider<List<String>>((ref) async {
  final themeService = ref.read(themeServiceProvider);
  final result = await themeService.getAvailableFontFamilies();
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (fonts) => fonts,
  );
});

/// Provider for current reading theme
final currentReadingThemeProvider = Provider<ReadingTheme>((ref) {
  final themeConfig = ref.watch(themeNotifierProvider);
  
  return themeConfig.when(
    data: (config) => config.readingTheme,
    loading: () => ReadingTheme.light,
    error: (error, stack) => ReadingTheme.light,
  );
});

/// Provider for current font settings
final currentFontSettingsProvider = Provider<FontSettings>((ref) {
  final themeConfig = ref.watch(themeNotifierProvider);
  
  return themeConfig.when(
    data: (config) => config.fontSettings,
    loading: () => FontSettings.defaultSettings,
    error: (error, stack) => FontSettings.defaultSettings,
  );
});

/// Provider for effective theme mode
final effectiveThemeModeProvider = Provider<ThemeMode>((ref) {
  final themeConfig = ref.watch(themeNotifierProvider);
  
  return themeConfig.when(
    data: (config) => config.effectiveThemeMode,
    loading: () => ThemeMode.system,
    error: (error, stack) => ThemeMode.system,
  );
});

/// Provider for theme data for the app
final appThemeDataProvider = Provider<ThemeData>((ref) {
  final themeConfig = ref.watch(themeNotifierProvider);
  
  return themeConfig.when(
    data: (config) => config.getAppThemeData(),
    loading: () => ThemeData.light(),
    error: (error, stack) => ThemeData.light(),
  );
});

/// Stream provider for theme configuration changes
final themeConfigurationStreamProvider = StreamProvider<ThemeConfiguration>((ref) {
  final themeService = ref.read(themeServiceProvider);
  return themeService.themeConfigurationStream;
});

/// Stream provider for reading theme changes
final readingThemeStreamProvider = StreamProvider<ReadingTheme>((ref) {
  final themeService = ref.read(themeServiceProvider);
  return themeService.readingThemeStream;
});

/// Stream provider for font settings changes
final fontSettingsStreamProvider = StreamProvider<FontSettings>((ref) {
  final themeService = ref.read(themeServiceProvider);
  return themeService.fontSettingsStream;
});
