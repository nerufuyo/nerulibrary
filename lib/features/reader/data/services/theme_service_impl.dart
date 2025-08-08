import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/font_settings.dart';
import '../../domain/entities/reading_theme.dart';
import '../../domain/entities/theme_configuration.dart';
import '../../domain/services/theme_service.dart';

/// Implementation of theme service for managing reading themes
///
/// Handles persistent storage, real-time updates, and system integration
/// for reading theme configurations.
class ThemeServiceImpl implements ThemeService {
  final SharedPreferences _prefs;

  // Stream controllers for real-time updates
  final _themeConfigController =
      StreamController<ThemeConfiguration>.broadcast();
  final _readingThemeController = StreamController<ReadingTheme>.broadcast();
  final _fontSettingsController = StreamController<FontSettings>.broadcast();

  // Current configuration cache
  ThemeConfiguration? _currentConfig;

  ThemeServiceImpl({
    required SharedPreferences prefs,
  }) : _prefs = prefs {
    _loadInitialConfiguration();
  }

  @override
  Stream<ThemeConfiguration> get themeConfigurationStream =>
      _themeConfigController.stream;

  @override
  Stream<ReadingTheme> get readingThemeStream => _readingThemeController.stream;

  @override
  Stream<FontSettings> get fontSettingsStream => _fontSettingsController.stream;

  /// Load initial configuration from storage
  Future<void> _loadInitialConfiguration() async {
    final result = await getCurrentThemeConfiguration();
    result.fold(
      (failure) => _currentConfig = ThemeConfiguration.defaultConfig,
      (config) => _currentConfig = config,
    );
  }

  @override
  Future<Either<Failure, ThemeConfiguration>>
      getCurrentThemeConfiguration() async {
    try {
      final configJson = _prefs.getString(StorageConstants.prefReadingTheme);

      if (configJson == null) {
        // Return default configuration
        final defaultConfig = ThemeConfiguration.defaultConfig;
        await _saveConfigurationToStorage(defaultConfig);
        return Right(defaultConfig);
      }

      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      final config = ThemeConfiguration.fromJson(configMap);

      _currentConfig = config;
      return Right(config);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to load theme configuration: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> saveThemeConfiguration(
      ThemeConfiguration config) async {
    try {
      await _saveConfigurationToStorage(config);
      _currentConfig = config;

      // Emit updates to streams
      _themeConfigController.add(config);
      _readingThemeController.add(config.readingTheme);
      _fontSettingsController.add(config.fontSettings);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to save theme configuration: ${e.toString()}',
      ));
    }
  }

  Future<void> _saveConfigurationToStorage(ThemeConfiguration config) async {
    final configJson = jsonEncode(config.toJson());
    await _prefs.setString(StorageConstants.prefReadingTheme, configJson);
  }

  @override
  Future<Either<Failure, List<ReadingTheme>>> getAvailableThemes() async {
    try {
      return Right(ReadingTheme.allThemes);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to get available themes: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> setReadingTheme(ReadingTheme theme) async {
    try {
      final currentConfig = _currentConfig ?? ThemeConfiguration.defaultConfig;
      final newConfig = currentConfig.copyWith(readingTheme: theme);
      return await saveThemeConfiguration(newConfig);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to set reading theme: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> setFontSettings(
      FontSettings fontSettings) async {
    try {
      final currentConfig = _currentConfig ?? ThemeConfiguration.defaultConfig;
      final newConfig = currentConfig.copyWith(fontSettings: fontSettings);
      return await saveThemeConfiguration(newConfig);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to set font settings: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> setGlobalThemeMode(ThemeMode themeMode) async {
    try {
      final currentConfig = _currentConfig ?? ThemeConfiguration.defaultConfig;
      final newConfig = currentConfig.copyWith(
        globalThemeMode: themeMode,
        useSystemTheme: themeMode == ThemeMode.system,
      );
      return await saveThemeConfiguration(newConfig);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to set theme mode: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> toggleThemeMode() async {
    try {
      final currentConfig = _currentConfig ?? ThemeConfiguration.defaultConfig;
      final currentMode = currentConfig.globalThemeMode;

      ThemeMode newMode;
      switch (currentMode) {
        case ThemeMode.light:
          newMode = ThemeMode.dark;
          break;
        case ThemeMode.dark:
          newMode = ThemeMode.light;
          break;
        case ThemeMode.system:
          newMode = ThemeMode.light;
          break;
      }

      return await setGlobalThemeMode(newMode);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to toggle theme mode: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> resetToDefault() async {
    try {
      return await saveThemeConfiguration(ThemeConfiguration.defaultConfig);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to reset to default: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, ThemeConfiguration>> importThemeConfiguration(
    Map<String, dynamic> json,
  ) async {
    try {
      final config = ThemeConfiguration.fromJson(json);
      await saveThemeConfiguration(config);
      return Right(config);
    } catch (e) {
      return Left(ValidationFailure(
        message: 'Failed to import theme configuration: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>>
      exportThemeConfiguration() async {
    try {
      final config = _currentConfig ?? ThemeConfiguration.defaultConfig;
      return Right(config.toJson());
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to export theme configuration: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> isSystemDarkMode() async {
    try {
      // This would need platform-specific implementation
      // For now, return false as placeholder
      return const Right(false);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to check system dark mode: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> setScreenBrightness(double brightness) async {
    try {
      final clampedBrightness = brightness.clamp(0.0, 1.0);
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          systemNavigationBarIconBrightness:
              clampedBrightness > 0.5 ? Brightness.dark : Brightness.light,
        ),
      );

      final currentConfig = _currentConfig ?? ThemeConfiguration.defaultConfig;
      final newConfig =
          currentConfig.copyWith(screenBrightness: clampedBrightness);
      return await saveThemeConfiguration(newConfig);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to set screen brightness: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> setKeepScreenOn(bool keepOn) async {
    try {
      final currentConfig = _currentConfig ?? ThemeConfiguration.defaultConfig;
      final newConfig = currentConfig.copyWith(keepScreenOn: keepOn);
      return await saveThemeConfiguration(newConfig);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to set keep screen on: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> setAnimationsEnabled(bool enabled) async {
    try {
      final currentConfig = _currentConfig ?? ThemeConfiguration.defaultConfig;
      final newConfig = currentConfig.copyWith(enableAnimations: enabled);
      return await saveThemeConfiguration(newConfig);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to set animations enabled: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, int>> getCurrentFontSizeLevel() async {
    try {
      final config = _currentConfig ?? ThemeConfiguration.defaultConfig;
      return Right(config.fontSettings.fontSizeLevel);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to get font size level: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> setFontSizeLevel(int level) async {
    try {
      final currentConfig = _currentConfig ?? ThemeConfiguration.defaultConfig;
      final newFontSettings =
          currentConfig.fontSettings.withFontSizeLevel(level);
      return await setFontSettings(newFontSettings);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to set font size level: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> increaseFontSize() async {
    try {
      final currentConfig = _currentConfig ?? ThemeConfiguration.defaultConfig;
      final newFontSettings = currentConfig.fontSettings.increaseFontSize();
      return await setFontSettings(newFontSettings);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to increase font size: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> decreaseFontSize() async {
    try {
      final currentConfig = _currentConfig ?? ThemeConfiguration.defaultConfig;
      final newFontSettings = currentConfig.fontSettings.decreaseFontSize();
      return await setFontSettings(newFontSettings);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to decrease font size: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> setFontFamily(String fontFamily) async {
    try {
      final currentConfig = _currentConfig ?? ThemeConfiguration.defaultConfig;
      final newFontSettings =
          currentConfig.fontSettings.copyWith(fontFamily: fontFamily);
      return await setFontSettings(newFontSettings);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to set font family: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableFontFamilies() async {
    try {
      return const Right(FontSettings.availableFonts);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to get available font families: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> validateThemeConfiguration(
    ThemeConfiguration config,
  ) async {
    try {
      // Basic validation
      if (config.fontSettings.fontSize < 8.0 ||
          config.fontSettings.fontSize > 32.0) {
        return Left(ValidationFailure(message: 'Invalid font size'));
      }

      if (config.screenBrightness < 0.0 || config.screenBrightness > 1.0) {
        return Left(ValidationFailure(message: 'Invalid screen brightness'));
      }

      return const Right(true);
    } catch (e) {
      return Left(ValidationFailure(
        message: 'Theme configuration validation failed: ${e.toString()}',
      ));
    }
  }

  /// Dispose resources
  void dispose() {
    _themeConfigController.close();
    _readingThemeController.close();
    _fontSettingsController.close();
  }
}
