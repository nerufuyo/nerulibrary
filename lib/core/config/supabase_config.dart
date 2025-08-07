import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../errors/exceptions.dart' as app_exceptions;

/// Supabase configuration and initialization
/// 
/// Handles Supabase client setup, authentication, and connection management.
/// Provides centralized access to Supabase services with proper error handling.
class SupabaseConfig {
  static SupabaseConfig? _instance;
  static SupabaseConfig get instance => _instance ??= SupabaseConfig._();
  
  SupabaseClient? _client;
  bool _initialized = false;
  
  SupabaseConfig._();
  
  /// Get the Supabase client instance
  SupabaseClient get client {
    if (!_initialized) {
      throw const app_exceptions.AuthException('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }
  
  /// Check if Supabase is initialized
  bool get isInitialized => _initialized;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _initialized && _client!.auth.currentUser != null;
  
  /// Get current user
  User? get currentUser => _initialized ? _client!.auth.currentUser : null;
  
  /// Get current session
  Session? get currentSession => _initialized ? _client!.auth.currentSession : null;
  
  /// Initialize Supabase client
  Future<void> initialize() async {
    try {
      final appConfig = AppConfig.instance;
      
      // Check if cloud sync is enabled and properly configured
      if (!appConfig.enableCloudSync) {
        // Initialize with dummy values for offline-only mode
        await _initializeOfflineMode();
        return;
      }
      
      // Validate configuration
      if (!appConfig.isConfigurationValid) {
        final missing = appConfig.missingConfiguration;
        throw app_exceptions.AuthException(
          'Invalid Supabase configuration. Missing: ${missing.join(', ')}'
        );
      }
      
      // Initialize Supabase
      await Supabase.initialize(
        url: appConfig.supabaseUrl,
        anonKey: appConfig.supabaseAnonKey,
      );
      
      _client = Supabase.instance.client;
      _initialized = true;
      
      // Set up auth state listener
      _setupAuthStateListener();
      
    } catch (e) {
      throw app_exceptions.AuthException(
        'Failed to initialize Supabase: ${e.toString()}',
      );
    }
  }
  
  /// Initialize for offline-only mode
  Future<void> _initializeOfflineMode() async {
    // For offline mode, we don't need a real Supabase connection
    // but we still mark as initialized to prevent errors
    _initialized = true;
  }
  
  /// Set up authentication state listener
  void _setupAuthStateListener() {
    if (!AppConfig.instance.enableCloudSync) return;
    
    _client!.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      
      switch (event) {
        case AuthChangeEvent.signedIn:
          _handleSignIn(session);
          break;
        case AuthChangeEvent.signedOut:
          _handleSignOut();
          break;
        case AuthChangeEvent.tokenRefreshed:
          _handleTokenRefresh(session);
          break;
        case AuthChangeEvent.userUpdated:
          _handleUserUpdate(session);
          break;
        case AuthChangeEvent.passwordRecovery:
          _handlePasswordRecovery(session);
          break;
        default:
          break;
      }
    });
  }
  
  /// Handle sign in event
  void _handleSignIn(Session? session) {
    if (session != null) {
      // User signed in successfully
      // Trigger sync if needed
    }
  }
  
  /// Handle sign out event
  void _handleSignOut() {
    // User signed out
    // Clear local sensitive data if needed
  }
  
  /// Handle token refresh event
  void _handleTokenRefresh(Session? session) {
    if (session != null) {
      // Token refreshed successfully
    }
  }
  
  /// Handle user update event
  void _handleUserUpdate(Session? session) {
    if (session != null) {
      // User profile updated
    }
  }
  
  /// Handle password recovery event
  void _handlePasswordRecovery(Session? session) {
    // Password recovery initiated
  }
  
  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    if (!AppConfig.instance.enableCloudSync) {
      throw const app_exceptions.AuthException('Cloud sync is disabled. Cannot sign up.');
    }
    
    try {
      return await _client!.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
    } catch (e) {
      throw app_exceptions.AuthException(
        'Failed to sign up: ${e.toString()}',
      );
    }
  }
  
  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (!AppConfig.instance.enableCloudSync) {
      throw const app_exceptions.AuthException('Cloud sync is disabled. Cannot sign in.');
    }
    
    try {
      return await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw app_exceptions.AuthException(
        'Failed to sign in: ${e.toString()}',
      );
    }
  }
  
  /// Sign out current user
  Future<void> signOut() async {
    if (!AppConfig.instance.enableCloudSync) {
      return; // No-op for offline mode
    }
    
    try {
      await _client!.auth.signOut();
    } catch (e) {
      throw app_exceptions.AuthException(
        'Failed to sign out: ${e.toString()}',
      );
    }
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    if (!AppConfig.instance.enableCloudSync) {
      throw const app_exceptions.AuthException('Cloud sync is disabled. Cannot reset password.');
    }
    
    try {
      await _client!.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw app_exceptions.AuthException(
        'Failed to reset password: ${e.toString()}',
      );
    }
  }
  
  /// Update user profile
  Future<UserResponse> updateProfile({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    if (!AppConfig.instance.enableCloudSync) {
      throw const app_exceptions.AuthException('Cloud sync is disabled. Cannot update profile.');
    }
    
    try {
      return await _client!.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
          data: data,
        ),
      );
    } catch (e) {
      throw app_exceptions.AuthException(
        'Failed to update profile: ${e.toString()}',
      );
    }
  }
  
  /// Get database client
  SupabaseClient get database {
    if (!AppConfig.instance.enableCloudSync) {
      throw const app_exceptions.AuthException('Cloud sync is disabled. Database not available.');
    }
    return _client!;
  }
  
  /// Get storage client
  SupabaseStorageClient get storage {
    if (!AppConfig.instance.enableCloudSync) {
      throw const app_exceptions.AuthException('Cloud sync is disabled. Storage not available.');
    }
    return _client!.storage;
  }
  
  /// Get realtime client
  RealtimeClient get realtime {
    if (!AppConfig.instance.enableCloudSync) {
      throw const app_exceptions.AuthException('Cloud sync is disabled. Realtime not available.');
    }
    return _client!.realtime;
  }
  
  /// Dispose resources
  void dispose() {
    // Clean up resources if needed
    _initialized = false;
    _client = null;
  }
}
