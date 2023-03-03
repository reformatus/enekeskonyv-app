import 'dart:collection';

String getSongTitle(LinkedHashMap song) {
  return (song['number'] != null ? song['number'] + ': ' : '') + song['title'];
}

// HACK - needs refactor
// The JSON asset gets loaded into this one when the app starts, then this never
// gets writes any more.
late final LinkedHashMap<String, dynamic> globalSongs;