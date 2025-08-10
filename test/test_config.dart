/// Test configuration for LiteraLib
///
/// This file contains centralized test configuration and utilities
/// that can be used across all test files.
library;

// Test configuration constants
class TestConfig {
  static const String testDatabaseName = 'test_literalib.db';
  static const String testTemporaryPath = '/tmp';
  static const String testDocumentsPath = '/tmp/documents';

  // Test timeout configuration
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(minutes: 2);

  // Test data constants
  static const String testBookTitle = 'Test Book Title';
  static const String testAuthorName = 'Test Author';
  static const String testBookContent = 'Sample book content for testing';

  static const Map<String, dynamic> testUserData = {
    'id': 'test-user-id',
    'email': 'test@example.com',
    'name': 'Test User',
  };

  static const Map<String, dynamic> testBookData = {
    'id': 'test-book-id',
    'title': testBookTitle,
    'author': testAuthorName,
    'isbn': '1234567890',
    'published_year': 2023,
    'language': 'en',
    'file_size': 1024,
    'page_count': 100,
  };

  // Private constructor
  TestConfig._();
}
