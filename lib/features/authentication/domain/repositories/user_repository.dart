import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Abstract repository interface for user-related operations
/// 
/// Defines the contract for user data operations including
/// authentication, profile management, and preferences.
abstract class UserRepository {
  /// Get the currently authenticated user
  /// 
  /// Returns [Either] containing [AuthenticationFailure] on error 
  /// or [User] on success. Returns null if no user is authenticated.
  Future<Either<Failure, User?>> getCurrentUser();
  
  /// Sign in with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password
  /// 
  /// Returns [Either] containing [AuthenticationFailure] on error
  /// or [User] on successful authentication.
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  });
  
  /// Sign up with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password
  /// [name] - Optional display name
  /// 
  /// Returns [Either] containing [AuthenticationFailure] on error
  /// or [User] on successful registration.
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  });
  
  /// Sign out the current user
  /// 
  /// Returns [Either] containing [AuthenticationFailure] on error
  /// or [void] on success.
  Future<Either<Failure, void>> signOut();
  
  /// Update user profile information
  /// 
  /// [user] - Updated user object with new information
  /// 
  /// Returns [Either] containing [DatabaseFailure] on error
  /// or updated [User] on success.
  Future<Either<Failure, User>> updateProfile(User user);
  
  /// Update user reading preferences
  /// 
  /// [preferences] - Map of preference key-value pairs
  /// 
  /// Returns [Either] containing [DatabaseFailure] on error
  /// or updated [User] on success.
  Future<Either<Failure, User>> updateReadingPreferences(
    Map<String, dynamic> preferences,
  );
  
  /// Reset password for given email
  /// 
  /// [email] - Email address to send reset link to
  /// 
  /// Returns [Either] containing [AuthenticationFailure] on error
  /// or [void] on success.
  Future<Either<Failure, void>> resetPassword(String email);
  
  /// Verify email address
  /// 
  /// [token] - Email verification token
  /// 
  /// Returns [Either] containing [AuthenticationFailure] on error
  /// or [void] on success.
  Future<Either<Failure, void>> verifyEmail(String token);
  
  /// Change user password
  /// 
  /// [currentPassword] - Current password for verification
  /// [newPassword] - New password to set
  /// 
  /// Returns [Either] containing [AuthenticationFailure] on error
  /// or [void] on success.
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  /// Delete user account
  /// 
  /// Returns [Either] containing [AuthenticationFailure] on error
  /// or [void] on success.
  Future<Either<Failure, void>> deleteAccount();
  
  /// Refresh authentication token
  /// 
  /// Returns [Either] containing [AuthenticationFailure] on error
  /// or refreshed [User] on success.
  Future<Either<Failure, User>> refreshToken();
  
  /// Check if user is authenticated
  /// 
  /// Returns [true] if user has valid authentication session.
  Future<bool> isAuthenticated();
  
  /// Get user by ID
  /// 
  /// [userId] - Unique user identifier
  /// 
  /// Returns [Either] containing [DatabaseFailure] on error
  /// or [User] on success.
  Future<Either<Failure, User>> getUserById(String userId);
  
  /// Update user's last login timestamp
  /// 
  /// Returns [Either] containing [DatabaseFailure] on error
  /// or [void] on success.
  Future<Either<Failure, void>> updateLastLogin();
  
  /// Complete user onboarding
  /// 
  /// [preferences] - Initial user preferences from onboarding
  /// 
  /// Returns [Either] containing [DatabaseFailure] on error
  /// or updated [User] on success.
  Future<Either<Failure, User>> completeOnboarding(
    Map<String, dynamic> preferences,
  );
}
