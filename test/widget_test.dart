// Salam Quran App - Widget Tests
//
// This file contains widget tests for the Salam Quran application.
// Tests verify UI components render correctly and user interactions work as expected.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:salam/presentation/providers/enhanced_theme_provider.dart';

void main() {
  group('Salam Quran App Widget Tests', () {
    testWidgets('MaterialApp renders with theme provider (smoke test)',
        (WidgetTester tester) async {
      // Smoke test: Verify that app structure doesn't crash on initialization
      final themeProvider = EnhancedThemeProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: themeProvider,
          child: Consumer<EnhancedThemeProvider>(
            builder: (context, provider, _) {
              return MaterialApp(
                theme: provider.lightTheme,
                darkTheme: provider.darkTheme,
                themeMode: provider.themeMode,
                home: const Scaffold(
                  body: Center(child: Text('Salam Quran App')),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app renders without errors
      expect(find.text('Salam Quran App'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('EnhancedThemeProvider provides valid light and dark themes',
        (WidgetTester tester) async {
      final themeProvider = EnhancedThemeProvider();

      // Verify themes are not null and have proper structure
      expect(themeProvider.lightTheme, isNotNull);
      expect(themeProvider.darkTheme, isNotNull);
      expect(themeProvider.themeMode, isNotNull);

      // Verify themes have required properties
      expect(themeProvider.lightTheme.brightness, equals(Brightness.light));
      expect(themeProvider.darkTheme.brightness, equals(Brightness.dark));
    });

    testWidgets('Simple Icon widget renders correctly',
        (WidgetTester tester) async {
      // Basic widget rendering test
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Icon(Icons.book, size: 48),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify icon renders
      expect(find.byIcon(Icons.book), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Basic Text widget renders with Arabic content',
        (WidgetTester tester) async {
      // Test Arabic text rendering (critical for Quran app)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Arabic text renders without errors
      expect(
          find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
    });
  });
}
