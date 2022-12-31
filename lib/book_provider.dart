import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookProvider extends ChangeNotifier {
  static const Book defaultBook = Book.blue;

  Book _book = defaultBook;
  bool _initialized = false;

  Book get book {
    return _book;
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
