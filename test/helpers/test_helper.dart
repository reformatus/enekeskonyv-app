import 'dart:collection';

import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mock_test_environment.dart';

/// Test helper utilities for the Énekeskönyv app
class TestHelper {
  /// Sets up complete test environment including mocks
  static void setupTestEnvironment() {
    MockTestEnvironment.setUp();
    setupSharedPreferences();
    setupMockSongBooks();
  }

  /// Cleans up test environment
  static void cleanupTestEnvironment() {
    MockTestEnvironment.tearDown();
    cleanup();
  }
  /// Creates mock song books data for testing
  static Map<String, dynamic> createMockSongBooks() {
    return {
      '21': {
        '1': {
          'title': 'Aki nem jár hitlenek tanácsán',
          'number': '1',
          'texts': [
            '1. Aki nem jár hitlenek tanácsán, bűnösök útján meg nem áll',
            '2. Hanem az Úr törvényében gyönyörködik',
            '3. És az ő törvényén gondolkodik éjjel és nappal',
            '4. Olyan lesz, mint a folyóvizek mellé ültetett fa',
          ],
          'markdown': null,
        },
        '2': {
          'title': 'Miért zúgolódnak a pogányok?',
          'number': '2',
          'texts': [
            '1. Miért zúgolódnak a pogányok?',
            '2. És miért gondolnak hiábavalóságot a népek?',
            '3. A föld királyai felállanak',
          ],
          'markdown': null,
        },
        '3': {
          'title': 'Úr, mily sokasodtak ellenségeim!',
          'number': '3',
          'texts': [
            '1. Úr, mily sokasodtak ellenségeim!',
            '2. Sokan vannak, akik ellenem támadnak',
          ],
          'markdown': null,
        }
      },
      '48': {
        '1': {
          'title': 'Dicsőség legyen az Atyának',
          'number': '1',
          'texts': [
            '1. Dicsőség legyen az Atyának és a Fiúnak és a Szentlélek Istennek',
          ],
          'markdown': null,
        },
        '2': {
          'title': 'Jöjj, Szentlélek Úristen',
          'number': '2',
          'texts': [
            '1. Jöjj, Szentlélek Úristen, töltsd be híveid szívét',
            '2. És gerjesd fel őbennük a te szeretetednek tüzét',
          ],
          'markdown': null,
        }
      }
    };
  }

  /// Creates a test widget wrapped with necessary providers
  static Widget createTestWidget({
    required Widget child,
    SettingsProvider? settingsProvider,
    ThemeData? theme,
  }) {
    final provider = settingsProvider ?? SettingsProvider();
    
    return ChangeNotifierProvider<SettingsProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: Scaffold(body: child),
      ),
    );
  }

  /// Creates a test widget with navigation capability
  static Widget createTestWidgetWithNavigation({
    required Widget child,
    SettingsProvider? settingsProvider,
    ThemeData? theme,
    List<Route<dynamic>>? initialRoutes,
  }) {
    final provider = settingsProvider ?? SettingsProvider();
    
    return ChangeNotifierProvider<SettingsProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: child,
        // Add navigation support if needed
      ),
    );
  }

  /// Sets up SharedPreferences for testing
  static void setupSharedPreferences([Map<String, Object>? values]) {
    SharedPreferences.setMockInitialValues(values ?? {});
  }

  /// Sets up mock song books in the global variable
  static void setupMockSongBooks() {
    songBooks = createMockSongBooks();
  }

  /// Cleans up test data
  static void cleanup() {
    songBooks.clear();
  }

  /// Creates a mock SettingsProvider with specific settings
  static SettingsProvider createMockSettingsProvider({
    Book book = Book.blue,
    ScoreDisplay scoreDisplay = ScoreDisplay.all,
    double fontSize = 14.0,
    ThemeMode appThemeMode = ThemeMode.system,
    bool isOledTheme = false,
    bool tapNavigation = true,
    bool isVerseBarPinned = false,
    bool isVerseBarEnabled = true,
    bool searchNumericKeyboard = false,
    String selectedCue = 'Kedvencek',
  }) {
    final provider = SettingsProvider();
    
    // Set up the provider with test values
    provider.changeBook(book);
    provider.changeScoreDisplay(scoreDisplay);
    provider.changeFontSize(fontSize);
    provider.changeAppThemeMode(appThemeMode);
    provider.changeIsOledTheme(isOledTheme);
    provider.changeTapNavigation(tapNavigation);
    provider.changeIsVerseBarPinned(isVerseBarPinned);
    provider.changeIsVerseBarEnabled(isVerseBarEnabled);
    provider.changeSearchNumericKeyboard(searchNumericKeyboard);
    provider.changeSelectedCue(selectedCue);
    
    return provider;
  }

  /// Creates a test verse object
  static Map<String, dynamic> createTestVerse({
    String? number,
    required String text,
  }) {
    return {
      'number': number,
      'text': text,
    };
  }

  /// Creates a test song object
  static LinkedHashMap<String, dynamic> createTestSong({
    required String title,
    String? number,
    List<String>? texts,
    String? markdown,
  }) {
    return LinkedHashMap<String, dynamic>.from({
      'title': title,
      'number': number,
      'texts': texts ?? ['1. Test verse'],
      'markdown': markdown,
    });
  }

  /// Pumps widget and waits for animations to settle
  static Future<void> pumpAndSettle(tester, [Duration? duration]) async {
    await tester.pumpAndSettle(duration ?? const Duration(milliseconds: 100));
  }

  /// Common expect statements for widget presence
  static void expectWidgetToBePresent(finder) {
    expect(finder, findsOneWidget);
  }

  static void expectWidgetToBeAbsent(finder) {
    expect(finder, findsNothing);
  }

  static void expectWidgetsCount(finder, int count) {
    expect(finder, findsNWidgets(count));
  }
}