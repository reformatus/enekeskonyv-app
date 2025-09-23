import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsProvider Tests', () {
    late SettingsProvider settingsProvider;

    setUp(() {
      // Set up SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      settingsProvider = SettingsProvider();
    });

    group('Default Values', () {
      test('should have correct default values', () {
        expect(settingsProvider.book, equals(Book.blue));
        expect(settingsProvider.scoreDisplay, equals(ScoreDisplay.all));
        expect(settingsProvider.fontSize, equals(14.0));
        expect(settingsProvider.appThemeMode, equals(ThemeMode.system));
        expect(settingsProvider.sheetThemeMode, equals(ThemeMode.light));
        expect(settingsProvider.isOledTheme, equals(false));
        expect(settingsProvider.tapNavigation, equals(true));
        expect(settingsProvider.isVerseBarPinned, equals(false));
        expect(settingsProvider.isVerseBarEnabled, equals(true));
        expect(settingsProvider.searchNumericKeyboard, equals(false));
        expect(settingsProvider.selectedCue, equals('Kedvencek'));
        expect(settingsProvider.initialized, equals(false));
      });
    });

    group('Book Selection', () {
      test('should change book and notify listeners', () {
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeBook(Book.black);

        expect(settingsProvider.book, equals(Book.black));
        expect(notified, isTrue);
      });

      test('should not notify if same book is set', () {
        settingsProvider.changeBook(Book.blue); // Set initial
        
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeBook(Book.blue); // Same book

        expect(notified, isFalse);
      });
    });

    group('Score Display', () {
      test('should change score display and notify listeners', () {
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeScoreDisplay(ScoreDisplay.none);

        expect(settingsProvider.scoreDisplay, equals(ScoreDisplay.none));
        expect(notified, isTrue);
      });

      test('should handle all score display values', () {
        settingsProvider.changeScoreDisplay(ScoreDisplay.first);
        expect(settingsProvider.scoreDisplay, equals(ScoreDisplay.first));

        settingsProvider.changeScoreDisplay(ScoreDisplay.all);
        expect(settingsProvider.scoreDisplay, equals(ScoreDisplay.all));

        settingsProvider.changeScoreDisplay(ScoreDisplay.none);
        expect(settingsProvider.scoreDisplay, equals(ScoreDisplay.none));
      });
    });

    group('Font Size', () {
      test('should change font size and notify listeners', () {
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeFontSize(18.0);

        expect(settingsProvider.fontSize, equals(18.0));
        expect(notified, isTrue);
      });

      test('should handle different font sizes', () {
        settingsProvider.changeFontSize(12.0);
        expect(settingsProvider.fontSize, equals(12.0));

        settingsProvider.changeFontSize(20.0);
        expect(settingsProvider.fontSize, equals(20.0));
      });
    });

    group('Theme Mode', () {
      test('should change app theme mode and notify listeners', () {
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeAppBrightnessSetting(ThemeMode.dark);

        expect(settingsProvider.appThemeMode, equals(ThemeMode.dark));
        expect(notified, isTrue);
      });

      test('should change sheet theme mode and notify listeners', () {
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeSheetBrightnessSetting(ThemeMode.dark);

        expect(settingsProvider.sheetThemeMode, equals(ThemeMode.dark));
        expect(notified, isTrue);
      });
    });

    group('Boolean Settings', () {
      test('should change OLED theme setting', () {
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeIsOledTheme(true);

        expect(settingsProvider.isOledTheme, isTrue);
        expect(notified, isTrue);
      });

      test('should change tap navigation setting', () {
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeTapNavigation(false);

        expect(settingsProvider.tapNavigation, isFalse);
        expect(notified, isTrue);
      });

      test('should change verse bar pinned setting', () {
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeIsVerseBarPinned(true);

        expect(settingsProvider.isVerseBarPinned, isTrue);
        expect(notified, isTrue);
      });

      test('should change verse bar enabled setting', () {
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeIsVerseBarEnabled(false);

        expect(settingsProvider.isVerseBarEnabled, isFalse);
        expect(notified, isTrue);
      });

      test('should change search numeric keyboard setting', () {
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeSearchNumericKeyboard(true);

        expect(settingsProvider.searchNumericKeyboard, isTrue);
        expect(notified, isTrue);
      });
    });

    group('Selected Cue', () {
      test('should change selected cue and notify listeners', () {
        bool notified = false;
        settingsProvider.addListener(() {
          notified = true;
        });

        settingsProvider.changeSelectedCue('Test Cue');

        expect(settingsProvider.selectedCue, equals('Test Cue'));
        expect(notified, isTrue);
      });
    });

    group('Brightness Detection', () {
      testWidgets('should return correct brightness based on theme mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light,
            home: Builder(
              builder: (context) {
                // Test light theme
                settingsProvider.changeAppBrightnessSetting(ThemeMode.light);
                final lightBrightness = settingsProvider.getCurrentAppBrightness(context);
                expect(lightBrightness, equals(Brightness.light));

                // Test dark theme
                settingsProvider.changeAppBrightnessSetting(ThemeMode.dark);
                final darkBrightness = settingsProvider.getCurrentAppBrightness(context);
                expect(darkBrightness, equals(Brightness.dark));

                return Container();
              },
            ),
          ),
        );
      });
    });
  });
}