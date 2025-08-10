import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'user_local_datasource.dart';

/// Concrete implementation of UserLocalDataSource using secure storage
class UserLocalDataSourceImpl implements UserLocalDataSource {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _userCacheKey = 'cached_user';
  static const String _preferencesCacheKey = 'cached_preferences';
  static const String _lastCacheUpdateKey = 'last_cache_update';

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userJson = await _storage.read(key: _userCacheKey);
      if (userJson == null) return null;

      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      // If there's an error reading cache, return null
      return null;
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final userJson = json.encode(user.toJson());
      await _storage.write(key: _userCacheKey, value: userJson);

      // Update cache timestamp
      await _storage.write(
        key: _lastCacheUpdateKey,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      // Silently fail cache operations
      // In a production app, you might want to log this error
    }
  }

  @override
  Future<void> clearUserCache() async {
    try {
      await _storage.delete(key: _userCacheKey);
      await _storage.delete(key: _preferencesCacheKey);
      await _storage.delete(key: _lastCacheUpdateKey);
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<bool> hasUserCache() async {
    try {
      final userJson = await _storage.read(key: _userCacheKey);
      return userJson != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedPreferences() async {
    try {
      final preferencesJson = await _storage.read(key: _preferencesCacheKey);
      if (preferencesJson == null) return null;

      return json.decode(preferencesJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cachePreferences(Map<String, dynamic> preferences) async {
    try {
      final preferencesJson = json.encode(preferences);
      await _storage.write(key: _preferencesCacheKey, value: preferencesJson);

      // Update cache timestamp
      await _storage.write(
        key: _lastCacheUpdateKey,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<DateTime?> getLastCacheUpdate() async {
    try {
      final timestampString = await _storage.read(key: _lastCacheUpdateKey);
      if (timestampString == null) return null;

      final timestamp = int.parse(timestampString);
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isCacheStale({Duration? maxAge}) async {
    try {
      final lastUpdate = await getLastCacheUpdate();
      if (lastUpdate == null) return true;

      final age = maxAge ?? const Duration(hours: 24); // Default: 24 hours
      final staleTime = DateTime.now().subtract(age);

      return lastUpdate.isBefore(staleTime);
    } catch (e) {
      return true; // Assume stale if we can't determine age
    }
  }
}
