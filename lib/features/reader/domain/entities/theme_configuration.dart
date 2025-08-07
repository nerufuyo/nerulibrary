import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'font_settings.dart';
import 'reading_theme.dart';

/// Complete theme configuration for the reading experience
/// 
/// Combines reading theme, font settings, and display preferences
/// for a fully customized reading environment.
class ThemeConfiguration extends Equatable {
  final ReadingTheme readingTheme;
  final FontSettings fontSettings;
  final ThemeMode globalThemeMode;
  final bool useSystemTheme;
  final double screenBrightness;
  final bool keepScreenOn;
  final bool enableAnimations;

  const ThemeConfiguration({
    required this.readingTheme,
    required this.fontSettings,
    this.globalThemeMode = ThemeMode.system,
    this.useSystemTheme = true,
    this.screenBrightness = 1.0,
    this.keepScreenOn = false,
    this.enableAnimations = true,
  });

  /// Default theme configuration
  static const ThemeConfiguration defaultConfig = ThemeConfiguration(
    readingTheme: ReadingTheme.light,
    fontSettings: FontSettings.defaultSettings,
    globalThemeMode: ThemeMode.system,
    useSystemTheme: true,
    screenBrightness: 1.0,
    keepScreenOn: false,
    enableAnimations: true,
  );

  /// Dark mode theme configuration
  static const ThemeConfiguration darkConfig = ThemeConfiguration(
    readingTheme: ReadingTheme.dark,
    fontSettings: FontSettings.defaultSettings,
    globalThemeMode: ThemeMode.dark,
    useSystemTheme: false,
    screenBrightness: 0.8,
    keepScreenOn: false,
    enableAnimations: true,
  );

  /// High contrast configuration for accessibility
  static const ThemeConfiguration accessibilityConfig = ThemeConfiguration(
    readingTheme: ReadingTheme.highContrast,
    fontSettings: FontSettings(
      fontFamily: 'System Default',
      fontSize: 20.0,
      lineHeight: 1.6,
      fontWeight: FontWeight.w500,
    ),
    globalThemeMode: ThemeMode.light,
    useSystemTheme: false,
    screenBrightness: 1.0,
    keepScreenOn: true,
    enableAnimations: false,
  );

  /// Create copy with modified properties
  ThemeConfiguration copyWith({
    ReadingTheme? readingTheme,
    FontSettings? fontSettings,
    ThemeMode? globalThemeMode,
    bool? useSystemTheme,
    double? screenBrightness,
    bool? keepScreenOn,
    bool? enableAnimations,
  }) {
    return ThemeConfiguration(
      readingTheme: readingTheme ?? this.readingTheme,
      fontSettings: fontSettings ?? this.fontSettings,
      globalThemeMode: globalThemeMode ?? this.globalThemeMode,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      screenBrightness: screenBrightness ?? this.screenBrightness,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      enableAnimations: enableAnimations ?? this.enableAnimations,
    );
  }

  /// Get effective theme mode
  ThemeMode get effectiveThemeMode {
    if (useSystemTheme) {
      return ThemeMode.system;
    }
    return globalThemeMode;
  }

  /// Get reading text style
  TextStyle getReadingTextStyle() {
    return fontSettings.toTextStyle(readingTheme.textColor);
  }

  /// Get Material Theme Data for the app
  ThemeData getAppThemeData() {
    return readingTheme.toThemeData();
  }

  /// Check if current theme is dark
  bool get isDarkTheme {
    return readingTheme.themeMode == ThemeMode.dark ||
           globalThemeMode == ThemeMode.dark;
  }

  /// Get theme summary for display
  String get themeSummary {
    return '${readingTheme.name} • ${fontSettings.fontFamily} • ${fontSettings.fontSizeLabel}';
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'readingThemeId': readingTheme.id,
      'fontSettings': fontSettings.toJson(),
      'globalThemeMode': globalThemeMode.name,
      'useSystemTheme': useSystemTheme,
      'screenBrightness': screenBrightness,
      'keepScreenOn': keepScreenOn,
      'enableAnimations': enableAnimations,
    };
  }

  /// Create from JSON
  factory ThemeConfiguration.fromJson(Map<String, dynamic> json) {
    // Find reading theme by ID
    final themeId = json['readingThemeId'] as String? ?? 'light';
    final readingTheme = ReadingTheme.allThemes.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => ReadingTheme.light,
    );

    // Parse theme mode
    final themeModeStr = json['globalThemeMode'] as String? ?? 'system';
    ThemeMode themeMode;
    switch (themeModeStr) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    return ThemeConfiguration(
      readingTheme: readingTheme,
      fontSettings: FontSettings.fromJson(
        json['fontSettings'] as Map<String, dynamic>? ?? {},
      ),
      globalThemeMode: themeMode,
      useSystemTheme: json['useSystemTheme'] as bool? ?? true,
      screenBrightness: (json['screenBrightness'] as num?)?.toDouble() ?? 1.0,
      keepScreenOn: json['keepScreenOn'] as bool? ?? false,
      enableAnimations: json['enableAnimations'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    readingTheme,
    fontSettings,
    globalThemeMode,
    useSystemTheme,
    screenBrightness,
    keepScreenOn,
    enableAnimations,
  ];
}
