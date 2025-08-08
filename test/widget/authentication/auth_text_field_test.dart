import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nerulibrary/features/authentication/presentation/widgets/auth_text_field.dart';

void main() {
  group('AuthTextField Widget Tests', () {
    testWidgets('displays label and hint correctly', (WidgetTester tester) async {
      const labelText = 'Email';
      const hintText = 'Enter your email';
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              labelText: labelText,
              hintText: hintText,
            ),
          ),
        ),
      );

      expect(find.text(labelText), findsOneWidget);
      expect(find.text(hintText), findsOneWidget);
    });

    testWidgets('shows prefix icon when provided', (WidgetTester tester) async {
      const iconData = Icons.email;
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              labelText: 'Email',
              prefixIcon: iconData,
            ),
          ),
        ),
      );

      expect(find.byIcon(iconData), findsOneWidget);
    });

    testWidgets('shows suffix icon when provided', (WidgetTester tester) async {
      const iconData = Icons.visibility;
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              labelText: 'Password',
              suffixIcon: iconData,
              onSuffixIconPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(iconData), findsOneWidget);
    });

    testWidgets('calls onSuffixIconPressed when suffix icon is tapped', (WidgetTester tester) async {
      bool wasTapped = false;
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              labelText: 'Password',
              suffixIcon: Icons.visibility,
              onSuffixIconPressed: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('obscures text when obscureText is true', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              labelText: 'Password',
              obscureText: true,
            ),
          ),
        ),
      );

      final authTextField = tester.widget<AuthTextField>(find.byType(AuthTextField));
      expect(authTextField.obscureText, isTrue);
    });

    testWidgets('does not obscure text when obscureText is false', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              labelText: 'Email',
              obscureText: false,
            ),
          ),
        ),
      );

      final authTextField = tester.widget<AuthTextField>(find.byType(AuthTextField));
      expect(authTextField.obscureText, isFalse);
    });

    testWidgets('calls validator when validation is triggered', (WidgetTester tester) async {
      String? validationResult;
      const invalidEmail = 'invalid-email';
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Form(
            child: Scaffold(
              body: AuthTextField(
                controller: controller,
                labelText: 'Email',
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), invalidEmail);
      await tester.pump();
      
      // Find the form field and trigger validation
      final formField = tester.widget<TextFormField>(find.byType(TextFormField));
      validationResult = formField.validator?.call(invalidEmail);
      
      expect(validationResult, equals('Please enter a valid email'));
    });

    testWidgets('accepts text input correctly', (WidgetTester tester) async {
      const inputText = 'test@example.com';
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              labelText: 'Email',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), inputText);
      await tester.pump();

      expect(controller.text, equals(inputText));
      expect(find.text(inputText), findsOneWidget);
    });

    testWidgets('applies correct keyboard type', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      final authTextField = tester.widget<AuthTextField>(find.byType(AuthTextField));
      expect(authTextField.keyboardType, equals(TextInputType.emailAddress));
    });

    testWidgets('displays error state correctly', (WidgetTester tester) async {
      const errorMessage = 'This field is required';
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Form(
            key: formKey,
            child: Scaffold(
              body: AuthTextField(
                controller: controller,
                labelText: 'Email',
                validator: (value) => errorMessage,
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('applies correct theming', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
            ),
          ),
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              labelText: 'Email',
            ),
          ),
        ),
      );

      final authTextField = tester.widget<AuthTextField>(find.byType(AuthTextField));
      expect(authTextField.labelText, equals('Email'));
    });

    testWidgets('handles enabled/disabled state correctly', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              labelText: 'Email',
              enabled: false,
            ),
          ),
        ),
      );

      final authTextField = tester.widget<AuthTextField>(find.byType(AuthTextField));
      expect(authTextField.enabled, isFalse);
    });

    testWidgets('controller updates text correctly', (WidgetTester tester) async {
      final controller = TextEditingController();
      const testText = 'Initial text';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              labelText: 'Email',
            ),
          ),
        ),
      );

      controller.text = testText;
      await tester.pump();

      expect(find.text(testText), findsOneWidget);
      expect(controller.text, equals(testText));
    });
  });
}
