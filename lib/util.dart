import 'dart:collection';

import 'settings_provider.dart';

String getSongTitle(LinkedHashMap song) {
  return (song['number'] != null ? song['number'] + ': ' : '') + song['title'];
}

String getVerseId(Book book, String songKey, int verseIndex) {
  return '${book.name}/$songKey/$verseIndex';
}
