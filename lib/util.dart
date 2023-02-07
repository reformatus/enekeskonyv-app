import 'dart:collection';

String getSongTitle(LinkedHashMap song) {
  return (song['number'] != null ? song['number'] + ': ' : '') + song['title'];
}

// HACK - needs refactor
late LinkedHashMap<String, dynamic> globalSongs;