import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const Book defaultBook = Book.blue;
  static const ScoreDisplay defaultScoreDisplay = ScoreDisplay.all;
  static const double defaultFontSize = 14.0;

  Book _book = defaultBook;
  ScoreDisplay _scoreDisplay = defaultScoreDisplay;
  double _fontSize = defaultFontSize;
  bool _initialized = false;

  Book get book {
    return _book;
  }

  ScoreDisplay get scoreDisplay {
    return _scoreDisplay;
  }

  double get fontSize {
    return _fontSize;
  }

  String get bookAsString {
    switch (_book) {
      case Book.black:
        return '48';

      case Book.blue:
      default:
        return '21';
    }
  }

  bool get initialized {
    return _initialized;
  }

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

  void initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

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
    } catch (e) {
      _book = defaultBook;
    }

    _scoreDisplay = ScoreDisplay
        .values[prefs.getInt('scoreDisplayEnum') ?? defaultScoreDisplay.index];

    _fontSize = prefs.getDouble('fontSize') ?? defaultFontSize;

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
