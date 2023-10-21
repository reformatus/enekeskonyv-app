import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../settings_provider.dart';
import 'build_pages.dart';

class SongStateProvider extends ChangeNotifier {
  int song;
  int verse;
  Book book;
  ScrollController scrollController = ScrollController();
  ScrollController? tabBarScrollController;
  late TabController tabController;
  bool isVerseBarVisible = true;
  // To make sure verse bar hides after opening a page, we subtract a few seconds.
  DateTime barLastShownAtTime =
      DateTime.now().subtract(const Duration(seconds: 10));
  Timer? verseBarHideTimer;
  List<Widget> tabs = [];
  Map<int, GlobalKey> tabKeys = {};
  GlobalKey verseBarKey = GlobalKey();

  SongStateProvider({
    required this.song,
    required this.verse,
    required this.book,
    required TickerProvider vsync,
    required BuildContext context,
  }) {
    initTabController(
        vsync: vsync,
        numOfPages: getNumOfPages(book, songKey, context),
        initialIndex: verse,
        initial: true);
    showThenHideVerseBar();
  }

  void initTabController(
      {int? numOfPages,
      int? initialIndex,
      bool initial = false,
      required TickerProvider vsync}) {
    initialIndex ??= tabController.index;
    numOfPages ??= tabController.length;

    tabs.clear();

    tabController = TabController(
        initialIndex: initialIndex, length: numOfPages, vsync: vsync);

    for (var i = 0; i < tabController.length; i++) {
      GlobalKey key = GlobalKey();
      // Get the verse number from the text itself.
      // The 48 book skips some verses.
      tabs.add(Tab(
        key: key,
        text: songBooks[book.name][songKey]['texts'][i].split('.')[0],
      ));
      tabKeys[i] = key;
    }

    tabController.addListener(() {
      verse = tabController.index;
      scrollVerseBarToCurrent();
      showThenHideVerseBar();
      notifyListeners();
    });

    // show verse bar when user starts scrolling
    tabController.animation!.addListener(() {
      showThenHideVerseBar();
    });
  }

  void settingsListener(
      {required BuildContext context, required TickerProvider vsync}) {
    if (tabController.length != getNumOfPages(book, songKey, context)) {
      initTabController(
          vsync: vsync,
          numOfPages: getNumOfPages(book, songKey, context),
          initialIndex: 0);
    }
  }

  // To retrieve the song data, the key (the actual number of the song) is
  // needed, not the index (the position in the list).
  String get songKey => songBooks[book.name].keys.elementAt(song);

  void showThenHideVerseBar() {
    if (DateTime.now().difference(barLastShownAtTime) <
        const Duration(seconds: 1)) return;
    isVerseBarVisible = true;
    if (verseBarHideTimer != null) verseBarHideTimer!.cancel();
    verseBarHideTimer = Timer(const Duration(seconds: 2), () {
      isVerseBarVisible = false;
      notifyListeners();
    });
    barLastShownAtTime = DateTime.now();
    notifyListeners();
  }

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
        //ensure a new versebar state is created
        verseBarKey = GlobalKey();

        initTabController(
            vsync: vsync,
            numOfPages: getNumOfPages(book, songKey, context),
            initialIndex: verse);

        scrollController.jumpTo(0);
      } else {
        tabController.animateTo(verse);
      }
    }
    notifyListeners();
    showThenHideVerseBar();
  }

  void switchSong(
      {required bool next,
      required BuildContext context,
      required TickerProvider vsync}) {
    next ? song++ : song--;
    verse = 0;

    //ensure a new versebar state is created
    verseBarKey = GlobalKey();

    initTabController(
        vsync: vsync,
        numOfPages: getNumOfPages(book, songKey, context),
        initialIndex: 0);

    scrollController.jumpTo(0);
    notifyListeners();
    showThenHideVerseBar();
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

  scrollVerseBarToCurrent({bool animate = true}) {
    Scrollable.ensureVisible(tabKeys[verse]!.currentContext!,
        alignment: 0.5,
        duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
        curve: Curves.ease);
  }

  static SongStateProvider of(BuildContext context) {
    return Provider.of<SongStateProvider>(context, listen: false);
  }
}
