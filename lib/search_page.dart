import 'dart:io';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_provider.dart';
import 'song/song_page.dart';
import 'utils.dart';

class SearchVerse {
  final String songKey;
  final int verseIndex;
  final String verseNumber;
  final String text;

  const SearchVerse({
    required this.songKey,
    required this.verseIndex,
    required this.verseNumber,
    required this.text,
  });
}

class SearchPage extends StatefulWidget {
  const SearchPage({
    Key? key,
    required this.book,
    required this.settingsProvider,
    this.addToCueSearch = false,
  }) : super(key: key);

  final Book book;
  final SettingsProvider settingsProvider;
  final bool addToCueSearch;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<SearchVerse> allSearchVerses = [];
  String searchText = '';

  /// Function that gets called when user presses Enter in the search field.
  Function onSubmit = () {};

  @override
  void initState() {
    super.initState();
    // When the page is displayed, a full list of all verses is needed as a
    // search data source.
    songBooks[widget.book.name].forEach((key, value) {
      var verseIndex = 0;
      value['texts'].forEach((valueText) {
        var splitAtPosition = (valueText as String).indexOf('.');
        allSearchVerses.add(SearchVerse(
          songKey: key,
          verseIndex: verseIndex,
          verseNumber: valueText.substring(0, splitAtPosition),
          text: valueText.substring(splitAtPosition + 1).trim(),
        ));
        verseIndex++;
      });
    });
  }

  List<Widget> getSearchResults() {
    // Reset the function to prevent "ghost-calling" with keyboard after submit, with no results.
    onSubmit = () {};

    // Jump mode
    if (searchText.contains(RegExp(r'^\d'))) {
      try {
        var searchParts = searchText.split(RegExp(r'[ \.\-/,]'));
        String songNumber = searchParts[0];
        if (!allSearchVerses.any((element) => element.songKey == songNumber)) {
          return [errorMessageTile('Nincs ilyen ének!')];
        }

        String verseNumber = searchParts.length > 1 ? searchParts[1] : '1';

        SearchVerse foundVerse;
        try {
          foundVerse = allSearchVerses.firstWhere((element) =>
              element.songKey == songNumber &&
              element.verseNumber == verseNumber);
        } catch (e) {
          return [errorMessageTile('Nincs ilyen versszak!')];
        }
        return [
          foundSongTile(
            songNumber,
            foundByNumber: true,
            firstResult: true,
            [
              foundVerseTile(
                foundVerse,
                foundByNumber: true,
                foundFirst: true,
                [TextSpan(text: foundVerse.text)],
              )
            ],
          )
        ];
      } catch (e) {
        return [errorMessageTile('Helytelen formátum!')];
      }
    }

    // Search mode
    // RegEx here: to remove all non-letters when considering search string length (unicode aware)
    // This precise method is necessary, because simply entring 3 whitespace characters would match all verses.
    if (searchText.replaceAll(RegExp(r'\P{L}', unicode: true), '').length < 3) {
      return [
        ListTile(
          subtitle: Text(
            !widget.addToCueSearch
                ? '''
Kereséshez adj meg legalább 3 betűt.

Ugráshoz add meg az ének számát.
Versszakot is megadhatsz per jellel, kötőjellel, ponttal, vesszővel vagy szóközzel elválasztva.'''
                : '''
A találatokat azonnal hozzáfűzheted a kiválasztott listához.

Hozzáfűzéshez koppints a találatra, vagy használd a Kész gombot.
''',
            style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.secondary),
          ),
        )
      ];
    }

    List<Widget> searchResults = [];
    bool firstSong = true;
    bool firstVerse = true;
    List<Widget> searchResultsFromSong = [];

    String lastSongSeen = "";

    for (var element in allSearchVerses) {
      // Continue with next verse if search text is not found in this one.
      if (!(getSearchableText(element.text)
          .contains(getSearchableText(searchText)))) {
        continue;
      }
      // Add the song card with its found verses.
      if (lastSongSeen != element.songKey && lastSongSeen.isNotEmpty) {
        searchResults.add(
          foundSongTile(lastSongSeen, searchResultsFromSong,
              firstResult: firstSong),
        );
        firstSong = false;
        searchResultsFromSong.clear();
      }
      lastSongSeen = element.songKey;

      // Highlight search text by making it bold.
      var matchPosition = getSearchableText(element.text, filterLetters: false)
          .indexOf(getSearchableText(searchText, filterLetters: false));

      List<TextSpan> titleSpans = [
        if (matchPosition >= 0) ...[
          TextSpan(
            text: element.text.substring(0, matchPosition),
          ),
          TextSpan(
            text: element.text
                .substring(matchPosition, matchPosition + searchText.length),
            style: TextStyle(
              // This is the boldest possible choice.
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextSpan(
            text: element.text.substring(matchPosition + searchText.length),
          ),
        ],
        if (matchPosition == -1) TextSpan(text: element.text),
      ];

      searchResultsFromSong
          .add(foundVerseTile(element, titleSpans, foundFirst: firstVerse));
      firstVerse = false;
    }
    if (lastSongSeen.isNotEmpty) {
      searchResults.add(foundSongTile(lastSongSeen, searchResultsFromSong,
          firstResult: firstSong));
    }

    if (searchResults.isEmpty) {
      searchResults.add(errorMessageTile('Nincs találat!'));
    }

    return searchResults;
  }

  Widget foundVerseTile(SearchVerse element, List<TextSpan> titleSpans,
      {bool foundFirst = false, bool foundByNumber = false}) {
    onTap() {
      if (!widget.addToCueSearch) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return SongPage(
                  book: widget.settingsProvider.book,
                  songIndex: songBooks[widget.book.name]
                      .keys
                      .toList()
                      .indexOf(element.songKey),
                  verseIndex: element.verseIndex);
            },
          ),
          // Request focus to show keyboard when returning from song page
        ).then((value) => keyboardFocusNode.requestFocus());
      } else {
        widget.settingsProvider
            .addToCue(
                widget.settingsProvider.selectedCue,
                getVerseId(widget.settingsProvider.book, element.songKey,
                    element.verseIndex))
            .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              content: Text('Hozzáfűzve a kiválasztott listához',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  )),
              duration: const Duration(seconds: 2),
            ),
          );
        });
      }
    }

    if (foundFirst) {
      onSubmit = onTap;
    }
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: foundFirst
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: foundFirst ? 3 : 1,
            ),
          ),
        ),
        margin: const EdgeInsets.only(left: 10, right: 10),
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (foundFirst)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Icon(
                        !widget.addToCueSearch ? Icons.shortcut : Icons.add,
                        size: 20,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Text(
                      !widget.addToCueSearch
                          ? 'Megnyitás Kész gombbal'
                          : 'Listához fűzés Kész gombbal',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                  ],
                ),
              ),
            RichText(
              text: TextSpan(
                // Without this explicit color, the search results would be
                // illegible when the app is in light mode. This makes it legible in
                // both dark and light modes.
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
                children: [
                  TextSpan(
                    text: '${element.verseNumber}. ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: foundByNumber
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  ...titleSpans,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Card foundSongTile(String lastSongSeen, List<Widget> searchResultsFromSong,
      {bool firstResult = false, bool foundByNumber = false}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: firstResult ? 10 : 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin:
                const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 5),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge!,
                children: [
                  TextSpan(
                    text: '$lastSongSeen. ',
                    style: foundByNumber
                        ? TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  TextSpan(
                      text:
                          '${songBooks[widget.book.name][lastSongSeen]['title']}'),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...searchResultsFromSong,
        ],
      ),
    );
  }

  String getSearchableText(String text, {bool filterLetters = true}) {
    if (!filterLetters) {
      return removeDiacritics(text).toLowerCase();
    }

    // Replace diacritics with their non-diacritic counterparts.
    // Remove everything that is not a letter.
    return removeDiacritics(text)
        .toLowerCase()
        .replaceAll(RegExp(r'[\W]', unicode: true), '');
  }

  Widget errorMessageTile(String error) {
    return ListTile(
      title: Text(
        error,
        style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.secondary),
      ),
    );
  }

  FocusNode keyboardFocusNode = FocusNode();
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var searchResults = getSearchResults();

    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      return Scaffold(
          appBar: AppBar(
            // To save some screen estate, reuse the page title for the search input
            // field.
            title: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    focusNode: keyboardFocusNode,
                    autofocus: true,
                    autocorrect: false,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Keresés vagy ugrás (pl: 150,3)',
                    ),
                    keyboardType: settings.searchNumericKeyboard
                        ? const TextInputType.numberWithOptions(
                            decimal: true,
                          )
                        : TextInputType.text,
                    onChanged: (e) {
                      setState(() {
                        searchText = e;
                      });
                    },
                    // Prevent keyboard from closing on submit
                    onEditingComplete: () {},
                    onSubmitted: (e) {
                      onSubmit();
                      textController.text = '';
                      setState(() {
                        searchText = '';
                      });
                    },
                  ),
                ),
                // A button to clear the search text.
                IconButton(
                    onPressed: () {
                      textController.clear();
                      setState(() {
                        searchText = '';
                      });
                    },
                    icon: Icon(
                      Icons.clear,
                      color: Theme.of(context).disabledColor,
                    )),
              ],
            ),
          ),
          floatingActionButton: (Platform.isIOS &&
                  settings.searchNumericKeyboard &&
                  searchText.isNotEmpty)
              // Show a Done button on iOS when using the numeric keyboard,
              // because the numeric keyboard does not have a submit button.
              ? FloatingActionButton(
                  onPressed: () {
                    onSubmit();
                    textController.text = '';
                    setState(() {
                      searchText = '';
                    });
                  },
                  backgroundColor: Colors.green,
                  tooltip: (widget.addToCueSearch)
                      ? 'Hozzáfűzés a kiválasztott listához'
                      : 'Ugrás',
                  child: (widget.addToCueSearch)
                      ? const Icon(Icons.add)
                      : const Icon(Icons.arrow_forward),
                )
              // A button to switch between numeric and normal keyboard.
              : FloatingActionButton(
                  tooltip: 'Váltás numerikus és normál billentyűzet között',
                  onPressed: () {
                    setState(() {
                      settings.changeSearchNumericKeyboard(
                          !settings.searchNumericKeyboard);
                      keyboardFocusNode.unfocus();
                      // Some delay necessary. Exact amount unknowable, this seems fine for now.
                      Future.delayed(const Duration(milliseconds: 100), () {
                        keyboardFocusNode.requestFocus();
                      });
                    });
                  },
                  child: Icon(settings.searchNumericKeyboard
                      ? Icons.keyboard
                      : Icons.pin_outlined),
                ),
          body: SafeArea(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return searchResults[index];
              },
            ),
          ),
          bottomSheet: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.addToCueSearch)
                Material(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  elevation: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.manage_search,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      Flexible(
                        child: Text(
                          'Hozzáfűzés: ${settings.selectedCue}',
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ));
    });
  }
}
