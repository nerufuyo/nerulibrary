# nerulibrary

A comprehensive digital library application built with Flutter that provides users with access to a vast collection of public domain books. nerulibrary combines modern reading experiences with intelligent library management, offering seamless synchronization across devices and an intuitive interface for book discovery and reading.

## Project Overview

nerulibrary is designed to be a complete digital reading solution that aggregates content from multiple public domain sources including Project Gutenberg, Internet Archive, and OpenLibrary. The application focuses on providing users with a rich reading experience while maintaining high performance and reliability.

### Key Features

**Reading Experience**
- Multi-format support (PDF, EPUB, TXT)
- Customizable reading themes with 5 built-in options
- Advanced bookmarking and highlighting system
- Note-taking with rich text support
- Reading progress tracking across devices
- Cross-session reading state persistence

**Library Management**
- Intelligent book categorization and collections
- Advanced search with full-text indexing
- Duplicate detection and handling
- Library export and import functionality
- Offline reading capabilities

**Content Discovery**
- Integration with multiple public book APIs
- Comprehensive search across multiple sources
- Author and subject-based browsing
- Personalized recommendations

**Cloud Synchronization**
- Real-time sync with Supabase backend
- Intelligent conflict resolution
- Offline queue with retry logic
- Cross-device reading progress sync

**Performance & Quality**
- App startup time under 3 seconds
- Memory usage optimization
- Progressive image loading
- Database query optimization with caching
- Battery usage optimization

## Technology Stack

### Frontend
- **Flutter** 3.16+ with Material Design 3
- **Dart** 3.0+ with modern language features
- **Riverpod** 2.4+ for state management
- **go_router** for navigation

### Backend & Storage
- **Supabase** for authentication, database, and storage
- **SQLite** with sqflite for local data persistence
- **Flutter Secure Storage** for sensitive data

### Reading & File Handling
- **flutter_pdfview** for PDF reading
- **epubx** for EPUB support
- **path_provider** and **permission_handler** for file management

### Network & Performance
- **Dio** for HTTP requests with retry logic
- **connectivity_plus** for network state management
- **cached_network_image** for optimized image loading

## Project Structure

The application follows Clean Architecture principles with clear separation of concerns:

```
lib/
├── core/                    # Core utilities and configuration
│   ├── config/             # App, database, and API configuration
│   ├── constants/          # Application constants
│   ├── errors/             # Error handling and exceptions
│   ├── network/            # Network client configuration
│   ├── storage/            # Local and secure storage
│   └── utils/              # Common utilities
├── features/               # Feature-specific modules
│   ├── authentication/    # User authentication
│   ├── library/           # Library management
│   ├── reader/            # Book reading functionality
│   └── discovery/         # Content discovery
└── shared/                # Shared widgets and providers
    ├── widgets/           # Reusable UI components
    ├── providers/         # Global state providers
    └── extensions/        # Dart extensions
```

## API Integration

nerulibrary integrates with multiple public book APIs to provide comprehensive content access:

### Primary Sources
- **Project Gutenberg**: Public domain classics and literature
- **Internet Archive**: Diverse collection of books and documents
- **OpenLibrary**: Comprehensive book metadata and information

### Features
- Rate limiting and error handling for all API calls
- Comprehensive data validation and sanitization
- Local caching to reduce network usage
- Offline fallback mechanisms

## Development Status

The project is currently in production-ready state with all major features implemented and tested. All core functionality including reading experience, library management, content discovery, cloud synchronization, and performance optimization has been completed and verified.

## Installation

### Prerequisites
- Flutter SDK 3.16.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio or VS Code with Flutter extensions

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/nerufuyo/nerulibrary.git
   cd nerulibrary
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure environment variables:
   Create a `.env` file in the root directory with:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## Testing

The project maintains high test coverage with comprehensive testing strategy:

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test suites
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
```

Current test coverage: 80%+ with 72 tests passing (47 unit tests + 25 widget tests)

## Performance Benchmarks

- **App startup time**: Under 3 seconds
- **Memory usage**: Optimized with monitoring
- **Build size**: APK 36.9MB, AAB 56.9MB (with obfuscation)
- **Page navigation**: Under 500ms
- **Search performance**: Optimized with SQLite FTS and caching

## Contributing

This project follows strict development standards:

1. All code must pass static analysis (`dart analyze`)
2. Code formatting is enforced (`dart format`)
3. Test coverage must be maintained above 80%
4. All new features require comprehensive documentation
5. Follow the established project structure and patterns

## Security

- Security audit completed with 94/100 score
- OWASP compliance implemented
- Code obfuscation for release builds
- Secure storage for sensitive data
- Environment variable-based configuration

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments

This project aggregates content from various public domain sources:
- Project Gutenberg for classic literature
- Internet Archive for diverse book collections
- OpenLibrary for comprehensive book metadata

All content is provided under their respective open licenses and terms of use.
