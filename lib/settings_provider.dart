import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const Book defaultBook = Book.blue;
  static const ScoreDisplay defaultScoreDisplay = ScoreDisplay.all;
  static const double defaultFontSize = 14.0;
  static const BrightnessSetting defaultAppBrightnessSetting =
      BrightnessSetting.system;
  static const BrightnessSetting defaultSheetBrightnessSetting =
      BrightnessSetting.light;

  Book _book = defaultBook;
  ScoreDisplay _scoreDisplay = defaultScoreDisplay;
  double _fontSize = defaultFontSize;
  BrightnessSetting _appBrightnessSetting = defaultAppBrightnessSetting;
  BrightnessSetting _sheetBrightnessSetting = defaultSheetBrightnessSetting;
  bool _initialized = false;

  Book get book => _book;
  ScoreDisplay get scoreDisplay => _scoreDisplay;
  double get fontSize => _fontSize;
  BrightnessSetting get appBrightnessSetting => _appBrightnessSetting;
  BrightnessSetting get sheetBrightnessSetting => _sheetBrightnessSetting;

  String get bookAsString {
    switch (_book) {
      case Book.black:
        return '48';

      case Book.blue:
      default:
        return '21';
    }
  }

  ThemeMode get appThemeMode {
    switch (_appBrightnessSetting) {
      case BrightnessSetting.system:
        return ThemeMode.system;
      case BrightnessSetting.dark:
        return ThemeMode.dark;
      case BrightnessSetting.light:
        return ThemeMode.light;
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

  void changeAppBrightnessSetting(BrightnessSetting value) async {
    _appBrightnessSetting = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appBrightness', value.index);
    notifyListeners();
    //? I don't think seting _initialized to true is appropriate here.
    //? Other values have not been loaded yet. (-RedyAu)
  }

  void changeSheetBrightnessSetting(BrightnessSetting value) async {
    _sheetBrightnessSetting = value;
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
      _appBrightnessSetting = BrightnessSetting.values[
          prefs.getInt('appBrightness') ?? defaultAppBrightnessSetting.index];

      _sheetBrightnessSetting = BrightnessSetting.values[
          prefs.getInt('sheetBrightness') ??
              defaultSheetBrightnessSetting.index];
    } catch (e) {
      // On any unexpected error, use default settings
      _book = defaultBook;
      _scoreDisplay = defaultScoreDisplay;
      _fontSize = defaultFontSize;
      _appBrightnessSetting = defaultAppBrightnessSetting;
      _sheetBrightnessSetting = defaultSheetBrightnessSetting;
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

enum BrightnessSetting { system, dark, light }

String getBrightnessName(BrightnessSetting brightness) {
  switch (brightness) {
    case BrightnessSetting.system:
      return "Rendszer";
    case BrightnessSetting.dark:
      return "Sötét";
    case BrightnessSetting.light:
    default:
      return "Világos";
  }
}
