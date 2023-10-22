import 'dart:collection';
import 'dart:core';

import 'settings_provider.dart';

String getSongTitle(LinkedHashMap song) {
  return (song['number'] != null ? song['number'] + ': ' : '') + song['title'];
}

String getVerseId(Book book, String songKey, int verseIndex) {
  return '${book.name}.$songKey.$verseIndex';
}
/*
Record parseVerseId(String verseId) {
  List<String> parts = verseId.split('/');
  return Record(parts[0], parts[1], int.parse(parts[2]));
}
*/