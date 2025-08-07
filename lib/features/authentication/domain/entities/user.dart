import 'package:equatable/equatable.dart';

/// User entity representing an authenticated user in the application
/// 
/// Contains all user-related information including authentication data,
/// profile information, and application preferences.
class User extends Equatable {
  /// Unique identifier for the user (Supabase UUID)
  final String id;
  
  /// User's email address (used for authentication)
  final String email;
  
  /// User's display name
  final String? name;
  
  /// URL to user's profile avatar
  final String? avatarUrl;
  
  /// User's preferred reading theme
  final String? readingTheme;
  
  /// User's preferred font family for reading
  final String? fontFamily;
  
  /// User's preferred font size for reading
  final double? fontSize;
  
  /// Whether the user prefers dark mode
  final bool isDarkMode;
  
  /// User's timezone
  final String? timezone;
  
  /// User's preferred language code (e.g., 'en', 'id')
  final String? languageCode;
  
  /// Whether the user has completed onboarding
  final bool isOnboardingCompleted;
  
  /// Whether the user has premium features enabled
  final bool isPremium;
  
  /// User's subscription status
  final String? subscriptionStatus;
  
  /// When the user account was created
  final DateTime createdAt;
  
  /// When the user account was last updated
  final DateTime updatedAt;
  
  /// When the user last logged in
  final DateTime? lastLoginAt;

  const User({
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

  /// Create a copy of this user with some fields replaced
  User copyWith({
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
    return User(
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

  /// Get user's display name or fallback to email
  String get displayName => name ?? email.split('@').first;

  /// Check if user has a complete profile
  bool get hasCompleteProfile => name != null && name!.isNotEmpty;

  /// Get user's initials for avatar fallback
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  /// Check if user is active (has logged in recently)
  bool get isActive {
    if (lastLoginAt == null) return false;
    final daysSinceLastLogin = DateTime.now().difference(lastLoginAt!).inDays;
    return daysSinceLastLogin <= 30; // Active if logged in within 30 days
  }

  /// Get reading preferences as a map
  Map<String, dynamic> get readingPreferences => {
    'theme': readingTheme,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'isDarkMode': isDarkMode,
  };

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
    return 'User(id: $id, email: $email, name: $name, isDarkMode: $isDarkMode, '
           'isOnboardingCompleted: $isOnboardingCompleted, isPremium: $isPremium)';
  }
}
