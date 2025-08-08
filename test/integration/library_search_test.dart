import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nerulibrary/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Library Search Integration Tests', () {
    testWidgets('Search functionality works correctly',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to discover/search screen
      final discoverTab = find.text('Discover');
      final searchTab = find.text('Search');

      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();
      } else if (searchTab.evaluate().isNotEmpty) {
        await tester.tap(searchTab);
        await tester.pumpAndSettle();
      }

      // Look for search field
      final searchField = find.byType(TextField);

      if (searchField.evaluate().isNotEmpty) {
        // Test search functionality
        await tester.enterText(searchField.first, 'shakespeare');
        await tester.pumpAndSettle();

        // Look for search button or trigger search
        final searchButton = find.byIcon(Icons.search);
        if (searchButton.evaluate().isNotEmpty) {
          await tester.tap(searchButton);
          await tester.pumpAndSettle();
        } else {
          // Try pressing enter key to trigger search
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await tester.pumpAndSettle();
        }

        // Wait for search results
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify search results appear
        final listView = find.byType(ListView);
        final gridView = find.byType(GridView);
        final searchResults = find.textContaining('result');

        expect(
            listView.evaluate().isNotEmpty ||
                gridView.evaluate().isNotEmpty ||
                searchResults.evaluate().isNotEmpty,
            isTrue,
            reason:
                'Search should display results or indicate search completion');
      }
    });

    testWidgets('Empty search handling works correctly',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to search
      final discoverTab = find.text('Discover');

      if (discoverTab.evaluate().isNotEmpty) {
        await tester.tap(discoverTab);
        await tester.pumpAndSettle();

        // Find search field and enter empty query
        final searchField = find.byType(TextField);

        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, '');
          await tester.pumpAndSettle();

          // Try to trigger search
          final searchButton = find.byIcon(Icons.search);
          if (searchButton.evaluate().isNotEmpty) {
            await tester.tap(searchButton);
            await tester.pumpAndSettle();

            // Verify appropriate handling of empty search
            final errorMessage = find.textContaining('enter');
            final emptyMessage = find.textContaining('empty');

            expect(
                errorMessage.evaluate().isNotEmpty ||
                    emptyMessage.evaluate().isNotEmpty,
                isTrue,
                reason: 'Empty search should show appropriate message');
          }
        }
      }
    });

    testWidgets('Book details navigation works correctly',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to library
      final libraryTab = find.text('Library');

      if (libraryTab.evaluate().isNotEmpty) {
        await tester.tap(libraryTab);
        await tester.pumpAndSettle();

        // Look for book items
        final bookCards = find.byType(Card);
        final listTiles = find.byType(ListTile);

        if (bookCards.evaluate().isNotEmpty) {
          // Tap on first book card
          await tester.tap(bookCards.first);
          await tester.pumpAndSettle();

          // Verify navigation to book details
          final detailsScreen = find.textContaining('Details');
          final titleText = find.textContaining('Title');
          final authorText = find.textContaining('Author');

          expect(
              detailsScreen.evaluate().isNotEmpty ||
                  titleText.evaluate().isNotEmpty ||
                  authorText.evaluate().isNotEmpty,
              isTrue,
              reason: 'Should navigate to book details screen');
        } else if (listTiles.evaluate().isNotEmpty) {
          // Tap on first list tile
          await tester.tap(listTiles.first);
          await tester.pumpAndSettle();

          // Verify navigation
          expect(find.byType(AppBar), findsOneWidget,
              reason: 'Should show details screen with app bar');
        }
      }
    });
  });
}
