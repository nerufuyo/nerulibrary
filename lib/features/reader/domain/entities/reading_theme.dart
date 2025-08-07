import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Reading theme entity defining visual appearance for reading
/// 
/// Contains all visual properties needed for a customized reading experience
/// including colors, typography, and layout preferences.
class ReadingTheme extends Equatable {
  final String id;
  final String name;
  final String description;
  final Color backgroundColor;
  final Color textColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final double contrast;
  final bool isHighContrast;
  final ThemeMode themeMode;

  const ReadingTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundColor,
    required this.textColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.contrast,
    this.isHighContrast = false,
    this.themeMode = ThemeMode.light,
  });

  /// Predefined reading themes
  static const ReadingTheme light = ReadingTheme(
    id: 'light',
    name: 'Light',
    description: 'Clean light theme for comfortable daytime reading',
    backgroundColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF1C1C1E),
    primaryColor: Color(0xFF007AFF),
    secondaryColor: Color(0xFF5856D6),
    surfaceColor: Color(0xFFF2F2F7),
    contrast: 1.0,
    themeMode: ThemeMode.light,
  );

  static const ReadingTheme dark = ReadingTheme(
    id: 'dark',
    name: 'Dark',
    description: 'Dark theme for comfortable night reading',
    backgroundColor: Color(0xFF000000),
    textColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFF0A84FF),
    secondaryColor: Color(0xFF5E5CE6),
    surfaceColor: Color(0xFF1C1C1E),
    contrast: 1.0,
    themeMode: ThemeMode.dark,
  );

  static const ReadingTheme sepia = ReadingTheme(
    id: 'sepia',
    name: 'Sepia',
    description: 'Warm sepia tone for reduced eye strain',
    backgroundColor: Color(0xFFF7F3E9),
    textColor: Color(0xFF5C4B37),
    primaryColor: Color(0xFF8B4513),
    secondaryColor: Color(0xFFCD853F),
    surfaceColor: Color(0xFFF5F5DC),
    contrast: 0.9,
    themeMode: ThemeMode.light,
  );

  static const ReadingTheme night = ReadingTheme(
    id: 'night',
    name: 'Night',
    description: 'Ultra-dark theme for late night reading',
    backgroundColor: Color(0xFF0D1117),
    textColor: Color(0xFFE6EDF3),
    primaryColor: Color(0xFF58A6FF),
    secondaryColor: Color(0xFF8B949E),
    surfaceColor: Color(0xFF161B22),
    contrast: 1.1,
    themeMode: ThemeMode.dark,
  );

  static const ReadingTheme highContrast = ReadingTheme(
    id: 'high_contrast',
    name: 'High Contrast',
    description: 'Maximum contrast for accessibility',
    backgroundColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF000000),
    primaryColor: Color(0xFF0000FF),
    secondaryColor: Color(0xFF8B0000),
    surfaceColor: Color(0xFFF0F0F0),
    contrast: 1.5,
    isHighContrast: true,
    themeMode: ThemeMode.light,
  );

  /// Get all available reading themes
  static List<ReadingTheme> get allThemes => [
    light,
    dark,
    sepia,
    night,
    highContrast,
  ];

  /// Create theme with modified properties
  ReadingTheme copyWith({
    String? id,
    String? name,
    String? description,
    Color? backgroundColor,
    Color? textColor,
    Color? primaryColor,
    Color? secondaryColor,
    Color? surfaceColor,
    double? contrast,
    bool? isHighContrast,
    ThemeMode? themeMode,
  }) {
    return ReadingTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      contrast: contrast ?? this.contrast,
      isHighContrast: isHighContrast ?? this.isHighContrast,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  /// Convert to Material Theme Data
  ThemeData toThemeData() {
    final colorScheme = themeMode == ThemeMode.dark
        ? ColorScheme.dark(
            primary: primaryColor,
            secondary: secondaryColor,
            surface: surfaceColor,
            onSurface: textColor,
            background: backgroundColor,
            onBackground: textColor,
          )
        : ColorScheme.light(
            primary: primaryColor,
            secondary: secondaryColor,
            surface: surfaceColor,
            onSurface: textColor,
            background: backgroundColor,
            onBackground: textColor,
          );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    backgroundColor,
    textColor,
    primaryColor,
    secondaryColor,
    surfaceColor,
    contrast,
    isHighContrast,
    themeMode,
  ];
}
