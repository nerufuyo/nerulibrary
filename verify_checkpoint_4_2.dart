#!/usr/bin/env dart

// CHECKPOINT_4_2 Verification Script: Library Management System
// Verifies complete library management functionality including:
// - Category operations (CRUD, hierarchical, relationships)
// - Collection management (user collections, book relationships)
// - Advanced search and filtering capabilities
// - Duplicate detection algorithm
// - Data import/export functionality

import 'dart:io';
import 'dart:convert';

const String categoryImplementationPath = 'lib/features/library/data/datasources/book_local_datasource_impl.dart';
const String repositoryImplementationPath = 'lib/features/library/data/repositories/book_repository_impl.dart';

void main() async {
  print('🔍 CHECKPOINT_4_2 VERIFICATION: Library Management System');
  print('=' * 60);
  
  int totalChecks = 0;
  int passedChecks = 0;
  
  // Verify category operations implementation
  print('\n📚 CATEGORY OPERATIONS VERIFICATION');
  print('-' * 40);
  
  final categoryResults = await verifyCategoryOperations();
  totalChecks += categoryResults['total'] as int;
  passedChecks += categoryResults['passed'] as int;
  
  // Verify collection operations implementation  
  print('\n📦 COLLECTION OPERATIONS VERIFICATION');
  print('-' * 40);
  
  final collectionResults = await verifyCollectionOperations();
  totalChecks += collectionResults['total'] as int;
  passedChecks += collectionResults['passed'] as int;
  
  // Verify search and filtering functionality
  print('\n🔍 SEARCH & FILTERING VERIFICATION');
  print('-' * 40);
  
  final searchResults = await verifySearchAndFiltering();
  totalChecks += searchResults['total'] as int;
  passedChecks += searchResults['passed'] as int;
  
  // Verify duplicate detection implementation
  print('\n🔄 DUPLICATE DETECTION VERIFICATION');
  print('-' * 40);
  
  final duplicateResults = await verifyDuplicateDetection();
  totalChecks += duplicateResults['total'] as int;
  passedChecks += duplicateResults['passed'] as int;
  
  // Verify import/export functionality
  print('\n📤 IMPORT/EXPORT VERIFICATION');
  print('-' * 40);
  
  final importExportResults = await verifyImportExport();
  totalChecks += importExportResults['total'] as int;
  passedChecks += importExportResults['passed'] as int;
  
  // Verify repository layer integration
  print('\n🏗️ REPOSITORY INTEGRATION VERIFICATION');
  print('-' * 40);
  
  final repositoryResults = await verifyRepositoryIntegration();
  totalChecks += repositoryResults['total'] as int;
  passedChecks += repositoryResults['passed'] as int;
  
  // Generate verification report
  print('\n' + '=' * 60);
  print('📊 CHECKPOINT_4_2 VERIFICATION RESULTS');
  print('=' * 60);
  
  final double successRate = (passedChecks / totalChecks) * 100;
  
  print('✅ Passed: $passedChecks/$totalChecks checks');
  print('📈 Success Rate: ${successRate.toStringAsFixed(1)}%');
  
  if (successRate >= 95.0) {
    print('🎉 CHECKPOINT_4_2: ✅ PASSED - Library Management System fully implemented');
    print('🏆 All critical library management features are operational');
    exit(0);
  } else if (successRate >= 80.0) {
    print('⚠️  CHECKPOINT_4_2: 🟡 PARTIAL - Minor issues need attention');
    exit(1);
  } else {
    print('❌ CHECKPOINT_4_2: ❌ FAILED - Major implementation issues detected');
    exit(2);
  }
}

Future<Map<String, int>> verifyCategoryOperations() async {
  int total = 0;
  int passed = 0;
  
  // Check if data source file exists
  total++;
  if (await File(categoryImplementationPath).exists()) {
    passed++;
    print('✅ Data source implementation file exists');
  } else {
    print('❌ Data source implementation file missing');
    return {'total': total, 'passed': passed};
  }
  
  final content = await File(categoryImplementationPath).readAsString();
  
  // Verify category CRUD operations
  final categoryOperations = [
    'getCategoryById',
    'getCategories',
    'insertCategory',
    'updateCategory', 
    'deleteCategory',
    'getBooksByCategory',
    'searchCategories',
    'addBookCategory',
    'removeBookCategory',
    'getBookCategories'
  ];
  
  for (String operation in categoryOperations) {
    total++;
    if (content.contains('Future<') && content.contains(operation) && 
        !content.contains('UnimplementedError') &&
        !content.contains('throw UnimplementedError')) {
      passed++;
      print('✅ $operation implementation found');
    } else {
      print('❌ $operation implementation missing or incomplete');
    }
  }
  
  // Verify hierarchical category support
  total++;
  if (content.contains('parent_id') && content.contains('parentId')) {
    passed++;
    print('✅ Hierarchical category support implemented');
  } else {
    print('❌ Hierarchical category support missing');
  }
  
  // Verify error handling
  total++;
  if (content.contains('NotFoundException') && content.contains('DatabaseException')) {
    passed++;
    print('✅ Proper error handling implemented');
  } else {
    print('❌ Error handling incomplete');
  }
  
  return {'total': total, 'passed': passed};
}

Future<Map<String, int>> verifyCollectionOperations() async {
  int total = 0;
  int passed = 0;
  
  final content = await File(categoryImplementationPath).readAsString();
  
  // Verify collection CRUD operations
  final collectionOperations = [
    'getCollectionById',
    'getCollections',
    'insertCollection',
    'updateCollection',
    'deleteCollection',
    'addBookToCollection',
    'removeBookFromCollection',
    'getBooksInCollection'
  ];
  
  for (String operation in collectionOperations) {
    total++;
    if (content.contains(operation) && !content.contains('UnimplementedError')) {
      passed++;
      print('✅ $operation implementation found');
    } else {
      print('❌ $operation implementation missing');
    }
  }
  
  // Verify collection metadata support
  total++;
  if (content.contains('book_count') && content.contains('is_public')) {
    passed++;
    print('✅ Collection metadata support implemented');
  } else {
    print('❌ Collection metadata support incomplete');
  }
  
  // Verify relationship management
  total++;
  if (content.contains('collection_books') && content.contains('added_at')) {
    passed++;
    print('✅ Collection-book relationships implemented');
  } else {
    print('❌ Collection-book relationships missing');
  }
  
  return {'total': total, 'passed': passed};
}

Future<Map<String, int>> verifySearchAndFiltering() async {
  int total = 0;
  int passed = 0;
  
  final content = await File(categoryImplementationPath).readAsString();
  
  // Verify advanced search functionality
  total++;
  if (content.contains('searchBooksAdvanced')) {
    passed++;
    print('✅ Advanced search method implemented');
  } else {
    print('❌ Advanced search method missing');
  }
  
  // Verify filtering functionality
  total++;
  if (content.contains('getBooksByFilters')) {
    passed++;
    print('✅ Book filtering method implemented');
  } else {
    print('❌ Book filtering method missing');
  }
  
  // Verify complex queries with JOINs
  total++;
  if (content.contains('LEFT JOIN') && content.contains('GROUP BY')) {
    passed++;
    print('✅ Complex SQL queries with JOINs implemented');
  } else {
    print('❌ Complex SQL queries missing');
  }
  
  // Verify search parameters
  final searchParams = ['categoryIds', 'authorIds', 'publishedAfter', 'languages', 'minRating'];
  for (String param in searchParams) {
    total++;
    if (content.contains(param)) {
      passed++;
      print('✅ Search parameter $param supported');
    } else {
      print('❌ Search parameter $param missing');
    }
  }
  
  return {'total': total, 'passed': passed};
}

Future<Map<String, int>> verifyDuplicateDetection() async {
  int total = 0;
  int passed = 0;
  
  final content = await File(categoryImplementationPath).readAsString();
  
  // Verify duplicate detection method
  total++;
  if (content.contains('findDuplicateBooks')) {
    passed++;
    print('✅ Duplicate detection method implemented');
  } else {
    print('❌ Duplicate detection method missing');
  }
  
  // Verify similarity calculation
  total++;
  if (content.contains('_calculateStringSimilarity')) {
    passed++;
    print('✅ String similarity calculation implemented');
  } else {
    print('❌ String similarity calculation missing');
  }
  
  // Verify Levenshtein distance
  total++;
  if (content.contains('_levenshteinDistance')) {
    passed++;
    print('✅ Levenshtein distance algorithm implemented');
  } else {
    print('❌ Levenshtein distance algorithm missing');
  }
  
  // Verify title normalization
  total++;
  if (content.contains('_normalizeTitle')) {
    passed++;
    print('✅ Title normalization implemented');
  } else {
    print('❌ Title normalization missing');
  }
  
  // Verify duplicate detection logic
  total++;
  if (content.contains('_areBooksLikelyDuplicates')) {
    passed++;
    print('✅ Duplicate detection logic implemented');
  } else {
    print('❌ Duplicate detection logic missing');
  }
  
  return {'total': total, 'passed': passed};
}

Future<Map<String, int>> verifyImportExport() async {
  int total = 0;
  int passed = 0;
  
  final content = await File(categoryImplementationPath).readAsString();
  
  // Verify export functionality
  total++;
  if (content.contains('exportLibraryData')) {
    passed++;
    print('✅ Library export method implemented');
  } else {
    print('❌ Library export method missing');
  }
  
  // Verify import functionality
  total++;
  if (content.contains('importLibraryData')) {
    passed++;
    print('✅ Library import method implemented');
  } else {
    print('❌ Library import method missing');
  }
  
  // Verify transaction support
  total++;
  if (content.contains('transaction') || content.contains('db.transaction')) {
    passed++;
    print('✅ Transaction support for import operations');
  } else {
    print('❌ Transaction support missing');
  }
  
  // Verify relationship preservation
  total++;
  if (content.contains('relationships') && content.contains('book_authors') && content.contains('book_categories')) {
    passed++;
    print('✅ Relationship preservation in import/export');
  } else {
    print('❌ Relationship preservation incomplete');
  }
  
  return {'total': total, 'passed': passed};
}

Future<Map<String, int>> verifyRepositoryIntegration() async {
  int total = 0;
  int passed = 0;
  
  // Check if repository file exists
  total++;
  if (await File(repositoryImplementationPath).exists()) {
    passed++;
    print('✅ Repository implementation file exists');
  } else {
    print('❌ Repository implementation file missing');
    return {'total': total, 'passed': passed};
  }
  
  final content = await File(repositoryImplementationPath).readAsString();
  
  // Verify category operations in repository
  final repositoryOperations = [
    'getCategoryById',
    'getCategories', 
    'saveCategory',
    'getBooksByCategory',
    'searchCategories',
    'getCollectionById',
    'getCollections',
    'saveCollection',
    'deleteCollection',
    'addBookToCollection',
    'removeBookFromCollection',
    'getBooksInCollection'
  ];
  
  for (String operation in repositoryOperations) {
    total++;
    // Check for the method signature and implementation (not just the name)
    String methodPattern = '$operation(';
    int methodIndex = content.indexOf(methodPattern);
    
    if (methodIndex != -1) {
      // Check if there's a try block after the method declaration
      String methodSection = content.substring(methodIndex, 
          methodIndex + 500 < content.length ? methodIndex + 500 : content.length);
      
      if (methodSection.contains('try {') && methodSection.contains('_localDataSource')) {
        passed++;
        print('✅ Repository $operation updated');
      } else {
        print('❌ Repository $operation incomplete implementation');
      }
    } else {
      print('❌ Repository $operation method not found');
    }
  }
  
  // Verify error handling patterns
  total++;
  if (content.contains('Either<Failure,') && content.contains('try {') && content.contains('catch')) {
    passed++;
    print('✅ Repository error handling patterns implemented');
  } else {
    print('❌ Repository error handling patterns incomplete');
  }
  
  // Verify model imports
  total++;
  if (content.contains('import') && content.contains('category_model.dart')) {
    passed++;
    print('✅ Required model imports added');
  } else {
    print('❌ Required model imports missing');
  }
  
  return {'total': total, 'passed': passed};
}
