import 'dart:collection';

class Util {
  static String getSongTitle(LinkedHashMap song) {
    return (song['number'] != null ? song['number'] + ': ' : '') + song['title'];
  }
}
