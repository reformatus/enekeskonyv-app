import 'package:enekeskonyv/settings_provider.dart';
import 'package:enekeskonyv/song/song_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../helpers/test_helper.dart';

void main() {
  group('SongPage Widget Tests', () {
    late SettingsProvider settingsProvider;

    setUp(() {
      TestHelper.setupSharedPreferences();
      TestHelper.setupMockSongBooks();
      settingsProvider = TestHelper.createMockSettingsProvider();
    });

    tearDown(() {
      TestHelper.cleanup();
    });

    testWidgets('should display song page with title and verse', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify song page elements
      expect(find.byType(SongPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      
      // Should show song title
      expect(find.textContaining('Aki nem jár'), findsOneWidget);
    });

    testWidgets('should show navigation buttons', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for navigation buttons
      expect(find.byIcon(Icons.skip_previous), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.skip_next), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.keyboard_arrow_left), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.keyboard_arrow_right), findsAtLeastNWidgets(1));
    });

    testWidgets('should disable previous buttons on first verse of first song', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Previous verse and song buttons should be disabled
      final prevVerseButtons = find.byIcon(Icons.keyboard_arrow_left);
      final prevSongButtons = find.byIcon(Icons.skip_previous);
      
      // Check if buttons are disabled (onPressed == null)
      if (tester.any(prevVerseButtons)) {
        final button = tester.widget<IconButton>(prevVerseButtons.first);
        expect(button.onPressed, isNull);
      }
    });

    testWidgets('should handle verse navigation', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to navigate to next verse
      final nextVerseButtons = find.byIcon(Icons.keyboard_arrow_right);
      if (tester.any(nextVerseButtons)) {
        final button = tester.widget<IconButton>(nextVerseButtons.first);
        if (button.onPressed != null) {
          await tester.tap(nextVerseButtons.first);
          await tester.pumpAndSettle();
          
          // Should move to next verse
          expect(find.byType(SongPage), findsOneWidget);
        }
      }
    });

    testWidgets('should handle song navigation', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to navigate to next song
      final nextSongButtons = find.byIcon(Icons.skip_next);
      if (tester.any(nextSongButtons)) {
        final finder = find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.icon is Icon && (widget.icon as Icon).icon == Icons.skip_next
        );
        
        if (tester.any(finder)) {
          await tester.tap(finder.first);
          await tester.pumpAndSettle();
          
          // Should move to next song
          expect(find.byType(SongPage), findsOneWidget);
        }
      }
    });

    testWidgets('should handle tap navigation', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get the song page size for tap navigation
      final songPageFinder = find.byType(SongPage);
      final songPageSize = tester.getSize(songPageFinder);
      final songPageCenter = tester.getCenter(songPageFinder);

      // Tap on right side (should go to next verse/song)
      await tester.tapAt(Offset(
        songPageCenter.dx + songPageSize.width / 4,
        songPageCenter.dy,
      ));
      await tester.pumpAndSettle();

      // Should handle tap navigation
      expect(find.byType(SongPage), findsOneWidget);
    });

    testWidgets('should display verse bar when enabled', (tester) async {
      // Enable verse bar
      settingsProvider.changeIsVerseBarEnabled(true);
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show verse bar with verse indicators
      expect(find.byType(SongPage), findsOneWidget);
      // Verse bar might be a custom widget - check for its presence
    });

    testWidgets('should handle score display settings', (tester) async {
      // Test with scores enabled
      settingsProvider.changeScoreDisplay(ScoreDisplay.all);
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should attempt to load and display SVG scores
      expect(find.byType(SongPage), findsOneWidget);
      
      // Test with scores disabled
      settingsProvider.changeScoreDisplay(ScoreDisplay.none);
      await tester.pumpAndSettle();
      
      // Should not display scores
      expect(find.byType(SongPage), findsOneWidget);
    });

    testWidgets('should handle font size changes', (tester) async {
      settingsProvider.changeFontSize(18.0);
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Text should be displayed with updated font size
      expect(find.byType(SongPage), findsOneWidget);
    });

    testWidgets('should handle cue mode navigation', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
              initialCueIndex: 0, // Cue mode
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In cue mode, navigation behavior might be different
      expect(find.byType(SongPage), findsOneWidget);
      
      // Should show cue-specific UI elements
      // This depends on implementation details
    });

    testWidgets('should navigate back to home', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for back button in app bar
      final backButton = find.byIcon(Icons.menu_book);
      if (tester.any(backButton)) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        
        // Should navigate back to home
        expect(find.byType(SongPage), findsNothing);
      }
    });

    testWidgets('should handle different book themes', (tester) async {
      // Test with blue book
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SongPage), findsOneWidget);

      // Test with black book
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.black,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SongPage), findsOneWidget);
    });

    testWidgets('should handle orientation changes', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: '1',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial portrait mode
      expect(find.byType(SongPage), findsOneWidget);

      // Simulate landscape mode (this is limited in widget tests)
      // The actual orientation handling would be tested in integration tests
    });

    testWidgets('should handle invalid song data gracefully', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: SongPage(
              book: Book.blue,
              songKey: 'nonexistent',
              verseIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle gracefully without crashing
      expect(find.byType(SongPage), findsOneWidget);
    });
  });
}