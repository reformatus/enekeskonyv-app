import 'dart:collection';
import 'dart:core';

import 'settings_provider.dart';

String getSongTitle(LinkedHashMap song) {
  return (song['number'] != null ? song['number'] + ': ' : '') + song['title'];
}

String getVerseId(Book book, String songKey, int verseIndex) {
  return '${book.name}.$songKey.$verseIndex';
}

class Verse {
  Book book;
  String songKey;
  int verseIndex;

  Verse(this.book, this.songKey, this.verseIndex);
}

Verse parseVerseId(String verseId) {
  if (songBooks.isEmpty) throw 'Énekeskönyv nincs betöltve, próbáld újra!';

  List<String> parts = verseId.split('.');

  if (parts.length < 3) {
    throw 'Könyv, ének vagy versszak nincs megadva.';
  }

  String bookName = parts[0];
  Book book;
  try {
    book = Book.values.firstWhere((element) => element.name == bookName);
  } catch (e) {
    throw 'Könyv nem található.';
  }

  String songKey = parts[1];
  if (!songBooks[bookName].containsKey(songKey)) throw 'Ének nem található.';

  int verseIndex;
  try {
    verseIndex = int.parse(parts[2]);
  } catch (_) {
    throw 'Versszakszám érvénytelen.';
  }

  if (songBooks[bookName][songKey]['texts'].length <= verseIndex) {
    throw 'Versszak nem található.';
  }

  return Verse(book, songKey, verseIndex);
}

// Helpers for translating between song index and key where needed.
// Prefer using songKey across the app; these are for unavoidable cases.
String songKeyFor(Book book, int songIndex) {
  return songBooks[book.name].keys.elementAt(songIndex);
}

int songIndexFor(Book book, String songKey) {
  return songBooks[book.name].keys.toList().indexOf(songKey);
}
