import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service class for secure storage operations using platform-specific encryption
/// 
/// Provides encrypted storage for sensitive data like authentication tokens,
/// user credentials, and app preferences using the device's secure storage
/// mechanisms (Keychain on iOS, Keystore on Android).
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Authentication Keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _sessionExpiryKey = 'session_expiry';
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _rememberMeKey = 'remember_me';
  static const String _lastLoginEmailKey = 'last_login_email';
  static const String _appThemeKey = 'app_theme';
  static const String _languageKey = 'language';
  static const String _offlineDataKey = 'offline_data';

  /// Store access token securely
  Future<void> storeAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Retrieve stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Store refresh token securely
  Future<void> storeRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieve stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Store user ID
  Future<void> storeUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Retrieve stored user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Store complete user data as JSON
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _storage.write(key: _userDataKey, value: jsonString);
  }

  /// Retrieve stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _storage.read(key: _userDataKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  /// Store session expiry timestamp
  Future<void> storeSessionExpiry(DateTime expiry) async {
    await _storage.write(key: _sessionExpiryKey, value: expiry.toIso8601String());
  }

  /// Retrieve session expiry
  Future<DateTime?> getSessionExpiry() async {
    final expiryString = await _storage.read(key: _sessionExpiryKey);
    if (expiryString != null) {
      return DateTime.parse(expiryString);
    }
    return null;
  }

  /// Check if user session is valid
  Future<bool> isSessionValid() async {
    final expiry = await getSessionExpiry();
    final token = await getAccessToken();
    
    if (token == null || expiry == null) {
      return false;
    }
    
    return DateTime.now().isBefore(expiry);
  }

  /// Store biometric authentication preference
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Store remember me preference
  Future<void> setRememberMe(bool remember) async {
    await _storage.write(key: _rememberMeKey, value: remember.toString());
  }

  /// Check remember me preference
  Future<bool> isRememberMeEnabled() async {
    final remember = await _storage.read(key: _rememberMeKey);
    return remember == 'true';
  }

  /// Store last login email for convenience
  Future<void> storeLastLoginEmail(String email) async {
    await _storage.write(key: _lastLoginEmailKey, value: email);
  }

  /// Retrieve last login email
  Future<String?> getLastLoginEmail() async {
    return await _storage.read(key: _lastLoginEmailKey);
  }

  /// Store app theme preference
  Future<void> storeAppTheme(String theme) async {
    await _storage.write(key: _appThemeKey, value: theme);
  }

  /// Retrieve app theme preference
  Future<String?> getAppTheme() async {
    return await _storage.read(key: _appThemeKey);
  }

  /// Store language preference
  Future<void> storeLanguage(String language) async {
    await _storage.write(key: _languageKey, value: language);
  }

  /// Retrieve language preference
  Future<String?> getLanguage() async {
    return await _storage.read(key: _languageKey);
  }

  /// Store first launch flag
  Future<void> setFirstLaunch(bool isFirst) async {
    await _storage.write(key: _isFirstLaunchKey, value: isFirst.toString());
  }

  /// Check if this is first app launch
  Future<bool> isFirstLaunch() async {
    final isFirst = await _storage.read(key: _isFirstLaunchKey);
    return isFirst != 'false'; // Default to true if not set
  }

  /// Store offline data for specific feature
  Future<void> storeOfflineData(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    await _storage.write(key: '$_offlineDataKey_$key', value: jsonString);
  }

  /// Retrieve offline data for specific feature
  Future<Map<String, dynamic>?> getOfflineData(String key) async {
    final jsonString = await _storage.read(key: '$_offlineDataKey_$key');
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userDataKey),
      _storage.delete(key: _sessionExpiryKey),
    ]);
  }

  /// Clear all stored data (use with caution)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    final userId = await getUserId();
    return token != null && userId != null;
  }
}