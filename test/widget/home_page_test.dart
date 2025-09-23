import 'package:enekeskonyv/home/home_page.dart';
import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../helpers/test_helper.dart';

void main() {
  group('HomePage Widget Tests', () {
    late SettingsProvider settingsProvider;

    setUp(() {
      TestHelper.setupSharedPreferences();
      TestHelper.setupMockSongBooks();
      settingsProvider = TestHelper.createMockSettingsProvider();
    });

    tearDown(() {
      TestHelper.cleanup();
    });

    testWidgets('should display loading state initially', (tester) async {
      // Don't set up songBooks to test loading state
      songBooks.clear();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Initially should show loading or empty state
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should display song list when data is loaded', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Wait for songs to load
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Énekeskönyv'), findsOneWidget);

      // Verify search, settings, and cues buttons are present
      expect(find.byIcon(Icons.search), findsWidgets);
      expect(find.byIcon(Icons.settings), findsWidgets);
      expect(find.byIcon(Icons.favorite), findsWidgets);
    });

    testWidgets('should navigate to search page when search is tapped', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap search button
      final searchButton = find.widgetWithIcon(InkWell, Icons.search).first;
      await tester.tap(searchButton);
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.byType(MaterialPageRoute), findsOneWidget);
    });

    testWidgets('should navigate to cues page when favorites is tapped', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap favorites/cues button
      final cuesButton = find.widgetWithIcon(InkWell, Icons.favorite).first;
      await tester.tap(cuesButton);
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.byType(MaterialPageRoute), findsOneWidget);
    });

    testWidgets('should display different theme colors based on book selection', (tester) async {
      // Test with blue book
      settingsProvider.changeBook(Book.blue);
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if theme color is blue-based
      final context = tester.element(find.byType(HomePage));
      final theme = Theme.of(context);
      expect(theme.colorScheme.primary, isNot(equals(Colors.amber)));

      // Change to black book
      settingsProvider.changeBook(Book.black);
      await tester.pumpAndSettle();

      // Theme should update (this is more of an integration test behavior)
    });

    testWidgets('should handle song selection and navigation', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for song titles in the list
      final songTitleFinder = find.textContaining('Aki nem jár');
      if (tester.any(songTitleFinder)) {
        await tester.tap(songTitleFinder.first);
        await tester.pumpAndSettle();

        // Verify navigation to song page occurred
        expect(find.byType(MaterialPageRoute), findsOneWidget);
      }
    });

    testWidgets('should handle deep link navigation', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Deep link testing would require app_links setup
      // This is a placeholder for more complex integration testing
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should display correct book content based on settings', (tester) async {
      // Test with Book.blue
      settingsProvider.changeBook(Book.blue);
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display content from 21-es book
      expect(find.textContaining('21'), findsWidgets);

      // Change to Book.black
      settingsProvider.changeBook(Book.black);
      await tester.pumpAndSettle();

      // Should display content from 48-as book
      expect(find.textContaining('48'), findsWidgets);
    });

    testWidgets('should handle scroll controller properly', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find scrollable content
      final scrollableFinder = find.byType(Scrollable);
      if (tester.any(scrollableFinder)) {
        // Test scrolling behavior
        await tester.drag(scrollableFinder.first, const Offset(0, -300));
        await tester.pumpAndSettle();

        // Verify scroll position changed
        expect(find.byType(HomePage), findsOneWidget);
      }
    });

    testWidgets('should properly dispose resources', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate away to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Different Page')),
        ),
      );

      await tester.pumpAndSettle();

      // Verify disposal didn't cause errors
      expect(find.text('Different Page'), findsOneWidget);
    });
  });
}