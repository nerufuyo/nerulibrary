import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nerulibrary/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    testWidgets('Complete authentication flow works correctly', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify splash screen appears
      expect(find.text('LiteraLib'), findsOneWidget);
      
      // Wait for navigation to authentication or main screen
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Check if we're on the main screen or authentication screen
      final authFieldFinder = find.byType(TextField);
      final mainScreenFinder = find.text('Library'); // Assuming library tab exists
      
      if (authFieldFinder.evaluate().isNotEmpty) {
        // We're on authentication screen, test authentication flow
        await _testAuthenticationFlow(tester);
      } else if (mainScreenFinder.evaluate().isNotEmpty) {
        // We're already authenticated, test main app flow
        await _testMainAppFlow(tester);
      }
    });

    testWidgets('Authentication error handling works correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for authentication fields
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      final loginButtonFinder = find.text('Login');

      if (emailField.evaluate().isNotEmpty && passwordField.evaluate().isNotEmpty) {
        // Test invalid credentials
        await tester.enterText(emailField, 'invalid@email.com');
        await tester.enterText(passwordField, 'wrongpassword');
        await tester.pumpAndSettle();

        // Try to find login button
        final signInButtonFinder = find.text('Sign In');
        final buttonToTap = loginButtonFinder.evaluate().isNotEmpty 
            ? loginButtonFinder 
            : signInButtonFinder;

        if (buttonToTap.evaluate().isNotEmpty) {
          await tester.tap(buttonToTap);
          await tester.pumpAndSettle();

          // Check for error message (either 'error' or 'invalid' text)
          final errorFinder = find.textContaining('error');
          final invalidFinder = find.textContaining('invalid');
          
          expect(
            errorFinder.evaluate().isNotEmpty || invalidFinder.evaluate().isNotEmpty, 
            isTrue,
            reason: 'Should display error message for invalid credentials'
          );
        }
      }
    });
  });
}

Future<void> _testAuthenticationFlow(WidgetTester tester) async {
  // Find authentication form elements
  final textFields = find.byType(TextField);
  
  if (textFields.evaluate().length >= 2) {
    final emailField = textFields.first;
    final passwordField = textFields.last;
    
    // Enter valid test credentials
    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordField, 'testpassword');
    await tester.pumpAndSettle();
    
    // Find and tap login button
    final loginButtonFinder = find.text('Login');
    final signInButtonFinder = find.text('Sign In');
    final buttonToTap = loginButtonFinder.evaluate().isNotEmpty 
        ? loginButtonFinder 
        : signInButtonFinder;
        
    if (buttonToTap.evaluate().isNotEmpty) {
      await tester.tap(buttonToTap);
      await tester.pumpAndSettle();
      
      // Wait for authentication to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Verify we've navigated to main app
      final libraryFinder = find.text('Library');
      final homeFinder = find.text('Home');
      
      expect(
        libraryFinder.evaluate().isNotEmpty || homeFinder.evaluate().isNotEmpty,
        isTrue,
        reason: 'Should navigate to main app after successful authentication'
      );
    }
  }
}

Future<void> _testMainAppFlow(WidgetTester tester) async {
  // Test main navigation
  final libraryTab = find.text('Library');
  final discoverTab = find.text('Discover');
  
  // Test Library tab
  if (libraryTab.evaluate().isNotEmpty) {
    await tester.tap(libraryTab);
    await tester.pumpAndSettle();
    
    // Verify library content loads
    final listViewFinder = find.byType(ListView);
    final gridViewFinder = find.byType(GridView);
    
    expect(
      listViewFinder.evaluate().isNotEmpty || gridViewFinder.evaluate().isNotEmpty,
      isTrue,
      reason: 'Library should display list or grid view of books'
    );
  }
  
  // Test Discover tab
  if (discoverTab.evaluate().isNotEmpty) {
    await tester.tap(discoverTab);
    await tester.pumpAndSettle();
    
    // Verify discover content loads
    final textFieldFinder = find.byType(TextField);
    final searchTextFinder = find.text('Search');
    
    expect(
      textFieldFinder.evaluate().isNotEmpty || searchTextFinder.evaluate().isNotEmpty,
      isTrue,
      reason: 'Discover should have search functionality'
    );
  }
}
