import 'dart:collection';
import 'dart:core';

import 'settings_provider.dart';

final Map<String, Map<String, dynamic>> _songLookupCache = {};

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
    book = Book.fromName(bookName);
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
Map<String, dynamic> _songLookup(Book book) {
  final bookName = book.name;
  final songs = songBooks[bookName];
  final cached = _songLookupCache[bookName];

  if (cached != null &&
      identical(cached['songs'], songs) &&
      cached['count'] == songs.length) {
    return cached;
  }

  final keys = songs.keys.cast<String>().toList(growable: false);
  final indices = <String, int>{};
  for (var i = 0; i < keys.length; i++) {
    indices[keys[i]] = i;
  }

  final lookup = {
    'songs': songs,
    'count': keys.length,
    'keys': keys,
    'indices': indices,
  };
  _songLookupCache[bookName] = lookup;
  return lookup;
}

String songKeyFor(Book book, int songIndex) {
  final lookup = _songLookup(book);
  return (lookup['keys'] as List<String>)[songIndex];
}

int songIndexFor(Book book, String songKey) {
  final lookup = _songLookup(book);
  return (lookup['indices'] as Map<String, int>)[songKey] ?? -1;
}
