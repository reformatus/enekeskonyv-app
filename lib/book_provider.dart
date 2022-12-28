import 'dart:developer';

import 'package:enekeskonyv/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookProvider extends ChangeNotifier {
  static const Book defaultBook = Book.kek;

  Book _book = defaultBook;
  bool _initialized = false;

  Book get book {
    return _book;
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
      //First try migrating from previous version
      String? bookMigrateString = prefs.getString('book');
      if (bookMigrateString != null) {
        log('Migrating from old prefs...');
        _book = (bookMigrateString == '21') ? Book.kek : Book.fekete;
        //Save new and remove old entry from storage
        await prefs.setInt('bookEnum', _book.index);
        await prefs.remove('book');
      } else {
        //Read saved value
        _book = Book.values[prefs.getInt('bookEnum') ?? defaultBook.index];
      }
    } catch (e, s) {
      log("Error while managing storage, using default book instead.",
          error: e, stackTrace: s);
      _book = defaultBook;
    }
    notifyListeners();
    _initialized = true;
  }
}
