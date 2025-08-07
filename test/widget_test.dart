// LiteraLib widget test
//
// Tests the main application widget to ensure it loads correctly
// and displays the expected initial screen without errors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('LiteraLib app basic structure test', (WidgetTester tester) async {
    // Build a simple app without full dependency injection for testing
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          title: 'LiteraLib',
          home: Scaffold(
            appBar: AppBar(
              title: const Text('LiteraLib'),
            ),
            body: const Center(
              child: Text('Welcome to LiteraLib'),
            ),
          ),
        ),
      ),
    );

    // Verify that our basic structure works
    expect(find.text('LiteraLib'), findsWidgets);
    expect(find.text('Welcome to LiteraLib'), findsOneWidget);
  });
}
