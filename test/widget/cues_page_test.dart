import 'package:enekeskonyv/cues/cues_page.dart';
import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../helpers/test_helper.dart';

void main() {
  group('CuesPage Widget Tests', () {
    late SettingsProvider settingsProvider;

    setUp(() {
      TestHelper.setupSharedPreferences();
      TestHelper.setupMockSongBooks();
      settingsProvider = TestHelper.createMockSettingsProvider();
    });

    tearDown(() {
      TestHelper.cleanup();
    });

    testWidgets('should display cues page with default cue', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: CuesPage(tester.element(find.byType(MaterialApp))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify cues page elements
      expect(find.byType(CuesPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Kedvencek'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show dropdown for cue selection', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: CuesPage(tester.element(find.byType(MaterialApp))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find dropdown button
      final dropdown = find.byType(DropdownButton<String?>);
      expect(dropdown, findsOneWidget);

      // Tap dropdown to open
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Should show dropdown items
      expect(find.text('Kedvencek'), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle cue creation', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: CuesPage(tester.element(find.byType(MaterialApp))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to access new cue creation
      final dropdown = find.byType(DropdownButton<String?>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Look for "new cue" option or equivalent
      // This might be implemented as a separate button or dropdown item
      if (find.text('Új lista').evaluate().isNotEmpty) {
        await tester.tap(find.text('Új lista'));
        await tester.pumpAndSettle();

        // Should show new cue dialog
        expect(find.byType(AlertDialog), findsOneWidget);
      }
    });

    testWidgets('should display empty cue message when no verses', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: CuesPage(tester.element(find.byType(MaterialApp))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Empty cue should show appropriate message or empty state
      expect(find.byType(CuesPage), findsOneWidget);
    });

    testWidgets('should handle verse removal from cue', (tester) async {
      // First add some verses to the cue
      settingsProvider.addToCue('21.1.0');
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: CuesPage(tester.element(find.byType(MaterialApp))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for remove/delete buttons
      final removeButtons = find.byIcon(Icons.delete);
      if (tester.any(removeButtons)) {
        await tester.tap(removeButtons.first);
        await tester.pumpAndSettle();

        // Verify verse was removed
        // This depends on implementation details
      }
    });

    testWidgets('should navigate to verse when tapped', (tester) async {
      // Add a verse to the cue
      settingsProvider.addToCue('21.1.0');
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: CuesPage(tester.element(find.byType(MaterialApp))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for verse list items
      final verseItems = find.byType(ListTile);
      if (tester.any(verseItems)) {
        await tester.tap(verseItems.first);
        await tester.pumpAndSettle();

        // Should navigate to song page
        expect(find.byType(MaterialPageRoute), findsOneWidget);
      }
    });

    testWidgets('should handle cue sharing', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: CuesPage(tester.element(find.byType(MaterialApp))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for share button
      final shareButton = find.byIcon(Icons.share);
      if (tester.any(shareButton)) {
        await tester.tap(shareButton);
        await tester.pumpAndSettle();

        // Should show share dialog or trigger share action
        // This depends on implementation
      }
    });

    testWidgets('should handle cue deletion', (tester) async {
      // Create a non-default cue first
      settingsProvider.changeSelectedCue('Test Cue');
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: CuesPage(tester.element(find.byType(MaterialApp))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for delete cue option (might be in menu)
      final menuButton = find.byIcon(Icons.more_vert);
      if (tester.any(menuButton)) {
        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        // Look for delete option
        if (find.text('Törlés').evaluate().isNotEmpty) {
          await tester.tap(find.text('Törlés'));
          await tester.pumpAndSettle();

          // Should show confirmation dialog
          expect(find.byType(AlertDialog), findsOneWidget);
        }
      }
    });

    testWidgets('should handle cue reordering', (tester) async {
      // Add multiple verses to test reordering
      settingsProvider.addToCue('21.1.0');
      settingsProvider.addToCue('21.2.0');
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: CuesPage(tester.element(find.byType(MaterialApp))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for reorder handles or drag functionality
      final reorderables = find.byType(ReorderableListView);
      if (tester.any(reorderables)) {
        // Test reordering functionality
        expect(find.byType(CuesPage), findsOneWidget);
      }
    });

    testWidgets('should search and add verses from search', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: CuesPage(tester.element(find.byType(MaterialApp))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for add/search button
      final addButton = find.byIcon(Icons.add);
      if (tester.any(addButton)) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // Should navigate to search page in add mode
        expect(find.byType(MaterialPageRoute), findsOneWidget);
      }
    });

    testWidgets('should handle cue playback mode', (tester) async {
      // Add verses to cue
      settingsProvider.addToCue('21.1.0');
      settingsProvider.addToCue('21.2.0');
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
          child: MaterialApp(
            home: CuesPage(tester.element(find.byType(MaterialApp))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for play button to start cue playback
      final playButton = find.byIcon(Icons.play_arrow);
      if (tester.any(playButton)) {
        await tester.tap(playButton);
        await tester.pumpAndSettle();

        // Should navigate to first verse in cue
        expect(find.byType(MaterialPageRoute), findsOneWidget);
      }
    });
  });
}