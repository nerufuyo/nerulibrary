import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Font settings entity for reading customization
/// 
/// Defines font family, size, and text properties for optimal reading experience.
class FontSettings extends Equatable {
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final FontWeight fontWeight;

  const FontSettings({
    required this.fontFamily,
    required this.fontSize,
    this.lineHeight = 1.5,
    this.letterSpacing = 0.0,
    this.fontWeight = FontWeight.normal,
  });

  /// Predefined font families for reading
  static const List<String> availableFonts = [
    'System Default',
    'Merriweather',
    'Open Sans',
    'Roboto',
    'Georgia',
    'Times New Roman',
    'Arial',
  ];

  /// Font size levels (8 levels as required)
  static const List<double> fontSizeLevels = [
    12.0,  // Extra Small
    14.0,  // Small
    16.0,  // Default
    18.0,  // Medium
    20.0,  // Large
    22.0,  // Extra Large
    24.0,  // XX Large
    26.0,  // XXX Large
  ];

  /// Default font settings
  static const FontSettings defaultSettings = FontSettings(
    fontFamily: 'System Default',
    fontSize: 16.0,
    lineHeight: 1.5,
    letterSpacing: 0.0,
    fontWeight: FontWeight.normal,
  );

  /// Get font size level index
  int get fontSizeLevel {
    for (int i = 0; i < fontSizeLevels.length; i++) {
      if (fontSizeLevels[i] == fontSize) {
        return i;
      }
    }
    return 2; // Default to medium
  }

  /// Get font size label
  String get fontSizeLabel {
    switch (fontSizeLevel) {
      case 0: return 'Extra Small';
      case 1: return 'Small';
      case 2: return 'Default';
      case 3: return 'Medium';
      case 4: return 'Large';
      case 5: return 'Extra Large';
      case 6: return 'XX Large';
      case 7: return 'XXX Large';
      default: return 'Default';
    }
  }

  /// Create font settings with new size level
  FontSettings withFontSizeLevel(int level) {
    if (level < 0 || level >= fontSizeLevels.length) {
      return this;
    }
    return copyWith(fontSize: fontSizeLevels[level]);
  }

  /// Increase font size
  FontSettings increaseFontSize() {
    final currentLevel = fontSizeLevel;
    if (currentLevel < fontSizeLevels.length - 1) {
      return withFontSizeLevel(currentLevel + 1);
    }
    return this;
  }

  /// Decrease font size
  FontSettings decreaseFontSize() {
    final currentLevel = fontSizeLevel;
    if (currentLevel > 0) {
      return withFontSizeLevel(currentLevel - 1);
    }
    return this;
  }

  /// Get TextStyle for reading
  TextStyle toTextStyle(Color textColor) {
    return TextStyle(
      fontFamily: fontFamily == 'System Default' ? null : fontFamily,
      fontSize: fontSize,
      height: lineHeight,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      color: textColor,
    );
  }

  /// Create copy with modified properties
  FontSettings copyWith({
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? letterSpacing,
    FontWeight? fontWeight,
  }) {
    return FontSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      fontWeight: fontWeight ?? this.fontWeight,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'letterSpacing': letterSpacing,
      'fontWeight': fontWeight.index,
    };
  }

  /// Create from JSON
  factory FontSettings.fromJson(Map<String, dynamic> json) {
    return FontSettings(
      fontFamily: json['fontFamily'] as String? ?? 'System Default',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.5,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      fontWeight: FontWeight.values[json['fontWeight'] as int? ?? FontWeight.normal.index],
    );
  }

  @override
  List<Object?> get props => [
    fontFamily,
    fontSize,
    lineHeight,
    letterSpacing,
    fontWeight,
  ];
}
