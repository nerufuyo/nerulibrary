import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

/// Data model for User entity with JSON serialization
/// 
/// Handles conversion between API JSON responses and User entities.
/// Includes factory methods for creating models from various data sources.
class UserModel extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? readingTheme;
  final String? fontFamily;
  final double? fontSize;
  final bool isDarkMode;
  final String? timezone;
  final String? languageCode;
  final bool isOnboardingCompleted;
  final bool isPremium;
  final String? subscriptionStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.readingTheme,
    this.fontFamily,
    this.fontSize,
    this.isDarkMode = false,
    this.timezone,
    this.languageCode,
    this.isOnboardingCompleted = false,
    this.isPremium = false,
    this.subscriptionStatus,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  /// Create UserModel from JSON response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      readingTheme: json['reading_theme'] as String?,
      fontFamily: json['font_family'] as String?,
      fontSize: (json['font_size'] as num?)?.toDouble(),
      isDarkMode: json['is_dark_mode'] as bool? ?? false,
      timezone: json['timezone'] as String?,
      languageCode: json['language_code'] as String?,
      isOnboardingCompleted: json['is_onboarding_completed'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      subscriptionStatus: json['subscription_status'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }

  /// Create UserModel from Supabase User object
  factory UserModel.fromSupabaseUser(
    dynamic supabaseUser,
    Map<String, dynamic>? metadata,
  ) {
    final now = DateTime.now();
    
    return UserModel(
      id: supabaseUser.id as String,
      email: supabaseUser.email as String,
      name: metadata?['name'] as String? ?? supabaseUser.userMetadata?['name'] as String?,
      avatarUrl: metadata?['avatar_url'] as String? ?? supabaseUser.userMetadata?['avatar_url'] as String?,
      readingTheme: metadata?['reading_theme'] as String?,
      fontFamily: metadata?['font_family'] as String?,
      fontSize: (metadata?['font_size'] as num?)?.toDouble(),
      isDarkMode: metadata?['is_dark_mode'] as bool? ?? false,
      timezone: metadata?['timezone'] as String?,
      languageCode: metadata?['language_code'] as String?,
      isOnboardingCompleted: metadata?['is_onboarding_completed'] as bool? ?? false,
      isPremium: metadata?['is_premium'] as bool? ?? false,
      subscriptionStatus: metadata?['subscription_status'] as String?,
      createdAt: supabaseUser.createdAt != null 
          ? DateTime.parse(supabaseUser.createdAt as String)
          : now,
      updatedAt: supabaseUser.updatedAt != null 
          ? DateTime.parse(supabaseUser.updatedAt as String)
          : now,
      lastLoginAt: metadata?['last_login_at'] != null
          ? DateTime.parse(metadata!['last_login_at'] as String)
          : null,
    );
  }

  /// Create UserModel from User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatarUrl,
      readingTheme: user.readingTheme,
      fontFamily: user.fontFamily,
      fontSize: user.fontSize,
      isDarkMode: user.isDarkMode,
      timezone: user.timezone,
      languageCode: user.languageCode,
      isOnboardingCompleted: user.isOnboardingCompleted,
      isPremium: user.isPremium,
      subscriptionStatus: user.subscriptionStatus,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      lastLoginAt: user.lastLoginAt,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'reading_theme': readingTheme,
      'font_family': fontFamily,
      'font_size': fontSize,
      'is_dark_mode': isDarkMode,
      'timezone': timezone,
      'language_code': languageCode,
      'is_onboarding_completed': isOnboardingCompleted,
      'is_premium': isPremium,
      'subscription_status': subscriptionStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  /// Convert to User entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      avatarUrl: avatarUrl,
      readingTheme: readingTheme,
      fontFamily: fontFamily,
      fontSize: fontSize,
      isDarkMode: isDarkMode,
      timezone: timezone,
      languageCode: languageCode,
      isOnboardingCompleted: isOnboardingCompleted,
      isPremium: isPremium,
      subscriptionStatus: subscriptionStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
    );
  }

  /// Convert to map for database storage
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'reading_theme': readingTheme,
      'font_family': fontFamily,
      'font_size': fontSize,
      'is_dark_mode': isDarkMode ? 1 : 0,
      'timezone': timezone,
      'language_code': languageCode,
      'is_onboarding_completed': isOnboardingCompleted ? 1 : 0,
      'is_premium': isPremium ? 1 : 0,
      'subscription_status': subscriptionStatus,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'last_login_at': lastLoginAt?.millisecondsSinceEpoch,
    };
  }

  /// Create UserModel from database map
  factory UserModel.fromDatabase(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      readingTheme: map['reading_theme'] as String?,
      fontFamily: map['font_family'] as String?,
      fontSize: (map['font_size'] as num?)?.toDouble(),
      isDarkMode: (map['is_dark_mode'] as int?) == 1,
      timezone: map['timezone'] as String?,
      languageCode: map['language_code'] as String?,
      isOnboardingCompleted: (map['is_onboarding_completed'] as int?) == 1,
      isPremium: (map['is_premium'] as int?) == 1,
      subscriptionStatus: map['subscription_status'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      lastLoginAt: map['last_login_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_login_at'] as int)
          : null,
    );
  }

  /// Create copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? readingTheme,
    String? fontFamily,
    double? fontSize,
    bool? isDarkMode,
    String? timezone,
    String? languageCode,
    bool? isOnboardingCompleted,
    bool? isPremium,
    String? subscriptionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      readingTheme: readingTheme ?? this.readingTheme,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      timezone: timezone ?? this.timezone,
      languageCode: languageCode ?? this.languageCode,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      isPremium: isPremium ?? this.isPremium,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    avatarUrl,
    readingTheme,
    fontFamily,
    fontSize,
    isDarkMode,
    timezone,
    languageCode,
    isOnboardingCompleted,
    isPremium,
    subscriptionStatus,
    createdAt,
    updatedAt,
    lastLoginAt,
  ];

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, isDarkMode: $isDarkMode)';
  }
}
