import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../settings_provider.dart';

class SongStateProvider extends ChangeNotifier with WidgetsBindingObserver {
  int song;
  int verse;
  Book book;
  ScrollController scrollController = ScrollController();
  TabController tabController;
  Orientation orientation;
  BuildContext context;

  SongStateProvider({
    required int song,
    required int verse,
    required Book book,
    required this.context,
  })  : song = song,
        verse = verse,
        book = book,
        tabController = TabController(
            initialIndex: verse, length: 10, vsync: ScrollableState()),
        orientation = MediaQuery.of(context).orientation;

  // To retrieve the song data, the key (the actual number of the song) is
  // needed, not the index (the position in the list).
  String get songKey => songBooks[book.name].keys.elementAt(song);

  void switchVerse({required bool next}) {
    int originalVerse = verse;
    int originalSong = song;

    SettingsProvider settingsProvider = SettingsProvider.of(context);

    if (next) {
      // Only allow switching to the next verse when all verses should have
      // scores (and there _is_ a next verse).
      if ((settingsProvider.scoreDisplay == ScoreDisplay.all) &&
          verse < songBooks[book.name][songKey]['texts'].length - 1) {
        verse++;
      } else if (song < songBooks[book.name].length - 1) {
        song++;
        verse = 0;
      }
    } else {
      // Only allow switching to the previous verse when all verses should
      // have scores (and there _is_ a previous verse).
      if ((settingsProvider.scoreDisplay == ScoreDisplay.all) && verse > 0) {
        verse--;
      } else if (song > 0) {
        song--;
        if (settingsProvider.scoreDisplay == ScoreDisplay.all) {
          // This songKey must be recalculated to be able to fetch the number
          // of verses for the previous song.
          verse = songBooks[book.name][songKey]['texts'].length - 1;
        } else {
          // When not all verses should have their scores displayed,
          // technically always their first verse is displayed.
          verse = 0;
        }
      }
    }
    if (originalVerse != verse || originalSong != song) {
      if (originalSong != song) {
        tabController.animateTo(verse, duration: const Duration(seconds: 0));
        scrollController.jumpTo(0);
      } else {
        tabController.animateTo(verse);
      }
    }

    notifyListeners();
  }

  void switchSong({required bool next}) {
    next ? song++ : song--;
    verse = 0;
    tabController.animateTo(verse);
    scrollController.jumpTo(0);
  }

  bool songExists({required bool next}) {
    if (next) { // TODO verify
      return song < songBooks[book.name].length - 1;
    } else {
      return song > 0;
    }
  }

  bool verseExists({required bool next}) {
    if (next) { // TODO verify
      return verse < songBooks[book.name][songKey]['texts'].length - 1;
    } else {
      return verse > 0;
    }
  }

  static SongStateProvider of(BuildContext context) {
    return Provider.of<SongStateProvider>(context, listen: false);
  }
}
