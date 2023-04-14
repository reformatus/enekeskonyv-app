import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const Book defaultBook = Book.blue;
  static const ScoreDisplay defaultScoreDisplay = ScoreDisplay.all;
  static const double defaultFontSize = 14.0;
  static const ThemeMode defaultAppThemeMode = ThemeMode.system;
  static const ThemeMode defaultSheetThemeMode = ThemeMode.light;
  static const bool defaultTapNavigation = true;

  Book _book = defaultBook;
  ScoreDisplay _scoreDisplay = defaultScoreDisplay;
  double _fontSize = defaultFontSize;
  ThemeMode _appThemeMode = defaultAppThemeMode;
  ThemeMode _sheetThemeMode = defaultSheetThemeMode;
  bool _tapNavigation = defaultTapNavigation;
  bool _initialized = false;

  Book get book => _book;

  ScoreDisplay get scoreDisplay => _scoreDisplay;

  double get fontSize => _fontSize;

  ThemeMode get appThemeMode => _appThemeMode;

  ThemeMode get sheetThemeMode => _sheetThemeMode;

  bool get tapNavigation => _tapNavigation;

  String get bookAsString {
    switch (_book) {
      case Book.black:
        return '48';

      case Book.blue:
      default:
        return '21';
    }
  }

  Brightness getCurrentAppBrightness(BuildContext context) {
    switch (appThemeMode) {
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context);
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.light:
        return Brightness.light;
    }
  }

  Brightness getCurrentSheetBrightness(BuildContext context) {
    switch (sheetThemeMode) {
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context);
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.light:
        return Brightness.light;
    }
  }

  bool get initialized => _initialized;

  Future changeBook(Book value) async {
    _book = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bookEnum', value.index);
    notifyListeners();
  }

  Future changeScoreDisplay(ScoreDisplay value) async {
    _scoreDisplay = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('scoreDisplayEnum', value.index);
    notifyListeners();
  }

  Future changeFontSize(double value) async {
    _fontSize = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', value);
    notifyListeners();
  }

  Future changeAppBrightnessSetting(ThemeMode value) async {
    _appThemeMode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appThemeMode', value.index);
    notifyListeners();
  }

  Future changeSheetBrightnessSetting(ThemeMode value) async {
    _sheetThemeMode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sheetThemeMode', value.index);
    notifyListeners();
  }

  Future changeTapNavigation(bool value) async {
    _tapNavigation = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tapNavigation', value);
    notifyListeners();
  }

  Future initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      //! Book selection.
      // First try migrating from previous version.
      String? bookMigrateString = prefs.getString('book');
      if (bookMigrateString != null) {
        _book = bookMigrateString == '21' ? Book.blue : Book.black;
        // Save the new entry and remove old one.
        await prefs.setInt('bookEnum', _book.index);
        await prefs.remove('book');
      } else {
        // Read saved value.
        _book = Book.values[prefs.getInt('bookEnum') ?? defaultBook.index];
      }

      //! Score appearance.
      _scoreDisplay = ScoreDisplay.values[
          prefs.getInt('scoreDisplayEnum') ?? defaultScoreDisplay.index];

      _fontSize = prefs.getDouble('fontSize') ?? defaultFontSize;

      //! Brightness.
      _appThemeMode = ThemeMode
          .values[prefs.getInt('appThemeMode') ?? defaultAppThemeMode.index];

      _sheetThemeMode = ThemeMode.values[
          prefs.getInt('sheetThemeMode') ?? defaultSheetThemeMode.index];

      //! Tap navigation.
      _tapNavigation = prefs.getBool('tapNavigation') ?? defaultTapNavigation;
    } catch (e) {
      // On any unexpected error, use default settings.
      _book = defaultBook;
      _scoreDisplay = defaultScoreDisplay;
      _fontSize = defaultFontSize;
      _appThemeMode = defaultAppThemeMode;
      _sheetThemeMode = defaultSheetThemeMode;
      _tapNavigation = defaultTapNavigation;
    }

    notifyListeners();
    _initialized = true;
  }

  // of method for easy access
  static SettingsProvider of(BuildContext context) {
    return Provider.of<SettingsProvider>(context, listen: false);
  }
}

// @see https://stackoverflow.com/a/29567669
enum Book {
  black('48'),
  blue('21');

  final String name;

  String get displayName =>
      this == Book.black ? '48-as (fekete)' : '21-es (kék)';

  const Book(this.name);
}

// @TODO Replace below function with above approach: enum with named consts.
enum ScoreDisplay { all, first, none }

String getScoreDisplayName(ScoreDisplay scoreDisplay) {
  switch (scoreDisplay) {
    case ScoreDisplay.first:
      return 'Első vers';

    case ScoreDisplay.none:
      return 'Nincs';

    case ScoreDisplay.all:
    default:
      return 'Minden vers';
  }
}

String getThemeModeName(ThemeMode themeMode) {
  switch (themeMode) {
    case ThemeMode.system:
      return 'Rendszer';
    case ThemeMode.dark:
      return 'Sötét';
    case ThemeMode.light:
      return 'Világos';
  }
}
