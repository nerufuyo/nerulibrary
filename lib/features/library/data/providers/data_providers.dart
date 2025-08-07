import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/database_config.dart';
import '../datasources/book_local_datasource.dart';
import '../datasources/book_local_datasource_impl.dart';
import '../repositories/book_repository_impl.dart';
import '../../domain/repositories/book_repository.dart';

/// Provider for database configuration
final databaseConfigProvider = Provider<DatabaseConfig>((ref) {
  return DatabaseConfig.instance;
});

/// Provider for book local data source
final bookLocalDataSourceProvider = Provider<BookLocalDataSource>((ref) {
  final databaseConfig = ref.read(databaseConfigProvider);
  return BookLocalDataSourceImpl(databaseConfig: databaseConfig);
});

/// Provider for book repository
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final localDataSource = ref.read(bookLocalDataSourceProvider);
  return BookRepositoryImpl(localDataSource: localDataSource);
});

/// Provider for database initialization
final databaseInitializationProvider = FutureProvider<void>((ref) async {
  final databaseConfig = ref.read(databaseConfigProvider);
  // Initialize database by accessing it
  await databaseConfig.database;
});
