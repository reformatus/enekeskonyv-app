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
      // Use a more robust waiting mechanism
      await tester.pumpAndSettle();
      
      // Wait for songs to load by checking for list tiles
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
    // Ensure the app's title is displayed.
    expect(find.textContaining('énekeskönyv'), findsWidgets);
    // Ensure the first song is displayed in the list.
    expect(
        find.textContaining('Aki nem jár hitlenek tanácsán'), findsOneWidget);

    // Ensure there is one of these buttons each.
    final settingsButton =
        find.byKey(const Key('_MyHomePageState.SettingsButton'));
    expect(settingsButton, findsOneWidget);
    final gotoSongButton =
        find.byKey(const Key('_MyHomePageState.GotoSongButton'));
    expect(gotoSongButton, findsOneWidget);
    final searchSongButton =
        find.byKey(const Key('_MyHomePageState.SearchSongButton'));
    expect(searchSongButton, findsOneWidget);

    // Now let's do some song/verse navigation tests, starting from the first
    // page.
    await tester.tap(find.textContaining('Aki nem jár hitlenek tanácsán'));
    await tester.pumpAndSettle();
    final mySongPageState = find.byKey(const Key('_MySongPageState'));
    expect(mySongPageState, findsOneWidget);
    expect(
        find.textContaining(': Aki nem jár hitlenek tanácsán'), findsOneWidget);
    final prevVerse =
        find.byKey(const Key('_MySongPageState.IconButton.prevVerse'));
    final prevSong =
        find.byKey(const Key('_MySongPageState.IconButton.prevSong'));
    final nextSong =
        find.byKey(const Key('_MySongPageState.IconButton.nextSong'));
    final nextVerse =
        find.byKey(const Key('_MySongPageState.IconButton.nextVerse'));
    // All four IconButtons should be present...
    expect(prevVerse, findsOneWidget);
    expect(prevSong, findsOneWidget);
    expect(nextSong, findsOneWidget);
    expect(nextVerse, findsOneWidget);
    // ...but only the first two should be disabled.
    expect(tester.widget<IconButton>(prevVerse).onPressed, null);
    expect(tester.widget<TextIconButton>(prevSong).onTap, null);
    expect(tester.widget<TextIconButton>(nextSong).onTap != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed != null, true);
    // Tapping the left half of the song page should switch to the previous
    // verse, even if it's the previous song's last verse - but only if there
    // _is_ a previous song/verse.
    final mySongPageStateCenter = tester.getCenter(mySongPageState);
    final mySongPageStateSize = tester.getSize(mySongPageState);
    await tester.tapAt(Offset(
        mySongPageStateSize.width / 2 - mySongPageStateCenter.dx / 2,
        mySongPageStateSize.height / 2 - mySongPageStateCenter.dy / 2));
    await tester.pumpAndSettle();
    // So only the first two IconButtons should be disabled still.
    expect(tester.widget<IconButton>(prevVerse).onPressed, null);
    expect(tester.widget<TextIconButton>(prevSong).onTap, null);
    expect(tester.widget<TextIconButton>(nextSong).onTap != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed != null, true);
    // Now let's navigate to the second verse.
    await tester.tap(nextVerse);
    await tester.pumpAndSettle();
    // Now the prevVerse IconButton should also be available.
    expect(tester.widget<IconButton>(prevVerse).onPressed != null, true);
    expect(tester.widget<TextIconButton>(prevSong).onTap, null);
    expect(tester.widget<TextIconButton>(nextSong).onTap != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed != null, true);
    // Now let's navigate to the fourth verse.
    await tester.tap(nextVerse);
    await tester.tap(nextVerse);
    await tester.pumpAndSettle();
    // On the last verse the nextVerse IconButton should not be available.
    expect(tester.widget<IconButton>(prevVerse).onPressed != null, true);
    expect(tester.widget<TextIconButton>(prevSong).onTap, null);
    expect(tester.widget<TextIconButton>(nextSong).onTap != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed, null);
    // Tapping on the right half of the song page should also switch to the
    // next verse, but even on the last verse of a song.
    await tester.tapAt(Offset(
        mySongPageStateSize.width / 2 + mySongPageStateCenter.dx / 2,
        mySongPageStateSize.height / 2 + mySongPageStateCenter.dy / 2));
    await tester.pumpAndSettle();
    // Now the second song's first verse should be displayed.
    expect(
        find.textContaining(': Miért zúgolódnak a pogányok?'), findsOneWidget);
    expect(tester.widget<IconButton>(prevVerse).onPressed, null);
    expect(tester.widget<TextIconButton>(prevSong).onTap != null, true);
    expect(tester.widget<TextIconButton>(nextSong).onTap != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed != null, true);
    // Go to the second verse.
    await tester.tap(nextVerse);
    await tester.pumpAndSettle();
    // Now the second song's second verse should be displayed.
    expect(tester.widget<IconButton>(prevVerse).onPressed != null, true);
    expect(tester.widget<TextIconButton>(prevSong).onTap != null, true);
    expect(tester.widget<TextIconButton>(nextSong).onTap != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed != null, true);

    // TODO Test settings (different books).
    // TODO Test search song function.
  });
}
