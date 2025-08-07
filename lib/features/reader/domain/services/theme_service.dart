import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../../core/errors/failures.dart';
import '../entities/font_settings.dart';
import '../entities/reading_theme.dart';
import '../entities/theme_configuration.dart';

/// Theme service interface for managing reading themes and settings
/// 
/// Provides methods for loading, saving, and managing theme configurations
/// with persistent storage and real-time updates.
abstract class ThemeService {
  /// Get current theme configuration
  Future<Either<Failure, ThemeConfiguration>> getCurrentThemeConfiguration();

  /// Save theme configuration
  Future<Either<Failure, void>> saveThemeConfiguration(ThemeConfiguration config);

  /// Get all available reading themes
  Future<Either<Failure, List<ReadingTheme>>> getAvailableThemes();

  /// Set reading theme
  Future<Either<Failure, void>> setReadingTheme(ReadingTheme theme);

  /// Set font settings
  Future<Either<Failure, void>> setFontSettings(FontSettings fontSettings);

  /// Set global theme mode (light/dark/system)
  Future<Either<Failure, void>> setGlobalThemeMode(ThemeMode themeMode);

  /// Toggle between light and dark mode
  Future<Either<Failure, void>> toggleThemeMode();

  /// Reset to default theme configuration
  Future<Either<Failure, void>> resetToDefault();

  /// Import theme configuration from JSON
  Future<Either<Failure, ThemeConfiguration>> importThemeConfiguration(
    Map<String, dynamic> json,
  );

  /// Export current theme configuration to JSON
  Future<Either<Failure, Map<String, dynamic>>> exportThemeConfiguration();

  /// Check if system dark mode is enabled
  Future<Either<Failure, bool>> isSystemDarkMode();

  /// Set screen brightness (0.0 - 1.0)
  Future<Either<Failure, void>> setScreenBrightness(double brightness);

  /// Set keep screen on setting
  Future<Either<Failure, void>> setKeepScreenOn(bool keepOn);

  /// Enable or disable animations
  Future<Either<Failure, void>> setAnimationsEnabled(bool enabled);

  /// Get font size level (0-7)
  Future<Either<Failure, int>> getCurrentFontSizeLevel();

  /// Set font size by level
  Future<Either<Failure, void>> setFontSizeLevel(int level);

  /// Increase font size
  Future<Either<Failure, void>> increaseFontSize();

  /// Decrease font size
  Future<Either<Failure, void>> decreaseFontSize();

  /// Set font family
  Future<Either<Failure, void>> setFontFamily(String fontFamily);

  /// Get available font families
  Future<Either<Failure, List<String>>> getAvailableFontFamilies();

  /// Validate theme configuration
  Future<Either<Failure, bool>> validateThemeConfiguration(
    ThemeConfiguration config,
  );

  /// Stream of theme configuration changes
  Stream<ThemeConfiguration> get themeConfigurationStream;

  /// Stream of reading theme changes
  Stream<ReadingTheme> get readingThemeStream;

  /// Stream of font settings changes
  Stream<FontSettings> get fontSettingsStream;
}
