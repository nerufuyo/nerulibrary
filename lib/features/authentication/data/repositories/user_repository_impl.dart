import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';
import '../datasources/user_local_datasource.dart';
import '../models/user_model.dart';

/// Implementation of [UserRepository] using Supabase backend
/// 
/// Handles user authentication, profile management, and data persistence
/// with offline support through local caching.
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final SecureStorage _secureStorage;
  final SupabaseClient _supabaseClient;

  const UserRepositoryImpl({
    required UserRemoteDataSource remoteDataSource,
    required UserLocalDataSource localDataSource,
    required SecureStorage secureStorage,
    required SupabaseClient supabaseClient,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _secureStorage = secureStorage,
       _supabaseClient = supabaseClient;

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      // Check if user is authenticated
      final session = _supabaseClient.auth.currentSession;
      if (session == null) {
        return const Right(null);
      }

      // Try to get user from cache first
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }

      // Fetch from remote if not cached
      final result = await _remoteDataSource.getCurrentUser();
      return result.fold(
        (failure) => Left(failure),
        (userModel) async {
          // Cache the user data
          await _localDataSource.cacheUser(userModel);
          return Right(userModel.toEntity());
        },
      );
    } catch (e) {
      return Left(AuthenticationFailure(
        message: 'Failed to get current user: ${e.toString()}',
        type: AuthFailureType.unknown,
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        return const Left(ValidationFailure(
          message: 'Email and password are required',
          field: 'email_password',
        ));
      }

      // Attempt sign in
      final result = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );

      return await result.fold(
        (failure) => Left(failure),
        (userModel) async {
          // Cache user data
          await _localDataSource.cacheUser(userModel);
          
          // Update last login
          await _updateLastLoginInternal();
          
          return Right(userModel.toEntity());
        },
      );
    } catch (e) {
      return Left(AuthenticationFailure(
        message: 'Sign in failed: ${e.toString()}',
        type: _mapSupabaseErrorToAuthFailure(e),
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        return const Left(ValidationFailure(
          message: 'Email and password are required',
          field: 'email_password',
        ));
      }

      if (password.length < 6) {
        return const Left(AuthenticationFailure(
          message: 'Password must be at least 6 characters',
          type: AuthFailureType.weakPassword,
        ));
      }

      // Attempt sign up
      final result = await _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      return await result.fold(
        (failure) => Left(failure),
        (userModel) async {
          // Cache user data
          await _localDataSource.cacheUser(userModel);
          
          return Right(userModel.toEntity());
        },
      );
    } catch (e) {
      return Left(AuthenticationFailure(
        message: 'Sign up failed: ${e.toString()}',
        type: _mapSupabaseErrorToAuthFailure(e),
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      final result = await _remoteDataSource.signOut();
      
      return await result.fold(
        (failure) => Left(failure),
        (_) async {
          // Clear cached data
          await _localDataSource.clearUserCache();
          await _secureStorage.clearAuthData();
          
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(AuthenticationFailure(
        message: 'Sign out failed: ${e.toString()}',
        type: AuthFailureType.unknown,
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      final result = await _remoteDataSource.updateProfile(userModel);
      
      return await result.fold(
        (failure) => Left(failure),
        (updatedUserModel) async {
          // Update cache
          await _localDataSource.cacheUser(updatedUserModel);
          
          return Right(updatedUserModel.toEntity());
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to update profile: ${e.toString()}',
        operation: 'update_profile',
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<Either<Failure, User>> updateReadingPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final result = await _remoteDataSource.updateReadingPreferences(preferences);
      
      return await result.fold(
        (failure) => Left(failure),
        (updatedUserModel) async {
          // Update cache
          await _localDataSource.cacheUser(updatedUserModel);
          
          return Right(updatedUserModel.toEntity());
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to update reading preferences: ${e.toString()}',
        operation: 'update_preferences',
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        return const Left(ValidationFailure(
          message: 'Email is required',
          field: 'email',
        ));
      }

      final result = await _remoteDataSource.resetPassword(email);
      return result;
    } catch (e) {
      return Left(AuthenticationFailure(
        message: 'Password reset failed: ${e.toString()}',
        type: AuthFailureType.unknown,
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail(String token) async {
    try {
      final result = await _remoteDataSource.verifyEmail(token);
      return result;
    } catch (e) {
      return Left(AuthenticationFailure(
        message: 'Email verification failed: ${e.toString()}',
        type: AuthFailureType.unknown,
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        return const Left(ValidationFailure(
          message: 'Current and new passwords are required',
          field: 'passwords',
        ));
      }

      if (newPassword.length < 6) {
        return const Left(AuthenticationFailure(
          message: 'New password must be at least 6 characters',
          type: AuthFailureType.weakPassword,
        ));
      }

      final result = await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      return result;
    } catch (e) {
      return Left(AuthenticationFailure(
        message: 'Password change failed: ${e.toString()}',
        type: AuthFailureType.unknown,
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final result = await _remoteDataSource.deleteAccount();
      
      return await result.fold(
        (failure) => Left(failure),
        (_) async {
          // Clear all local data
          await _localDataSource.clearUserCache();
          await _secureStorage.clearAll();
          
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(AuthenticationFailure(
        message: 'Account deletion failed: ${e.toString()}',
        type: AuthFailureType.unknown,
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<Either<Failure, User>> refreshToken() async {
    try {
      final result = await _remoteDataSource.refreshToken();
      
      return await result.fold(
        (failure) => Left(failure),
        (userModel) async {
          // Update cache
          await _localDataSource.cacheUser(userModel);
          
          return Right(userModel.toEntity());
        },
      );
    } catch (e) {
      return Left(AuthenticationFailure(
        message: 'Token refresh failed: ${e.toString()}',
        type: AuthFailureType.sessionExpired,
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final session = _supabaseClient.auth.currentSession;
      return session != null && !session.isExpired;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<Failure, User>> getUserById(String userId) async {
    try {
      final result = await _remoteDataSource.getUserById(userId);
      
      return result.fold(
        (failure) => Left(failure),
        (userModel) => Right(userModel.toEntity()),
      );
    } catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get user by ID: ${e.toString()}',
        operation: 'get_user_by_id',
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastLogin() async {
    return await _updateLastLoginInternal();
  }

  @override
  Future<Either<Failure, User>> completeOnboarding(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final result = await _remoteDataSource.completeOnboarding(preferences);
      
      return await result.fold(
        (failure) => Left(failure),
        (userModel) async {
          // Update cache
          await _localDataSource.cacheUser(userModel);
          
          return Right(userModel.toEntity());
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to complete onboarding: ${e.toString()}',
        operation: 'complete_onboarding',
        originalError: e,
        stackTrace: StackTrace.current,
      ));
    }
  }

  /// Internal method to update last login timestamp
  Future<Either<Failure, void>> _updateLastLoginInternal() async {
    try {
      final result = await _remoteDataSource.updateLastLogin();
      return result;
    } catch (e) {
      // Don't fail the main operation if last login update fails
      return const Right(null);
    }
  }

  /// Map Supabase errors to authentication failure types
  AuthFailureType _mapSupabaseErrorToAuthFailure(dynamic error) {
    if (error is AuthException) {
      switch (error.message.toLowerCase()) {
        case 'invalid login credentials':
          return AuthFailureType.invalidCredentials;
        case 'user not found':
          return AuthFailureType.userNotFound;
        case 'email not confirmed':
          return AuthFailureType.emailNotVerified;
        case 'too many requests':
          return AuthFailureType.tooManyAttempts;
        case 'weak password':
          return AuthFailureType.weakPassword;
        case 'user already registered':
          return AuthFailureType.emailAlreadyExists;
        case 'invalid email':
          return AuthFailureType.invalidEmail;
        default:
          return AuthFailureType.unknown;
      }
    }
    return AuthFailureType.unknown;
  }
}
