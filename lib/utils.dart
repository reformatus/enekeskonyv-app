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
  int songIndex;
  int verseIndex;

  Verse(this.book, this.songIndex, this.verseIndex);
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
  int songIndex = songBooks[bookName].keys.toList().indexOf(songKey);
  if (songIndex == -1) throw 'Ének nem található.';

  int verseIndex;
  try {
    verseIndex = int.parse(parts[2]);
  } catch (_) {
    throw 'Versszakszám érvénytelen.';
  }

  if (songBooks[bookName][songKey]['texts'].length <= verseIndex) {
    throw 'Versszak nem található.';
  }

  return Verse(book, songIndex, verseIndex);
}
