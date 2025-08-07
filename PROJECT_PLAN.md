# LiteraLib Development Planning & Guidelines

## Table of Contents
- [Project Overview](#project-overview)
- [Development Phases](#development-phases)
- [Project Structure](#project-structure)
- [Code Structure Guidelines](#code-structure-guidelines)
- [Git Workflow & Commit Standards](#git-workflow--commit-standards)
- [Development Environment](#development-environment)
- [Testing Strategy](#testing-strategy)
- [Documentation Standards](#documentation-standards)
- [Quality Assurance](#quality-assurance)

---

## Project Overview

### Technology Stack
- **Frontend:** Flutter 3.16+ with Dart 3.0+
- **State Management:** Riverpod 2.4+
- **Backend:** Supabase (Auth, Database, Storage)
- **Local Database:** SQLite with sqflite package
- **HTTP Client:** Dio for API calls
- **Storage:** Flutter Secure Storage
- **File Handling:** path_provider, permission_handler
- **PDF/EPUB Reader:** flutter_pdfview, epubx
- **UI Components:** Material Design 3

### Core Dependencies
```yaml
# State Management
flutter_riverpod: ^2.4.0
riverpod_annotation: ^2.3.0

# Backend & Storage
supabase_flutter: ^1.10.0
sqflite: ^2.3.0
flutter_secure_storage: ^9.0.0

# HTTP & Network
dio: ^5.3.0
connectivity_plus: ^4.0.0

# File & Storage
path_provider: ^2.1.0
permission_handler: ^11.0.0

# Book Readers
flutter_pdfview: ^1.3.0
epubx: ^0.5.0

# UI & Utils
cached_network_image: ^3.3.0
shimmer: ^3.0.0
```

---

## Development Phases

### Phase 1: Foundation Setup (Weeks 1-2)
**Scope:** Project initialization, architecture setup, basic navigation

**Deliverables:**
- Project structure implementation
- Riverpod providers setup
- Basic navigation with go_router
- Supabase configuration
- Authentication system (basic)

**Limitations:**
- No UI customization beyond Material Design defaults
- Basic error handling only
- No offline functionality yet
- Single platform focus (Android first)

**Success Criteria:**
- App builds and runs successfully
- User can register/login
- Basic navigation works
- Code follows established structure

### Phase 2: Core Reading Infrastructure (Weeks 3-5)
**Scope:** Book management, file handling, basic reader

**Deliverables:**
- Local database schema implementation
- File download and storage system
- Basic PDF/EPUB reader
- Book metadata management
- Search functionality (local only)

**Limitations:**
- Single format support per iteration
- No reading customization
- Basic UI without theming
- No sync functionality
- Limited error recovery

**Success Criteria:**
- Users can download and store books
- Basic reading functionality works
- Search returns relevant results
- File management is stable

### Phase 3: Enhanced Reading Experience (Weeks 6-8)
**Scope:** Reading customization, bookmarks, notes, progress tracking

**Deliverables:**
- Reading theme system
- Bookmark functionality
- Note-taking system
- Reading progress tracking
- Basic statistics

**Limitations:**
- Limited theme options (3-4 themes max)
- Basic note formatting only
- No export functionality
- No advanced statistics
- Single device only

**Success Criteria:**
- Reading experience is customizable
- Users can save bookmarks and notes
- Progress is tracked accurately
- Performance remains smooth

### Phase 4: Content Discovery & Management (Weeks 9-11)
**Scope:** Book discovery, library management, cloud sync

**Deliverables:**
- Integration with book APIs
- Advanced search and filtering
- Library organization features
- Cloud synchronization
- Offline content management

**Limitations:**
- Limited API integrations (2-3 sources max)
- Basic filtering options only
- No social features
- Simple sync (no conflict resolution)
- Limited offline search

**Success Criteria:**
- Users can discover new books easily
- Library organization is intuitive
- Sync works reliably
- Offline mode is functional

### Phase 5: Polish & Optimization (Weeks 12-14)
**Scope:** Performance optimization, UI refinement, testing

**Deliverables:**
- Performance optimization
- UI/UX improvements
- Comprehensive testing
- Bug fixes and stability improvements
- Documentation completion

**Limitations:**
- No new features
- Focus on existing functionality only
- Limited platform testing
- Basic analytics only

**Success Criteria:**
- App performance meets standards
- UI is polished and consistent
- Test coverage > 80%
- No critical bugs remain

---

## Project Structure

### Directory Structure
```
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── database_config.dart
│   │   └── supabase_config.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── api_constants.dart
│   │   └── storage_constants.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   ├── failures.dart
│   │   └── error_handler.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── network_info.dart
│   │   └── api_endpoints.dart
│   ├── storage/
│   │   ├── local_storage.dart
│   │   ├── secure_storage.dart
│   │   └── file_manager.dart
│   └── utils/
│       ├── app_utils.dart
│       ├── date_utils.dart
│       └── validation_utils.dart
├── features/
│   ├── authentication/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── widgets/
│   │       └── providers/
│   ├── library/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── reader/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── discovery/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/
│   ├── widgets/
│   │   ├── buttons/
│   │   ├── inputs/
│   │   ├── cards/
│   │   └── common/
│   ├── providers/
│   │   ├── app_providers.dart
│   │   └── global_providers.dart
│   └── extensions/
│       ├── string_extensions.dart
│       ├── context_extensions.dart
│       └── widget_extensions.dart
├── app.dart
└── main.dart

assets/
├── fonts/
├── icons/
├── images/
└── json/

test/
├── unit/
├── widget/
├── integration/
└── mocks/

docs/
├── api/
├── architecture/
└── deployment/
```

---

## Code Structure Guidelines

### File Naming Conventions
- **Files:** snake_case (e.g., `user_repository.dart`)
- **Classes:** PascalCase (e.g., `UserRepository`)
- **Variables/Functions:** camelCase (e.g., `getCurrentUser`)
- **Constants:** SCREAMING_SNAKE_CASE (e.g., `API_BASE_URL`)

### Class Structure Template
```dart
// Import order: dart -> flutter -> packages -> relative
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Brief description of the class purpose
/// 
/// Detailed description if needed
/// Example usage if complex
class UserRepository {
  // Private fields first
  final SupabaseClient _supabaseClient;
  final String _tableName = 'users';
  
  // Constructor
  const UserRepository({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;
  
  // Public methods
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // Implementation
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
  
  // Private methods last
  String _formatUserData(Map<String, dynamic> data) {
    // Implementation
  }
}
```

### Provider Structure
```dart
// Provider definition at the top
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    supabaseClient: ref.read(supabaseClientProvider),
  );
});

// Notifier class for state management
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  AsyncValue<User?> build() {
    return const AsyncValue.data(null);
  }
  
  Future<void> loadUser() async {
    state = const AsyncValue.loading();
    
    final repository = ref.read(userRepositoryProvider);
    final result = await repository.getCurrentUser();
    
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }
}
```

### Error Handling Pattern
```dart
// Use Either pattern for error handling
import 'package:dartz/dartz.dart';

Future<Either<Failure, T>> performOperation<T>() async {
  try {
    final result = await _riskyOperation();
    return Right(result);
  } on NetworkException catch (e) {
    return Left(NetworkFailure(message: e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message));
  } catch (e) {
    return Left(UnknownFailure(message: e.toString()));
  }
}
```

### Widget Structure
```dart
class BookCard extends ConsumerWidget {
  // Required parameters first
  final Book book;
  
  // Optional parameters with defaults
  final VoidCallback? onTap;
  final bool isSelected;
  
  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.isSelected = false,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Early returns for edge cases
    if (book.title.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Build method body
    return Card(
      child: ListTile(
        title: Text(book.title),
        onTap: onTap,
      ),
    );
  }
}
```

---

## Git Workflow & Commit Standards

### Branch Strategy
- **main:** Production-ready code only
- **develop:** Integration branch for features
- **feature/[feature-name]:** Individual feature development
- **hotfix/[issue-description]:** Critical bug fixes
- **release/[version]:** Release preparation

### Commit Message Format
```
type(scope): subject

body

footer
```

### Commit Types
- **feat:** New feature
- **fix:** Bug fix
- **docs:** Documentation changes
- **style:** Code style changes (formatting, no logic change)
- **refactor:** Code refactoring
- **test:** Adding or updating tests
- **chore:** Build process or auxiliary tool changes

### Examples
```
feat(auth): implement user authentication with supabase

Add login and registration functionality using Supabase auth.
Includes form validation, error handling, and state management
with Riverpod providers.

Closes #123

fix(reader): resolve pdf rendering issue on android devices

The PDF viewer was crashing on Android 12+ due to memory
allocation problems. Implemented lazy loading and memory
management improvements.

Fixes #145

docs(readme): update installation instructions

Add missing Flutter version requirements and Supabase setup
steps for local development environment.

test(library): add unit tests for book repository

Implement comprehensive test coverage for CRUD operations
including edge cases and error scenarios.

Coverage: 95%
```

### Commit Rules
1. **Subject line max 50 characters**
2. **Body wrapped at 72 characters**
3. **Use imperative mood** (Add, Fix, Update, not Added, Fixed, Updated)
4. **Reference issues/PRs in footer**
5. **No emojis in commit messages**
6. **Separate subject from body with blank line**

### Branch Naming
```
feature/user-authentication
feature/book-reader-ui
fix/pdf-rendering-crash
hotfix/critical-auth-bug
release/v1.0.0
```

### Pull Request Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Widget tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No console.log or print statements

## Screenshots (if applicable)

## Related Issues
Closes #123
```

---

## Development Environment

### Required Tools
- **Flutter SDK:** 3.16.0 or higher
- **Dart SDK:** 3.0.0 or higher
- **Android Studio:** Latest stable version
- **VS Code:** With Flutter and Dart extensions
- **Git:** Latest version

### VS Code Settings
```json
{
  "dart.flutterSdkPath": "path/to/flutter",
  "dart.lineLength": 80,
  "editor.rulers": [80],
  "editor.formatOnSave": true,
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  "files.exclude": {
    "**/.dart_tool": true,
    "**/build": true
  }
}
```

### Environment Variables
```
# .env file
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
API_BASE_URL=https://api.example.com
DEBUG_MODE=true
```

---

## Testing Strategy

### Test Structure
```
test/
├── unit/
│   ├── core/
│   ├── features/
│   │   ├── authentication/
│   │   ├── library/
│   │   └── reader/
│   └── shared/
├── widget/
│   ├── pages/
│   └── widgets/
├── integration/
│   ├── app_test.dart
│   └── flows/
└── mocks/
    ├── mock_repositories.dart
    └── mock_data.dart
```

### Test Coverage Requirements
- **Unit Tests:** > 80% coverage
- **Widget Tests:** All custom widgets
- **Integration Tests:** Critical user flows
- **Golden Tests:** UI consistency

### Test Naming Convention
```dart
// Pattern: should_[expected_behavior]_when_[condition]
void main() {
  group('UserRepository', () {
    test('should_return_user_when_authentication_succeeds', () async {
      // Test implementation
    });
    
    test('should_throw_exception_when_network_fails', () async {
      // Test implementation
    });
  });
}
```

---

## Documentation Standards

### Code Documentation
```dart
/// Retrieves the current authenticated user from the repository.
/// 
/// Returns [Either] containing [Failure] on error or [User] on success.
/// Throws [NetworkException] if network connectivity is unavailable.
/// 
/// Example:
/// ```dart
/// final result = await userRepository.getCurrentUser();
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (user) => print('User: ${user.name}'),
/// );
/// ```
Future<Either<Failure, User>> getCurrentUser() async {
  // Implementation
}
```

### README Structure
```markdown
# Feature Name

## Overview
Brief description of the feature

## Architecture
Explanation of the architectural decisions

## Usage
Code examples and usage instructions

## Testing
How to run tests for this feature

## Known Issues
List of known limitations or issues
```

---

## Quality Assurance

### Code Quality Checklist
- [ ] Follows naming conventions
- [ ] Proper error handling implemented
- [ ] Comments added for complex logic
- [ ] No hardcoded values
- [ ] Responsive design considerations
- [ ] Performance optimizations applied
- [ ] Memory leaks prevented
- [ ] Accessibility features included

### Performance Standards
- **App startup time:** < 3 seconds
- **Page navigation:** < 500ms
- **Image loading:** Progressive loading implemented
- **Memory usage:** < 100MB baseline
- **Build size:** < 50MB release APK

### Code Review Checklist
- [ ] Code follows established patterns
- [ ] Tests are comprehensive
- [ ] Documentation is updated
- [ ] Performance impact assessed
- [ ] Security considerations reviewed
- [ ] Edge cases handled
- [ ] Error messages are user-friendly

### Release Criteria
- [ ] All tests pass
- [ ] Code coverage > 80%
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Release notes prepared

---

## Progress Tracking Checkpoints

### MANDATORY CHECKPOINT VERIFICATION
**AI ASSISTANT MUST VERIFY EACH CHECKPOINT BEFORE PROCEEDING TO NEXT TASK**

### Phase 1 Checkpoints: Foundation Setup
```
CHECKPOINT_1_1: Project Structure Setup
[ ] Directory structure matches specification exactly
[ ] All required folders created with correct naming
[ ] pubspec.yaml contains all mandatory dependencies
[ ] Environment configuration files created
[ ] Git repository initialized with correct branch structure
VERIFICATION_REQUIRED: Directory tree screenshot or ls -la output

CHECKPOINT_1_2: Core Configuration Implementation
[ ] app_config.dart implemented with all required constants
[ ] database_config.dart with SQLite setup
[ ] supabase_config.dart with environment variables
[ ] dio_client.dart with proper error handling
[ ] All config files follow exact naming conventions
VERIFICATION_REQUIRED: Config files compilation without errors

CHECKPOINT_1_3: Authentication Foundation
[ ] User entity implemented following template structure
[ ] UserRepository with Either pattern error handling
[ ] Authentication providers implemented with Riverpod
[ ] Login/Register pages created with proper structure
[ ] All authentication files pass static analysis
VERIFICATION_REQUIRED: Authentication flow compiles and runs

CHECKPOINT_1_4: Navigation Setup
[ ] go_router implementation with all required routes
[ ] App navigation structure matches specification
[ ] Route guards implemented for authentication
[ ] Navigation follows Material Design patterns
[ ] No navigation memory leaks detected
VERIFICATION_REQUIRED: Navigation flow demonstration
```

### Phase 2 Checkpoints: Core Reading Infrastructure
```
CHECKPOINT_2_1: Database Schema Implementation
[ ] SQLite tables created following exact schema specification
[ ] Database migration system implemented
[ ] CRUD operations for all entities implemented
[ ] Foreign key relationships properly configured
[ ] Database queries optimized with indexes
VERIFICATION_REQUIRED: Database schema export and query performance tests

CHECKPOINT_2_2: File Management System
[ ] File download manager implemented with queue system
[ ] Local storage management with path_provider
[ ] File permission handling implemented
[ ] Storage cleanup mechanisms implemented
[ ] File integrity verification implemented
VERIFICATION_REQUIRED: File operations testing with various file sizes

CHECKPOINT_2_3: Book Reader Implementation
[ ] PDF reader integrated with flutter_pdfview
[ ] EPUB reader integrated with epubx package
[ ] Basic reader UI implemented following design system
[ ] Reader navigation (page turning) implemented
[ ] Memory management for large files implemented
VERIFICATION_REQUIRED: Reader performance test with 50MB+ files

CHECKPOINT_2_4: Search Functionality
[ ] Local search implementation with SQLite FTS
[ ] Search indexing for book metadata
[ ] Search results pagination implemented
[ ] Search performance optimization completed
[ ] Search filters implementation completed
VERIFICATION_REQUIRED: Search performance benchmarks documented
```

### Phase 3 Checkpoints: Enhanced Reading Experience
```
CHECKPOINT_3_1: Theme System Implementation
[ ] Theme provider implemented with Riverpod
[ ] Minimum 4 reading themes implemented
[ ] Font family selection (minimum 3 fonts)
[ ] Font size adjustment (8 levels minimum)
[ ] Dark/light mode implementation
VERIFICATION_REQUIRED: Theme switching demonstration without app restart

CHECKPOINT_3_2: Reading Tools Implementation
[ ] Bookmark system with local storage
[ ] Highlighting system with color options
[ ] Note-taking with rich text support
[ ] Reading position persistence
[ ] Cross-session reading state management
VERIFICATION_REQUIRED: Reading tools data persistence test

CHECKPOINT_3_3: Progress Tracking System
[ ] Reading progress calculation algorithm
[ ] Progress visualization components
[ ] Reading statistics data model
[ ] Progress sync across book formats
[ ] Reading time tracking implementation
VERIFICATION_REQUIRED: Progress accuracy test with manual verification
```

### Phase 4 Checkpoints: Content Discovery & Management
```
CHECKPOINT_4_1: API Integration Implementation
[ ] Project Gutenberg API integration completed
[ ] Internet Archive API integration completed
[ ] OpenLibrary API integration completed
[ ] API rate limiting implementation
[ ] API error handling and retry logic
VERIFICATION_REQUIRED: API integration test suite with 100% success rate

CHECKPOINT_4_2: Library Management System
[ ] Book categorization system implemented
[ ] Collection management with CRUD operations
[ ] Library search and filtering
[ ] Duplicate book detection and handling
[ ] Library export/import functionality
VERIFICATION_REQUIRED: Library operations stress test with 1000+ books

CHECKPOINT_4_3: Cloud Synchronization
[ ] Supabase sync implementation
[ ] Conflict resolution for reading progress
[ ] Offline queue for sync operations
[ ] Sync status indicators for user
[ ] Data integrity verification post-sync
VERIFICATION_REQUIRED: Multi-device sync test demonstration
```

### Phase 5 Checkpoints: Polish & Optimization
```
CHECKPOINT_5_1: Performance Optimization
[ ] App startup time under 3 seconds verified
[ ] Memory usage optimization completed
[ ] Image loading optimization implemented
[ ] Database query optimization completed
[ ] Battery usage optimization verified
VERIFICATION_REQUIRED: Performance benchmarks documented

CHECKPOINT_5_2: Quality Assurance
[ ] Unit test coverage above 80% verified
[ ] Widget test coverage for all custom widgets
[ ] Integration tests for critical flows implemented
[ ] Code analysis score above 95% achieved
[ ] No memory leaks detected in testing
VERIFICATION_REQUIRED: Test coverage report and analysis results

CHECKPOINT_5_3: Production Readiness
[ ] Release build optimization completed
[ ] Code obfuscation implemented
[ ] Security audit completed with no critical issues
[ ] App signing configuration completed
[ ] Release documentation completed
VERIFICATION_REQUIRED: Production build testing on multiple devices
```

---

## Public Book Resources API Integration

### Primary APIs (MANDATORY IMPLEMENTATION)
```
API_RESOURCE_1: Project Gutenberg
Base URL: https://www.gutenberg.org/ebooks/
Format: JSON, EPUB, PDF, TXT
License: Public Domain
Rate Limit: No official limit, implement 1 request/second
Implementation Priority: CRITICAL

Endpoints Required:
- GET /ebooks/search/?query={search_term}&format=json
- GET /ebooks/{book_id}.epub.noimages
- GET /ebooks/{book_id}.pdf
- GET /ebooks/{book_id}/pg{book_id}.txt

Error Handling Required:
- Network timeout (30 seconds)
- 404 book not found
- Rate limit exceeded
- Invalid format requests
```

```
API_RESOURCE_2: Internet Archive Books
Base URL: https://archive.org/
Format: JSON metadata, PDF, EPUB
License: Various (public domain focus)
Rate Limit: 100 requests/minute
Implementation Priority: CRITICAL

Endpoints Required:
- GET /advancedsearch.php?q=mediatype:texts&output=json
- GET /metadata/{identifier}
- GET /download/{identifier}/{filename}
- GET /services/search/v1/scrape?q={query}&count=100

Authentication: Not required for public domain
Rate Limiting: Implement exponential backoff
```

```
API_RESOURCE_3: OpenLibrary
Base URL: https://openlibrary.org/
Format: JSON
License: Open Data
Rate Limit: 100 requests/minute
Implementation Priority: HIGH

Endpoints Required:
- GET /search.json?q={query}&limit=20
- GET /works/{work_id}.json
- GET /api/books?bibkeys={identifiers}&format=json
- GET /authors/{author_id}.json

Metadata Focus: Book information, covers, author details
```

```
API_RESOURCE_4: DOAB (Directory of Open Access Books)
Base URL: https://directory.doabooks.org/
Format: JSON, XML
License: Open Access
Rate Limit: Implement 2 requests/second
Implementation Priority: MEDIUM

Endpoints Required:
- GET /rest/search?query={search_term}&expand=metadata
- GET /rest/books/{book_id}?expand=download
- GET /rest/subjects
```

### Secondary APIs (OPTIONAL ENHANCEMENT)
```
API_RESOURCE_5: Indonesian Digital Library
Base URL: https://lib.ui.ac.id/ (Example)
Focus: Indonesian academic content
Implementation: Post-MVP if available

API_RESOURCE_6: arXiv (Academic Papers)
Base URL: http://export.arxiv.org/
Focus: Scientific papers and preprints
Implementation: Phase 4 extension
```

### API Integration Requirements
```
INTEGRATION_RULE_1: Error Handling
All API calls MUST implement comprehensive error handling:
- Network connectivity errors
- HTTP status error codes (400, 401, 403, 404, 429, 500, 502, 503)
- JSON parsing errors
- Rate limit exceeded errors
- Timeout errors (30 second maximum)

INTEGRATION_RULE_2: Rate Limiting
All APIs MUST implement proper rate limiting:
- Request queue system with priority
- Exponential backoff for failures
- Respect API provider rate limits
- Local caching to reduce API calls
- Offline fallback mechanisms

INTEGRATION_RULE_3: Data Validation
All API responses MUST be validated:
- JSON schema validation
- Required field presence check
- Data type validation
- Sanitization of user-facing content
- Malformed data rejection

INTEGRATION_RULE_4: Caching Strategy
All API data MUST be cached appropriately:
- Book metadata cached for 24 hours
- Search results cached for 1 hour
- Author information cached for 7 days
- Cover images cached permanently
- Cache invalidation on app updates
```

### API Implementation Template
```dart
/// Template for all API service implementations
abstract class BookApiService {
  /// Search books with query string
  /// Returns paginated results with metadata
  Future<Either<ApiFailure, SearchResult>> searchBooks({
    required String query,
    int page = 1,
    int limit = 20,
  });
  
  /// Get detailed book information
  Future<Either<ApiFailure, BookDetail>> getBookDetail(String bookId);
  
  /// Get download URL for book file
  Future<Either<ApiFailure, DownloadInfo>> getDownloadUrl({
    required String bookId,
    required BookFormat format,
  });
  
  /// Validate API connectivity and rate limits
  Future<Either<ApiFailure, ApiStatus>> checkApiStatus();
}

class ProjectGutenbergService implements BookApiService {
  final Dio _dio;
  final CacheManager _cacheManager;
  static const String _baseUrl = 'https://www.gutenberg.org';
  static const Duration _timeout = Duration(seconds: 30);
  
  // Implementation following exact error handling patterns
}
```

---

## STRICT DEVELOPMENT ENFORCEMENT

### CODE QUALITY GATES (MANDATORY)
```
QUALITY_GATE_1: Pre-Commit Validation
MANDATORY_CHECKS_BEFORE_ANY_COMMIT:
[ ] dart analyze returns 0 issues
[ ] dart format --set-exit-if-changed passes
[ ] All unit tests pass (flutter test)
[ ] No TODO comments in production code
[ ] No print statements or debugPrint calls
[ ] No hardcoded strings (use constants)
[ ] All public APIs have documentation comments

AUTOMATED_REJECTION_CRITERIA:
- Any commit with failing tests will be rejected
- Any code with analysis issues will be rejected
- Any code without proper error handling will be rejected
```

```
QUALITY_GATE_2: Code Review Requirements
MANDATORY_REVIEW_CHECKLIST:
[ ] Code follows exact project structure specification
[ ] All new code has corresponding tests
[ ] Error handling uses Either pattern consistently
[ ] All dependencies are properly injected via Riverpod
[ ] Performance impact has been assessed
[ ] Security implications have been considered
[ ] Documentation is complete and accurate

REJECTION_CRITERIA:
- Code that deviates from established patterns
- Missing or inadequate test coverage
- Performance regressions
- Security vulnerabilities
```

```
QUALITY_GATE_3: Integration Requirements
MANDATORY_INTEGRATION_CHECKS:
[ ] All API integrations have proper error handling
[ ] Rate limiting is implemented for all external calls
[ ] Data validation is comprehensive
[ ] Offline functionality works without degradation
[ ] Memory usage remains within acceptable limits
[ ] App startup time remains under 3 seconds
```

### ZERO TOLERANCE POLICIES
```
POLICY_1: No Shortcuts
- No bypass of error handling for "quick fixes"
- No direct widget creation without following design system
- No API calls without proper rate limiting
- No data persistence without validation
- No UI updates without loading states

POLICY_2: Performance Standards
- All list views must implement lazy loading
- All images must be cached and optimized
- All database queries must be indexed
- All network requests must have timeout handling
- All animations must be 60fps capable

POLICY_3: Testing Requirements
- Every new feature must have unit tests
- Every UI component must have widget tests
- Every API integration must have integration tests
- Every critical path must have golden tests
- Test coverage below 80% blocks deployment
```

### MILESTONE APPROVAL PROCESS
```
MILESTONE_APPROVAL_REQUIRED:
Each phase completion requires formal approval based on:
1. All checkpoints verified and documented
2. Code quality gates passed
3. Performance benchmarks met
4. Security review completed
5. Documentation updated and accurate

APPROVAL_DOCUMENTATION:
- Checkpoint verification screenshots/outputs
- Performance benchmark reports
- Test coverage reports
- Code analysis results
- Security audit results

NO_EXCEPTIONS_POLICY:
No advancement to next phase without complete approval
No feature additions without proper foundation
No deployment without full quality assurance
```

---

## AI Assistant Mandatory Compliance

### BEFORE EVERY CODE CONTRIBUTION
```
AI_COMPLIANCE_CHECKLIST:
[ ] Current phase checkpoint status verified
[ ] All previous checkpoints completed and documented
[ ] Code follows exact template specifications
[ ] Error handling implemented with Either pattern
[ ] Tests written for all new functionality
[ ] Performance impact assessed
[ ] Security implications reviewed
[ ] Documentation updated accordingly

MANDATORY_VERIFICATION:
AI must request and verify:
1. Current project state
2. Completed checkpoints
3. Pending requirements
4. Quality gate status
```

### STRICT COMMUNICATION PROTOCOL
```
REQUIRED_FORMAT_FOR_CODE_SUBMISSIONS:

CHECKPOINT_STATUS: [Current Phase].[Current Checkpoint]
DEPENDENCIES_VERIFIED: [List of verified dependencies]
TESTING_COMPLETED: [Test types and results]
PERFORMANCE_IMPACT: [Measured impact on app performance]
SECURITY_REVIEW: [Security considerations addressed]

CODE_SUBMISSION:
[Actual code with proper documentation]

VERIFICATION_EVIDENCE:
[Screenshots, test results, benchmark data]
```

This development plan serves as the **IMMUTABLE SPECIFICATION** for all development activities. Any deviations require formal change control process with documented justification and approval.