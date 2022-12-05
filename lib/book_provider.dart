import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookProvider extends ChangeNotifier {
  static const String defaultBook = '21';

  String _book = defaultBook;
  bool _initialized = false;

  String get book {
    return _book;
  }

  bool get initialized {
    return _initialized;
  }

  void changeBook(String value) async {
    _book = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('book', value);
    notifyListeners();
    _initialized = true;
  }

  void initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _book = prefs.getString('book') ?? defaultBook;
    notifyListeners();
    _initialized = true;
  }
}