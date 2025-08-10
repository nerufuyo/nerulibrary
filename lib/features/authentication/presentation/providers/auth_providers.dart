import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/datasources/user_remote_datasource_impl.dart';
import '../../data/datasources/user_local_datasource.dart';
import '../../data/datasources/user_local_datasource_impl.dart';

/// Authentication-related providers for the app
///
/// Contains all Riverpod providers for user authentication,
/// user state management, and related dependencies.

// Core dependency providers
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

// Repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.read(userRemoteDataSourceProvider),
    localDataSource: ref.read(userLocalDataSourceProvider),
    secureStorage: ref.read(secureStorageProvider),
    supabaseClient: ref.read(supabaseClientProvider),
  );
});

// Data source providers
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSourceImpl(
    supabaseClient: ref.read(supabaseClientProvider),
  );
});

final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSourceImpl();
});

// User state provider
final currentUserProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  return UserNotifier(ref.read(userRepositoryProvider));
});

// Auth notifier provider (alias for currentUserProvider for better semantics)
final authNotifierProvider = currentUserProvider;

/// User state notifier for managing current user state
class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final UserRepository _userRepository;

  UserNotifier(this._userRepository) : super(const AsyncValue.data(null));

  /// Load current user
  Future<void> loadCurrentUser() async {
    state = const AsyncValue.loading();

    final result = await _userRepository.getCurrentUser();

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();

    final result = await _userRepository.signInWithEmail(
      email: email,
      password: password,
    );

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  /// Sign in with email and password (alias method)
  Future<void> signInWithEmail(
      {required String email, required String password}) async {
    await signIn(email, password);
  }

  /// Sign up with email and password
  Future<void> signUp(String email, String password, {String? name}) async {
    state = const AsyncValue.loading();

    final result = await _userRepository.signUpWithEmail(
      email: email,
      password: password,
      name: name,
    );

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    final result = await _userRepository.signOut();

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  /// Update user profile
  Future<void> updateProfile(User user) async {
    final result = await _userRepository.updateProfile(user);

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (updatedUser) => state = AsyncValue.data(updatedUser),
    );
  }
}
