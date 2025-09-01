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
  DateTime barLastShownAtTime = DateTime.now().subtract(
    const Duration(seconds: 10),
  );
  Timer? verseBarHideTimer;
  List<Widget> tabs = [];
  Map<int, GlobalKey> tabKeys = {};
  GlobalKey verseBarKey = GlobalKey();

  int? _cueIndex;
  int? get cueIndex => _cueIndex;
  set cueIndex(int? value) {
    _cueIndex = value;
    notifyListeners();
  }

  bool get inCue => _cueIndex != null;

  SongStateProvider({
    required this.song,
    required this.verse,
    required this.book,
    required TickerProvider vsync,
    required BuildContext context,
    required int? cueIndex,
  }) : _cueIndex = cueIndex {
    initTabController(
      vsync: vsync,
      numOfPages: getNumOfPages(book, songKey, context, inCue),
      initialIndex:
          (inCue ||
              SettingsProvider.of(context).scoreDisplay == ScoreDisplay.all)
          ? verse
          : 0,
      initial: true,
    );
    showThenHideVerseBar();
  }

  void initTabController({
    int? numOfPages,
    int? initialIndex,
    bool initial = false,
    required TickerProvider vsync,
  }) {
    initialIndex ??= tabController.index;
    numOfPages ??= tabController.length;

    tabs.clear();

    tabController = TabController(
      initialIndex: initialIndex,
      length: numOfPages,
      vsync: vsync,
    );

    for (var i = 0; i < tabController.length; i++) {
      GlobalKey key = GlobalKey();
      // Get the verse number from the text itself.
      // The 48 book skips some verses.
      tabs.add(
        Tab(
          key: key,
          text: songBooks[book.name][songKey]['texts'][i].split('.')[0],
        ),
      );
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

  void settingsListener({
    required BuildContext context,
    required TickerProvider vsync,
  }) {
    if (tabController.length != getNumOfPages(book, songKey, context, inCue)) {
      initTabController(
        vsync: vsync,
        numOfPages: getNumOfPages(book, songKey, context, inCue),
        initialIndex: 0,
      );
    }
  }

  // To retrieve the song data, the key (the actual number of the song) is
  // needed, not the index (the position in the list).
  String get songKey => songBooks[book.name].keys.elementAt(song);

  void showThenHideVerseBar() {
    if (DateTime.now().difference(barLastShownAtTime) <
        const Duration(seconds: 1)) {
      return;
    }
    isVerseBarVisible = true;
    if (verseBarHideTimer != null) verseBarHideTimer!.cancel();
    verseBarHideTimer = Timer(const Duration(seconds: 2), () {
      isVerseBarVisible = false;
      notifyListeners();
    });
    barLastShownAtTime = DateTime.now();
    notifyListeners();
  }

  void switchVerse({
    required bool next,
    required SettingsProvider settingsProvider,
    required BuildContext context,
    required TickerProvider vsync,
  }) {
    int originalVerse = verse;
    int originalSong = song;

    if (next) {
      // Only allow switching to the next verse when all verses should have
      // scores (and there _is_ a next verse).
      if ((settingsProvider.scoreDisplay == ScoreDisplay.all || inCue) &&
          verse < songBooks[book.name][songKey]['texts'].length - 1) {
        verse++;
      } else if (song < songBooks[book.name].length - 1) {
        song++;
        verse = 0;
      }
    } else {
      // Only allow switching to the previous verse when all verses should
      // have scores (and there _is_ a previous verse).
      if ((settingsProvider.scoreDisplay == ScoreDisplay.all || inCue) &&
          verse > 0) {
        verse--;
      } else if (song > 0) {
        song--;
        if (settingsProvider.scoreDisplay == ScoreDisplay.all || inCue) {
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
        // Ensure a new versebar state is created
        verseBarKey = GlobalKey();

        initTabController(
          vsync: vsync,
          numOfPages: getNumOfPages(book, songKey, context, inCue),
          initialIndex: verse,
        );

        scrollController.jumpTo(0);
      } else {
        tabController.animateTo(verse);
      }
    }
    notifyListeners();
    showThenHideVerseBar();
  }

  void switchSong({
    required bool next,
    required BuildContext context,
    required TickerProvider vsync,
  }) {
    next ? song++ : song--;
    verse = 0;

    // Ensure a new versebar state is created
    verseBarKey = GlobalKey();

    initTabController(
      vsync: vsync,
      numOfPages: getNumOfPages(book, songKey, context, inCue),
      initialIndex: 0,
    );

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

  bool cueElementExists(SettingsProvider settings, {required bool next}) {
    if (next) {
      return _cueIndex! < settings.cueStore[settings.selectedCue].length - 1;
    } else {
      return _cueIndex! > 0;
    }
  }

  void advanceCue(
    BuildContext context,
    SettingsProvider settings,
    TickerProvider vsync, {
    bool backward = false,
  }) {
    if (backward) {
      changeToVerseIdInCue(
        settings.cueStore[settings.selectedCue][_cueIndex! - 1],
        _cueIndex! - 1,
        context,
        vsync,
      );
    } else {
      changeToVerseIdInCue(
        settings.cueStore[settings.selectedCue][_cueIndex! + 1],
        _cueIndex! + 1,
        context,
        vsync,
      );
    }
  }

  void changeToVerseIdInCue(
    String verseId,
    int cueIndex,
    BuildContext context,
    TickerProvider vsync,
  ) {
    var parts = verseId.split('.');
    Book book = Book.values.firstWhere((b) => b.name == parts[0]);
    String songKey = parts[1];
    int verseIndex = int.parse(parts[2]);

    this.book = book;
    song = songBooks[book.name].keys.toList().indexOf(songKey);
    verse = verseIndex;
    _cueIndex = cueIndex;

    // Ensure that a new versebar state is created
    verseBarKey = GlobalKey();

    initTabController(
      vsync: vsync,
      numOfPages: getNumOfPages(book, songKey, context, inCue),
      initialIndex:
          (inCue ||
              SettingsProvider.of(context).scoreDisplay == ScoreDisplay.all)
          ? verse
          : 0,
      initial: true,
    );

    scrollController.jumpTo(0);
    notifyListeners();

    showThenHideVerseBar();
    scrollVerseBarToCurrent(animate: false);
  }

  void scrollVerseBarToCurrent({bool animate = true}) {
    Scrollable.ensureVisible(
      tabKeys[verse]!.currentContext!,
      alignment: 0.5,
      duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.ease,
    );
  }

  static SongStateProvider of(BuildContext context) {
    return Provider.of<SongStateProvider>(context, listen: false);
  }
}
