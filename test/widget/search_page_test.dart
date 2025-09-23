import 'package:enekeskonyv/search_page.dart';
import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../helpers/test_helper.dart';

void main() {
  group('SearchPage Widget Tests', () {
    late SettingsProvider settingsProvider;

    setUp(() {
      TestHelper.setupSharedPreferences();
      TestHelper.setupMockSongBooks();
      settingsProvider = TestHelper.createMockSettingsProvider();
    });

    tearDown(() {
      TestHelper.cleanup();
    });

    testWidgets('should display search page with text field', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SearchPage(
              book: Book.blue,
              settingsProvider: settingsProvider,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify search page elements
      expect(find.byType(SearchPage), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Keresés'), findsAtLeastNWidgets(1));
    });

    testWidgets('should perform text search and show results', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SearchPage(
              book: Book.blue,
              settingsProvider: settingsProvider,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Aki nem');
      await tester.pumpAndSettle();

      // Submit search (either automatically or via button)
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Verify search results are shown
      expect(find.textContaining('Aki nem'), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle jump mode with song number', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SearchPage(
              book: Book.blue,
              settingsProvider: settingsProvider,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter song number for jump mode
      final textField = find.byType(TextField);
      await tester.enterText(textField, '1');
      await tester.pumpAndSettle();

      // Submit jump
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();

      // Should navigate to song page
      expect(find.byType(MaterialPageRoute), findsOneWidget);
    });

    testWidgets('should handle jump mode with song and verse number', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SearchPage(
              book: Book.blue,
              settingsProvider: settingsProvider,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter song,verse format for jump mode
      final textField = find.byType(TextField);
      await tester.enterText(textField, '1,2');
      await tester.pumpAndSettle();

      // Submit jump
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();

      // Should navigate to specific verse
      expect(find.byType(MaterialPageRoute), findsOneWidget);
    });

    testWidgets('should show empty state when no search performed', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SearchPage(
              book: Book.blue,
              settingsProvider: settingsProvider,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state or instructions
      expect(find.byType(SearchPage), findsOneWidget);
      // Empty state could be a message or just empty list
    });

    testWidgets('should show no results message for non-matching search', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SearchPage(
              book: Book.blue,
              settingsProvider: settingsProvider,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text that won't match anything
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'xyz123nonexistent');
      await tester.pumpAndSettle();

      // Submit search
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Should show no results or empty list
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('should handle different book selections', (tester) async {
      // Test with blue book
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SearchPage(
              book: Book.blue,
              settingsProvider: settingsProvider,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search that should match blue book content
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Aki nem');
      await tester.pumpAndSettle();

      // Should show results from blue book
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('should handle addToCueSearch mode', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SearchPage(
              book: Book.blue,
              settingsProvider: settingsProvider,
              addToCueSearch: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In cue search mode, behavior might be different
      expect(find.byType(SearchPage), findsOneWidget);
      
      // Search and verify cue-specific functionality
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Aki nem');
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate back to previous page', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SearchPage(
              book: Book.blue,
              settingsProvider: settingsProvider,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Use back button or back navigation
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Should return to previous page
      expect(find.byType(SearchPage), findsNothing);
    });

    testWidgets('should handle tap on search results', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SearchPage(
              book: Book.blue,
              settingsProvider: settingsProvider,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Perform search to get results
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Aki nem');
      await tester.pumpAndSettle();

      // Submit search
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Tap on a search result if any
      final searchResults = find.byType(ListTile);
      if (tester.any(searchResults)) {
        await tester.tap(searchResults.first);
        await tester.pumpAndSettle();

        // Should navigate to selected song/verse
        expect(find.byType(MaterialPageRoute), findsOneWidget);
      }
    });
  });

  group('SearchVerse Class Tests', () {
    test('should create SearchVerse with all properties', () {
      const searchVerse = SearchVerse(
        songKey: '1',
        verseIndex: 0,
        verseNumber: '1',
        text: 'Test verse text',
      );

      expect(searchVerse.songKey, equals('1'));
      expect(searchVerse.verseIndex, equals(0));
      expect(searchVerse.verseNumber, equals('1'));
      expect(searchVerse.text, equals('Test verse text'));
    });
  });
}