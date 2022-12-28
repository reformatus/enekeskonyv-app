import 'dart:collection';

class Util {
  static String getSongTitle(LinkedHashMap song) {
    return (song['number'] != null ? song['number'] + ': ' : '') +
        song['title'];
  }
}

enum Book { fekete, kek }

String getBookName(Book book) =>
    (book == Book.fekete) ? "48-as (fekete)" : "21-es (kék)";
String getBookShortName(Book book) => (book == Book.fekete) ? "48" : "21";
