import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

/// Abstract interface for remote user data operations
/// 
/// Defines the contract for user-related remote operations
/// including authentication and profile management with Supabase.
abstract class UserRemoteDataSource {
  /// Get the currently authenticated user from remote
  Future<Either<Failure, UserModel>> getCurrentUser();
  
  /// Sign in with email and password
  Future<Either<Failure, UserModel>> signInWithEmail({
    required String email,
    required String password,
  });
  
  /// Sign up with email and password
  Future<Either<Failure, UserModel>> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  });
  
  /// Sign out the current user
  Future<Either<Failure, void>> signOut();
  
  /// Update user profile information
  Future<Either<Failure, UserModel>> updateProfile(UserModel user);
  
  /// Update user reading preferences
  Future<Either<Failure, UserModel>> updateReadingPreferences(
    Map<String, dynamic> preferences,
  );
  
  /// Reset password for given email
  Future<Either<Failure, void>> resetPassword(String email);
  
  /// Verify email address
  Future<Either<Failure, void>> verifyEmail(String token);
  
  /// Change user password
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  /// Delete user account
  Future<Either<Failure, void>> deleteAccount();
  
  /// Refresh authentication token
  Future<Either<Failure, UserModel>> refreshToken();
  
  /// Get user by ID
  Future<Either<Failure, UserModel>> getUserById(String userId);
  
  /// Update user's last login timestamp
  Future<Either<Failure, void>> updateLastLogin();
  
  /// Complete user onboarding
  Future<Either<Failure, UserModel>> completeOnboarding(
    Map<String, dynamic> preferences,
  );
}
