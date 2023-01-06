import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const Book defaultBook = Book.blue;
  static const ScoreDisplay defaultScoreDisplay = ScoreDisplay.all;
  static const double defaultFontSize = 14.0;
  static const ThemeMode defaultAppThemeMode = ThemeMode.system;
  static const ThemeMode defaultSheetThemeMode = ThemeMode.light;

  Book _book = defaultBook;
  ScoreDisplay _scoreDisplay = defaultScoreDisplay;
  double _fontSize = defaultFontSize;
  ThemeMode _appThemeMode = defaultAppThemeMode;
  ThemeMode _sheetThemeMode = defaultSheetThemeMode;
  bool _initialized = false;

  Book get book => _book;
  ScoreDisplay get scoreDisplay => _scoreDisplay;
  double get fontSize => _fontSize;
  ThemeMode get appThemeMode => _appThemeMode;
  ThemeMode get sheetThemeMode => _sheetThemeMode;

  String get bookAsString {
    switch (_book) {
      case Book.black:
        return '48';

      case Book.blue:
      default:
        return '21';
    }
  }

  bool get initialized => _initialized;

  void changeBook(Book value) async {
    _book = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bookEnum', value.index);
    notifyListeners();
    // TODO Is it possible that this gets called before .initialize()?
    _initialized = true;
  }

  void changeScoreDisplay(ScoreDisplay value) async {
    _scoreDisplay = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('scoreDisplayEnum', value.index);
    notifyListeners();
    // TODO Is it possible that this gets called before .initialize()?
    _initialized = true;
  }

  void changeFontSize(double value) async {
    _fontSize = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', value);
    notifyListeners();
    // TODO Is it possible that this gets called before .initialize()?
    _initialized = true;
  }

  void changeAppBrightnessSetting(ThemeMode value) async {
    _appThemeMode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appBrightness', value.index);
    notifyListeners();
    //? I don't think seting _initialized to true is appropriate here.
    //? Other values have not been loaded yet. (-RedyAu)
  }

  void changeSheetBrightnessSetting(ThemeMode value) async {
    _sheetThemeMode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sheetBrightness', value.index);
    notifyListeners();
  }

  void initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    //! Book
    try {
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

      //! Score apperance
      _scoreDisplay = ScoreDisplay.values[
          prefs.getInt('scoreDisplayEnum') ?? defaultScoreDisplay.index];

      _fontSize = prefs.getDouble('fontSize') ?? defaultFontSize;

      //! Brightness
      _appThemeMode = ThemeMode.values[
          prefs.getInt('appThemeMode') ?? defaultAppThemeMode.index];

      _sheetThemeMode = ThemeMode.values[
          prefs.getInt('sheetThemeMode') ?? defaultSheetThemeMode.index];
    } catch (e) {
      // On any unexpected error, use default settings
      _book = defaultBook;
      _scoreDisplay = defaultScoreDisplay;
      _fontSize = defaultFontSize;
      _appThemeMode = defaultAppThemeMode;
      _sheetThemeMode = defaultSheetThemeMode;
    }

    notifyListeners();
    _initialized = true;
  }
}

enum Book { black, blue }

String getBookName(Book book) {
  switch (book) {
    case Book.black:
      return '48-as (fekete)';

    case Book.blue:
    default:
      return '21-es (kék)';
  }
}

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
      return "Rendszer";
    case ThemeMode.dark:
      return "Sötét";
    case ThemeMode.light:
      return "Világos";
  }
}
