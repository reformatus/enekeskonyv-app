import 'build_pages.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../settings_provider.dart';

class SongStateProvider extends ChangeNotifier {
  int song;
  int verse;
  Book book;
  ScrollController scrollController = ScrollController();
  late TabController tabController;

  SongStateProvider({
    required this.song,
    required this.verse,
    required this.book,
    required TickerProvider vsync,
    required BuildContext context,
  }) {
    tabController = TabController(
        initialIndex: verse,
        length: getNumOfPages(book, songKey, context),
        vsync: vsync);
  }

  // To retrieve the song data, the key (the actual number of the song) is
  // needed, not the index (the position in the list).
  String get songKey => songBooks[book.name].keys.elementAt(song);

  // TODO review logic!!
  void switchVerse(
      {required bool next,
      required SettingsProvider settingsProvider,
      required BuildContext context,
      required TickerProvider vsync}) {
    int originalVerse = verse;
    int originalSong = song;

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
        tabController.dispose();
        tabController = TabController(
            length: getNumOfPages(book, songKey, context), vsync: vsync);
        scrollController.jumpTo(0);
      } else {
        tabController.animateTo(verse);
      }
    }

    notifyListeners();
  }

  void switchSong(
      {required bool next,
      required BuildContext context,
      required TickerProvider vsync}) {
    next ? song++ : song--;
    verse = 0;
    tabController.dispose();
    tabController = TabController(
        length: getNumOfPages(book, songKey, context), vsync: vsync);
    scrollController.jumpTo(0);
  }

  bool songExists({required bool next}) {
    if (next) {
      return song < songBooks[book.name].length - 1;
    } else {
      return song > 0;
    }
  }

  bool verseExists({required bool next}) {
    if (next) {
      return (verse < songBooks[book.name][songKey]['texts'].length - 1);
    } else {
      return verse > 0;
    }
  }

  static SongStateProvider of(BuildContext context) {
    return Provider.of<SongStateProvider>(context, listen: false);
  }
}
