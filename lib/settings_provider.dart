import 'dart:convert';

import 'package:enekeskonyv/home/chapter_utils.dart';
import 'package:flutter/material.dart';
import 'package:mailto/mailto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'error_dialog.dart';

Map<String, dynamic> songBooks = {};
Map<String, List<HomePageItem>> chapterTree = {};

class SettingsProvider extends ChangeNotifier {
  late GlobalKey<NavigatorState> navigatorKey;

  static const Book defaultBook = Book.blue;
  static const ScoreDisplay defaultScoreDisplay = ScoreDisplay.all;
  static const double defaultFontSize = 14.0;
  static const ThemeMode defaultAppThemeMode = ThemeMode.system;
  static const ThemeMode defaultSheetThemeMode = ThemeMode.light;
  static const bool defaultIsOledTheme = false;
  static const bool defaultTapNavigation = true;
  static const bool defaultIsVerseBarPinned = false;
  static const bool defaultIsVerseBarEnabled = true;
  static const bool defaultSearchNumericKeyboard = false;
  static const String defaultSelectedCue = 'Kedvencek';
  static const String defaultCueStore = '{"Kedvencek": []}';
  static const String defaultReadNewsIds = '[]';
  static const String defaultExpandedChapters = '{}';

  Book _book = defaultBook;
  ScoreDisplay _scoreDisplay = defaultScoreDisplay;
  double _fontSize = defaultFontSize;
  ThemeMode _appThemeMode = defaultAppThemeMode;
  ThemeMode _sheetThemeMode = defaultSheetThemeMode;
  bool _isOledTheme = defaultIsOledTheme;
  bool _tapNavigation = defaultTapNavigation;
  bool _isVerseBarPinned = defaultIsVerseBarPinned;
  bool _isVerseBarEnabled = defaultIsVerseBarEnabled;
  bool _searchNumericKeyboard = defaultSearchNumericKeyboard;
  String _selectedCue = defaultSelectedCue;
  Map _cueStore = jsonDecode(defaultCueStore);
  List<String> _readNewsIds = [];
  Map _expandedChapters = jsonDecode(defaultExpandedChapters);

  bool _initialized = false;

  Book get book => _book;
  ScoreDisplay get scoreDisplay => _scoreDisplay;
  double get fontSize => _fontSize;
  ThemeMode get appThemeMode => _appThemeMode;
  ThemeMode get sheetThemeMode => _sheetThemeMode;
  bool get isOledTheme => _isOledTheme;
  bool get tapNavigation => _tapNavigation;
  bool get isVerseBarPinned => _isVerseBarPinned;
  bool get isVerseBarEnabled => _isVerseBarEnabled;
  bool get searchNumericKeyboard => _searchNumericKeyboard;
  String get selectedCue => _selectedCue;
  Map get cueStore => _cueStore;
  List<String> get readNewsIds => _readNewsIds;
  Map get expandedChapters => _expandedChapters;

  // Returns whether a chapter should be initially expanded for a given book key ("21" or "48")
  bool getIsChapterExpanded(String bookKey, String chapterTitle) {
    final bookMap = _expandedChapters[bookKey];
    if (bookMap is Map) {
      final value = bookMap[chapterTitle];
      return value == true;
    }
    return false;
  }

  String get bookAsString {
    switch (_book) {
      case Book.black:
        return '48';

      case Book.blue:
        return '21';
    }
  }

  Brightness getCurrentAppBrightness(BuildContext context) {
    switch (appThemeMode) {
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context);
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.light:
        return Brightness.light;
    }
  }

  Brightness getCurrentSheetBrightness(BuildContext context) {
    switch (sheetThemeMode) {
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context);
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.light:
        return Brightness.light;
    }
  }

  List<String>? getCueContentOf(String cue) => _cueStore[cue]?.cast<String>();
  List<String> getSelectedCueContent() => getCueContentOf(_selectedCue) ?? [];
  bool getIsInCue(String cue, String verse) =>
      _cueStore[cue]?.contains(verse) ?? false;
  bool getIsInSelectedCue(String verse) => getIsInCue(_selectedCue, verse);

  bool get initialized => _initialized;

  //! Setters

  void setPref(String key, dynamic value) async {
    try {
      SharedPreferences.getInstance().then((prefs) {
        if (value is int) prefs.setInt(key, value);
        if (value is double) prefs.setDouble(key, value);
        if (value is bool) prefs.setBool(key, value);
        if (value is String) prefs.setString(key, value);
      });
    } catch (e, s) {
      showError(
        'Nem sikerült menteni a beállítást ($key). Az alkalmazás továbbra is használható, de a változtatás elveszhet újraindításkor.',
        e,
        s,
      );
    }
  }

  Future changeBook(Book value) async {
    _book = value;
    notifyListeners();
    setPref('bookEnum', value.index);
  }

  //! Theming
  Future changeScoreDisplay(ScoreDisplay value) async {
    _scoreDisplay = value;
    notifyListeners();
    setPref('scoreDisplayEnum', value.index);
  }

  Future changeFontSize(double value) async {
    _fontSize = value;
    notifyListeners();
    setPref('fontSize', value);
  }

  Future changeAppBrightnessSetting(ThemeMode value) async {
    _appThemeMode = value;
    notifyListeners();
    setPref('appThemeMode', value.index);
  }

  Future changeSheetBrightnessSetting(ThemeMode value) async {
    _sheetThemeMode = value;
    notifyListeners();
    setPref('sheetThemeMode', value.index);
  }

  Future changeIsOledTheme(bool value) async {
    _isOledTheme = value;
    notifyListeners();
    setPref('isOledTheme', value);
  }

  //! Interaction
  Future changeTapNavigation(bool value) async {
    _tapNavigation = value;
    notifyListeners();
    setPref('tapNavigation', value);
  }

  Future changeIsVerseBarPinned(bool value) async {
    _isVerseBarPinned = value;
    notifyListeners();
    setPref('isVerseBarPinned', value);
  }

  Future changeIsVerseBarEnabled(bool value) async {
    _isVerseBarEnabled = value;
    notifyListeners();
    setPref('isVerseBarEnabled', value);
  }

  Future changeSearchNumericKeyboard(bool value) async {
    _searchNumericKeyboard = value;
    notifyListeners();
    setPref('searchNumericKeyboard', value);
  }

  //! Home chapter expansion states
  Future setChapterExpandedState(
    Book book,
    String chapterTitle,
    bool isOpen,
  ) async {
    final bookKey = book.name; // '21' or '48'
    if (_expandedChapters[bookKey] == null ||
        _expandedChapters[bookKey] is! Map) {
      _expandedChapters[bookKey] = <String, bool>{};
    }
    // Update state
    (_expandedChapters[bookKey] as Map)[chapterTitle] = isOpen;
    notifyListeners();
    setPref('expandedChapters', jsonEncode(_expandedChapters));
  }

  // Bulk update expansion states for multiple chapters in a single notify/persist
  Future setAllChaptersExpandedState(
    Book book,
    bool isOpen,
    Iterable<String> chapterTitles,
  ) async {
    final bookKey = book.name;
    if (_expandedChapters[bookKey] == null ||
        _expandedChapters[bookKey] is! Map) {
      _expandedChapters[bookKey] = <String, bool>{};
    }
    final map = (_expandedChapters[bookKey] as Map);
    for (final title in chapterTitles) {
      map[title] = isOpen;
    }
    notifyListeners();
    setPref('expandedChapters', jsonEncode(_expandedChapters));
  }

  //! Cuelists
  Future changeSelectedCue(String value) async {
    _selectedCue = value;
    notifyListeners();
    setPref('selectedCue', value);
  }

  Future saveCue(String cue, List<String> verses) async {
    _cueStore[cue] = verses;
    setPref('setStore', jsonEncode(_cueStore));
  }

  Future clearCue(String cue) async {
    if (cue == 'Kedvencek') {
      _cueStore[cue] = [];
    } else {
      _cueStore.remove(cue);
    }
    notifyListeners();
    setPref('setStore', jsonEncode(_cueStore));
  }

  Future addToCue(String cue, String verse) async {
    if (_cueStore[cue] == null) {
      _cueStore[cue] = [];
    }
    _cueStore[cue].add(verse);
    notifyListeners();
    setPref('setStore', jsonEncode(_cueStore));
  }

  Future removeAllInstancesFromCue(String cue, String verse) async {
    _cueStore[cue].removeWhere((item) => item == verse);
    notifyListeners();
    setPref('setStore', jsonEncode(_cueStore));
  }

  Future removeFromCueAt(String cue, int index) async {
    _cueStore[cue].removeAt(index);
    notifyListeners();
    setPref('setStore', jsonEncode(_cueStore));
  }

  Future reorderCue(String cue, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _cueStore[cue].removeAt(oldIndex);
    _cueStore[cue].insert(newIndex, item);
    notifyListeners();
    setPref('setStore', jsonEncode(_cueStore));
  }

  //! News
  Future markNewsAsRead(String newsId) async {
    if (!_readNewsIds.contains(newsId)) {
      _readNewsIds.add(newsId);
      notifyListeners();
      setPref('readNewsIds', jsonEncode(_readNewsIds));
    }
  }

  bool isNewsRead(String newsId) {
    return _readNewsIds.contains(newsId);
  }

  Future factoryReset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await initialize(navigatorKey);
    notifyListeners();
  }

  late PackageInfo packageInfo;

  Future initialize(GlobalKey<NavigatorState> navigatorKey) async {
    this.navigatorKey = navigatorKey;

    await Future.delayed(Duration.zero); // Wait for navigatorKey to be set.

    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (e, s) {
      packageInfo = PackageInfo(
        appName: 'Hiba',
        packageName: 'Hiba',
        version: '#.#.#',
        buildNumber: '###',
      );
      showError(
        'Nem sikerült lekérdezni az alkalmazás verziószámát. Ez nem befolyásolja az alkalmazás működését.',
        e,
        s,
      );
    }

    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e, s) {
      showError(
        'Nem sikerült betölteni a beállításokat. Az alkalmazás az alapértelmezett beállításokkal fog működni.',
        e,
        s,
      );
      return;
    }

    try {
      if (prefs.getString('initAppVersion') == null) {
        // First run.
        prefs.setString('initAppVersion', packageInfo.version);
        print('First run, assigning defaults.'); // ignore: avoid_print
        assignDefaults();
        _initialized = true;
        notifyListeners();
        return;
      }

      //! Book selection.
      // First try migrating from previous version.
      String? bookMigrateString = prefs.getString('book');
      if (bookMigrateString != null) {
        _book = bookMigrateString == '21' ? Book.blue : Book.black;
        // Save the new entry and remove old one.
        await prefs.setInt('bookEnum', _book.index);
        await prefs.remove('book');
      } else {
        // Read saved value.
        _book = Book.values[prefs.getInt('bookEnum') ?? defaultBook.index];
      }

      //! Score appearance.
      _scoreDisplay =
          ScoreDisplay.values[prefs.getInt('scoreDisplayEnum') ??
              defaultScoreDisplay.index];

      _fontSize = prefs.getDouble('fontSize') ?? defaultFontSize;

      //! Brightness.
      _appThemeMode = ThemeMode
          .values[prefs.getInt('appThemeMode') ?? defaultAppThemeMode.index];

      _sheetThemeMode =
          ThemeMode.values[prefs.getInt('sheetThemeMode') ??
              defaultSheetThemeMode.index];

      //! Others
      _tapNavigation = prefs.getBool('tapNavigation') ?? defaultTapNavigation;
      _isVerseBarPinned =
          prefs.getBool('isVerseBarPinned') ?? defaultIsVerseBarPinned;
      _isVerseBarEnabled =
          prefs.getBool('isVerseBarEnabled') ?? defaultIsVerseBarEnabled;
      _isOledTheme = prefs.getBool('isOledTheme') ?? defaultIsOledTheme;
      _searchNumericKeyboard =
          prefs.getBool('searchNumericKeyboard') ??
          defaultSearchNumericKeyboard;
      _selectedCue = prefs.getString('selectedCue') ?? selectedCue;
      _cueStore = jsonDecode(prefs.getString('setStore') ?? defaultCueStore);
      _expandedChapters = jsonDecode(
        prefs.getString('expandedChapters') ?? defaultExpandedChapters,
      );
      if (!cueStore.containsKey(_selectedCue)) {
        _selectedCue = defaultSelectedCue;
      }
      _readNewsIds = (jsonDecode(prefs.getString('readNewsIds') ?? defaultReadNewsIds) as List)
          .cast<String>();
    } catch (e, s) {
      // On any unexpected error, use default settings.
      assignDefaults();

      // Show error message.
      showError(
        'Hiba történt a személyes beállítások betöltése közben. Az alkalmazás az alapértelmezett beállításokkal fog működni.',
        e,
        s,
      );
    }

    notifyListeners();
    _initialized = true;
  }

  void assignDefaults() {
    _book = defaultBook;
    _scoreDisplay = defaultScoreDisplay;
    _fontSize = defaultFontSize;
    _appThemeMode = defaultAppThemeMode;
    _sheetThemeMode = defaultSheetThemeMode;
    _tapNavigation = defaultTapNavigation;
    _isVerseBarPinned = defaultIsVerseBarPinned;
    _isVerseBarEnabled = defaultIsVerseBarEnabled;
    _isOledTheme = defaultIsOledTheme;
    _searchNumericKeyboard = defaultSearchNumericKeyboard;
    _selectedCue = defaultSelectedCue;
    _cueStore = jsonDecode(defaultCueStore);
    _readNewsIds = jsonDecode(defaultReadNewsIds).cast<String>();
    _expandedChapters = jsonDecode(defaultExpandedChapters);
  }

  void showError(String message, Object? e, StackTrace? s) {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      // Use the new error dialog instead of SnackBar
      ErrorDialog.show(
        context: context,
        title: 'Alkalmazáshiba',
        message: message,
        settings: this,
        error: e,
        stackTrace: s,
      );
    } else {
      // Fallback to SnackBar if context is not available
      final messenger = ScaffoldMessenger.of(navigatorKey.currentContext!);
      messenger.showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Jelentés',
            backgroundColor: Colors.grey[800],
            textColor: Colors.white,
            onPressed: () {
              launchUrl(
                Uri.parse(
                  Mailto(
                    to: ['app@reflabs.hu'],
                    subject:
                        'Programhiba ${packageInfo.version}+${packageInfo.buildNumber}',
                    body:
                        '''



Írd le a vonal fölé, mit tapasztaltál a hiba fellépésekor. Csatolhatsz képet is.

----

$message

$e

$s''',
                  ).toString(),
                ),
              );
            },
          ),
        ),
      );
    }
  }
}

// @see https://stackoverflow.com/a/29567669
enum Book {
  black('48'),
  blue('21');

  final String name;

  String get displayName =>
      this == Book.black ? '48-as (fekete)' : '21-es (kék)';

  const Book(this.name);
}

// @TODO Replace below function with above approach: enum with named consts.
enum ScoreDisplay { all, first, none }

String getScoreDisplayName(ScoreDisplay scoreDisplay) {
  switch (scoreDisplay) {
    case ScoreDisplay.first:
      return 'Első vers';

    case ScoreDisplay.none:
      return 'Nincs';

    case ScoreDisplay.all:
      return 'Minden vers';
  }
}

String getThemeModeName(ThemeMode themeMode) {
  switch (themeMode) {
    case ThemeMode.system:
      return 'Rendszer';
    case ThemeMode.dark:
      return 'Sötét';
    case ThemeMode.light:
      return 'Világos';
  }
}
