import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';
import 'user_remote_datasource.dart';

/// Concrete implementation of UserRemoteDataSource using Supabase
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient _supabaseClient;

  UserRemoteDataSourceImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  @override
  Future<Either<Failure, UserModel>> getCurrentUser() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return Left(AuthenticationFailure(
          message: 'No authenticated user found',
          type: AuthFailureType.sessionExpired,
        ));
      }

      // Get additional user data from profiles table
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final userModel = UserModel.fromSupabaseUser(user, response);
      return Right(userModel);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: AuthFailureType.unknown,
      ));
    } on PostgrestException catch (e) {
      return Left(DatabaseFailure(
        message: e.message,
        operation: 'getCurrentUser',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to get current user: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return Left(AuthenticationFailure(
          message: 'Sign in failed',
          type: AuthFailureType.invalidCredentials,
        ));
      }

      // Get user profile data
      final profileResponse = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      final userModel =
          UserModel.fromSupabaseUser(response.user!, profileResponse);
      return Right(userModel);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: _mapAuthExceptionToFailureType(e),
      ));
    } on PostgrestException catch (e) {
      return Left(DatabaseFailure(
        message: e.message,
        operation: 'signInWithEmail',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to sign in: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'display_name': name} : null,
      );

      if (response.user == null) {
        return Left(AuthenticationFailure(
          message: 'Sign up failed',
          type: AuthFailureType.unknown,
        ));
      }

      // Create profile entry
      final profileData = {
        'id': response.user!.id,
        'name': name,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabaseClient.from('profiles').insert(profileData);

      final userModel = UserModel.fromSupabaseUser(response.user!, profileData);
      return Right(userModel);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: _mapAuthExceptionToFailureType(e),
      ));
    } on PostgrestException catch (e) {
      return Left(DatabaseFailure(
        message: e.message,
        operation: 'signUpWithEmail',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to sign up: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: AuthFailureType.unknown,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to sign out: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, UserModel>> updateProfile(UserModel user) async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        return Left(AuthenticationFailure(
          message: 'No authenticated user',
          type: AuthFailureType.sessionExpired,
        ));
      }

      // Update auth user metadata if needed
      if (user.email != currentUser.email) {
        await _supabaseClient.auth.updateUser(
          UserAttributes(email: user.email),
        );
      }

      // Update profile table
      final profileData = {
        'name': user.name,
        'avatar_url': user.avatarUrl,
        'reading_theme': user.readingTheme,
        'font_family': user.fontFamily,
        'font_size': user.fontSize,
        'is_dark_mode': user.isDarkMode,
        'timezone': user.timezone,
        'language_code': user.languageCode,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseClient
          .from('profiles')
          .update(profileData)
          .eq('id', user.id)
          .select()
          .single();

      final updatedUser = UserModel.fromSupabaseUser(currentUser, response);
      return Right(updatedUser);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: AuthFailureType.unknown,
      ));
    } on PostgrestException catch (e) {
      return Left(DatabaseFailure(
        message: e.message,
        operation: 'updateProfile',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to update profile: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, UserModel>> updateReadingPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        return Left(AuthenticationFailure(
          message: 'No authenticated user',
          type: AuthFailureType.sessionExpired,
        ));
      }

      final response = await _supabaseClient
          .from('profiles')
          .update({
            'reading_theme': preferences['theme'],
            'font_family': preferences['fontFamily'],
            'font_size': preferences['fontSize'],
            'is_dark_mode': preferences['isDarkMode'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser.id)
          .select()
          .single();

      final userModel = UserModel.fromSupabaseUser(currentUser, response);
      return Right(userModel);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: AuthFailureType.unknown,
      ));
    } on PostgrestException catch (e) {
      return Left(DatabaseFailure(
        message: e.message,
        operation: 'updateReadingPreferences',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to update reading preferences: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: AuthFailureType.unknown,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to reset password: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail(String token) async {
    try {
      await _supabaseClient.auth.verifyOTP(
        type: OtpType.email,
        token: token,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: AuthFailureType.unknown,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to verify email: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: AuthFailureType.unknown,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to change password: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        return Left(AuthenticationFailure(
          message: 'No authenticated user',
          type: AuthFailureType.sessionExpired,
        ));
      }

      // Delete profile data
      await _supabaseClient.from('profiles').delete().eq('id', currentUser.id);

      // Sign out user
      await _supabaseClient.auth.signOut();

      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: AuthFailureType.unknown,
      ));
    } on PostgrestException catch (e) {
      return Left(DatabaseFailure(
        message: e.message,
        operation: 'deleteAccount',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to delete account: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, UserModel>> refreshToken() async {
    try {
      final response = await _supabaseClient.auth.refreshSession();
      if (response.user == null) {
        return Left(AuthenticationFailure(
          message: 'Failed to refresh token',
          type: AuthFailureType.sessionExpired,
        ));
      }

      final profileResponse = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      final userModel =
          UserModel.fromSupabaseUser(response.user!, profileResponse);
      return Right(userModel);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: AuthFailureType.sessionExpired,
      ));
    } on PostgrestException catch (e) {
      return Left(DatabaseFailure(
        message: e.message,
        operation: 'refreshToken',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to refresh token: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, UserModel>> getUserById(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // For getUserById, we create the user from profile data only
      final userModel = UserModel.fromJson({
        'id': response['id'],
        'email': response['email'] ?? '',
        'name': response['name'],
        'avatar_url': response['avatar_url'],
        'reading_theme': response['reading_theme'],
        'font_family': response['font_family'],
        'font_size': response['font_size'],
        'is_dark_mode': response['is_dark_mode'] ?? false,
        'timezone': response['timezone'],
        'language_code': response['language_code'],
        'is_onboarding_completed': response['is_onboarding_completed'] ?? false,
        'is_premium': response['is_premium'] ?? false,
        'subscription_status': response['subscription_status'],
        'created_at':
            response['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at':
            response['updated_at'] ?? DateTime.now().toIso8601String(),
        'last_login_at': response['last_login_at'],
      });

      return Right(userModel);
    } on PostgrestException catch (e) {
      return Left(DatabaseFailure(
        message: e.message,
        operation: 'getUserById',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to get user by ID: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastLogin() async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        return Left(AuthenticationFailure(
          message: 'No authenticated user',
          type: AuthFailureType.sessionExpired,
        ));
      }

      await _supabaseClient.from('profiles').update({
        'last_login_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser.id);

      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: AuthFailureType.unknown,
      ));
    } on PostgrestException catch (e) {
      return Left(DatabaseFailure(
        message: e.message,
        operation: 'updateLastLogin',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to update last login: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, UserModel>> completeOnboarding(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        return Left(AuthenticationFailure(
          message: 'No authenticated user',
          type: AuthFailureType.sessionExpired,
        ));
      }

      final response = await _supabaseClient
          .from('profiles')
          .update({
            'reading_theme': preferences['theme'],
            'font_family': preferences['fontFamily'],
            'font_size': preferences['fontSize'],
            'is_dark_mode': preferences['isDarkMode'],
            'is_onboarding_completed': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser.id)
          .select()
          .single();

      final userModel = UserModel.fromSupabaseUser(currentUser, response);
      return Right(userModel);
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        type: AuthFailureType.unknown,
      ));
    } on PostgrestException catch (e) {
      return Left(DatabaseFailure(
        message: e.message,
        operation: 'completeOnboarding',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to complete onboarding: $e',
      ));
    }
  }

  /// Maps Supabase AuthException to AuthFailureType
  AuthFailureType _mapAuthExceptionToFailureType(AuthException exception) {
    switch (exception.statusCode) {
      case '400':
        if (exception.message.toLowerCase().contains('invalid')) {
          return AuthFailureType.invalidCredentials;
        }
        return AuthFailureType.invalidEmail;
      case '422':
        return AuthFailureType.weakPassword;
      case '429':
        return AuthFailureType.tooManyAttempts;
      default:
        return AuthFailureType.unknown;
    }
  }
}
