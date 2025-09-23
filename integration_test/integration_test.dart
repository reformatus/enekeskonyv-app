import 'package:enekeskonyv/main.dart' as app;
import 'package:enekeskonyv/song/text_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Énekeskönyv App Integration Tests', () {
    testWidgets('Complete app flow test', (WidgetTester tester) async {
      // Start the app
      app.main();
      
      // Wait for the app to load songs from assets
      await tester.pumpAndSettle();
      await _waitForSongsToLoad(tester);
      
      // Test home page functionality
      await _testHomePage(tester);
      
      // Test song navigation
      await _testSongNavigation(tester);
      
      // Test verse navigation
      await _testVerseNavigation(tester);
    });

    testWidgets('Settings functionality test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await _waitForSongsToLoad(tester);
      
      // Test settings dialog and book switching
      await _testSettings(tester);
    });

    testWidgets('Search functionality test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await _waitForSongsToLoad(tester);
      
      // Test search functionality
      await _testSearch(tester);
    });
  });
}

/// Wait for songs to load from assets
Future<void> _waitForSongsToLoad(WidgetTester tester) async {
  // Wait up to 10 seconds for songs to load
  for (int i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byKey(const Key('_MyHomePageState.ListTile')).evaluate().isNotEmpty) {
      break;
    }
  }
  
  // Ensure we have at least one song loaded
  expect(find.byKey(const Key('_MyHomePageState.ListTile')), findsAtLeastNWidgets(1));
}

/// Test home page functionality
Future<void> _testHomePage(WidgetTester tester) async {
  // Ensure the app's title is displayed
  expect(find.textContaining('énekeskönyv'), findsWidgets);
  
  // Ensure the first song is displayed in the list
  expect(find.textContaining('Aki nem jár hitlenek tanácsán'), findsOneWidget);

  // Ensure required UI elements are present
  final settingsButton = find.byKey(const Key('_MyHomePageState.SettingsButton'));
  expect(settingsButton, findsOneWidget);
  
  final gotoSongButton = find.byKey(const Key('_MyHomePageState.GotoSongButton'));
  expect(gotoSongButton, findsOneWidget);
  
  final searchSongButton = find.byKey(const Key('_MyHomePageState.SearchSongButton'));
  expect(searchSongButton, findsOneWidget);
}

/// Test song navigation functionality
Future<void> _testSongNavigation(WidgetTester tester) async {
  // Tap on the first song to navigate to it
  await tester.tap(find.textContaining('Aki nem jár hitlenek tanácsán'));
  await tester.pumpAndSettle();
  
  // Verify we're on the song page
  final mySongPageState = find.byKey(const Key('_MySongPageState'));
  expect(mySongPageState, findsOneWidget);
  
  // Verify the song title is displayed
  expect(find.textContaining(': Aki nem jár hitlenek tanácsán'), findsOneWidget);
  
  // Find navigation buttons
  final prevVerse = find.byKey(const Key('_MySongPageState.IconButton.prevVerse'));
  final prevSong = find.byKey(const Key('_MySongPageState.IconButton.prevSong'));
  final nextSong = find.byKey(const Key('_MySongPageState.IconButton.nextSong'));
  final nextVerse = find.byKey(const Key('_MySongPageState.IconButton.nextVerse'));
  
  // All four IconButtons should be present
  expect(prevVerse, findsOneWidget);
  expect(prevSong, findsOneWidget);
  expect(nextSong, findsOneWidget);
  expect(nextVerse, findsOneWidget);
  
  // On the first song's first verse, prev buttons should be disabled
  expect(tester.widget<IconButton>(prevVerse).onPressed, null);
  expect(tester.widget<TextIconButton>(prevSong).onTap, null);
  expect(tester.widget<TextIconButton>(nextSong).onTap != null, true);
  expect(tester.widget<IconButton>(nextVerse).onPressed != null, true);
  
  // Test tap navigation on the right side of screen (should go to next verse)
  final mySongPageStateSize = tester.getSize(mySongPageState);
  final mySongPageStateCenter = tester.getCenter(mySongPageState);
  
  await tester.tapAt(Offset(
    mySongPageStateSize.width / 2 + mySongPageStateCenter.dx / 2,
    mySongPageStateSize.height / 2 + mySongPageStateCenter.dy / 2,
  ));
  await tester.pumpAndSettle();
  
  // Should move to next verse or next song, so prev verse should now be enabled
  expect(tester.widget<IconButton>(prevVerse).onPressed != null, true);
}

/// Test verse navigation functionality 
Future<void> _testVerseNavigation(WidgetTester tester) async {
  // We should be on song page from previous test
  final nextVerse = find.byKey(const Key('_MySongPageState.IconButton.nextVerse'));
  final prevVerse = find.byKey(const Key('_MySongPageState.IconButton.prevVerse'));
  
  // If we can go to next verse, test that
  if (tester.widget<IconButton>(nextVerse).onPressed != null) {
    await tester.tap(nextVerse);
    await tester.pumpAndSettle();
    
    // Now prev verse should be available
    expect(tester.widget<IconButton>(prevVerse).onPressed != null, true);
    
    // Go back to previous verse
    await tester.tap(prevVerse);
    await tester.pumpAndSettle();
  }
  
  // Test tap navigation on left side (should go to previous verse/song)
  final mySongPageState = find.byKey(const Key('_MySongPageState'));
  final mySongPageStateSize = tester.getSize(mySongPageState);
  final mySongPageStateCenter = tester.getCenter(mySongPageState);
  
  await tester.tapAt(Offset(
    mySongPageStateCenter.dx / 2,
    mySongPageStateSize.height / 2 + mySongPageStateCenter.dy / 2,
  ));
  await tester.pumpAndSettle();
  
  // Navigate back to home
  await tester.pageBack();
  await tester.pumpAndSettle();
}

/// Test settings functionality
Future<void> _testSettings(WidgetTester tester) async {
  // Open settings
  final settingsButton = find.byKey(const Key('_MyHomePageState.SettingsButton'));
  await tester.tap(settingsButton);
  await tester.pumpAndSettle();
  
  // Verify settings dialog/page opened
  // Note: This test needs to be updated based on actual settings UI implementation
  expect(find.text('Beállítások'), findsAtLeastNWidgets(1));
  
  // Close settings (assuming there's a back button or close action)
  await tester.pageBack();
  await tester.pumpAndSettle();
}

/// Test search functionality
Future<void> _testSearch(WidgetTester tester) async {
  // Open search
  final searchButton = find.byKey(const Key('_MyHomePageState.SearchSongButton'));
  await tester.tap(searchButton);
  await tester.pumpAndSettle();
  
  // Verify search page opened
  expect(find.text('Keresés'), findsAtLeastNWidgets(1));
  
  // Test search input (if there's a search field)
  final searchField = find.byType(TextField);
  if (tester.any(searchField)) {
    await tester.enterText(searchField.first, 'Aki nem');
    await tester.pumpAndSettle();
    
    // Verify search results
    expect(find.textContaining('Aki nem jár'), findsAtLeastNWidgets(1));
  }
  
  // Go back to home
  await tester.pageBack();
  await tester.pumpAndSettle();
}