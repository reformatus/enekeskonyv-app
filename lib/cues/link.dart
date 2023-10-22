import 'package:enekeskonyv/cues/cues_page.dart';
import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/material.dart';

import '../song/song_page.dart';

String? openAppLink(Uri uri, BuildContext context) {
  if (uri.host != 'reflabs.hu' || uri.queryParameters.isEmpty) {
    // When link is without a path, it's a link to the app itself.
    // Also app won't get launched if the host is not the expected one, so
    // that check is just to be sure.
    return null;
  }

  switch (uri.queryParameters.keys.first) {
    case 's': // Song
      Verse verse;
      try {
        verse = parseVerseId(uri.queryParameters['s']!);
      } catch (e) {
        return 'Helytelen link: $e';
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return SongPage(
              book: verse.book,
              songIndex: verse.songIndex,
              verseIndex: verse.verseIndex,
            );
          },
        ),
      );
      return null;
    case 'c': // Cue
      List<String> parts;
      try {
        parts = uri.queryParameters['c']!.split(',');
      } catch (e) {
        return 'Helytelen link: Lista formátum nem megfelelő.';
      }

      String cueName;
      try {
        cueName = parts[0];
      } catch (e) {
        return 'Helytelen link: Listanév hiányzik vagy érvénytelen';
      }

      List<String> cueContent;
      cueContent = parts.sublist(1);
      if (cueContent.isEmpty) return 'Helytelen link: Üres lista';

      for (var element in cueContent) {
        try {
          parseVerseId(element);
        } catch (e) {
          return 'Helytelen link: Lista érvénytelen versszakot tartalmaz:\n"$element" - $e';
        }
      }
      var settings = SettingsProvider.of(context);
      settings.saveCue(cueName, cueContent);
      settings.changeSelectedCue(cueName);

      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => CuesPage(context)));

      return null;
    default:
      return 'Helytelen link: Ismeretlen parancs.';
  }
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

  if (parts.length < 2) {
    throw 'Könyv vagy ének nincs megadva.';
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

  int? verseIndex = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
  if (songBooks[bookName][songKey].length <= verseIndex) {
    throw 'Versszak nem található.';
  }

  return Verse(book, songIndex, verseIndex);
}