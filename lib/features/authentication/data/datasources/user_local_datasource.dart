import '../models/user_model.dart';

/// Abstract interface for local user data operations
/// 
/// Defines the contract for user-related local storage operations
/// including caching and offline data management.
abstract class UserLocalDataSource {
  /// Get cached user data
  Future<UserModel?> getCachedUser();
  
  /// Cache user data locally
  Future<void> cacheUser(UserModel user);
  
  /// Clear cached user data
  Future<void> clearUserCache();
  
  /// Check if user data is cached
  Future<bool> hasUserCache();
  
  /// Get cached user preferences
  Future<Map<String, dynamic>?> getCachedPreferences();
  
  /// Cache user preferences
  Future<void> cachePreferences(Map<String, dynamic> preferences);
  
  /// Get last cache update time
  Future<DateTime?> getLastCacheUpdate();
  
  /// Check if cached data is stale
  Future<bool> isCacheStale({Duration? maxAge});
}
