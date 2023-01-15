import 'dart:collection';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'settings_provider.dart';
import 'song_page.dart';

class SearchVerse {
  final String songKey;
  final int verseIndex;
  final String text;

  const SearchVerse({
    required this.songKey,
    required this.verseIndex,
    required this.text,
  });
}

class MySearchSongPage extends StatefulWidget {
  const MySearchSongPage(
      {Key? key, required this.songs, required this.settingsProvider})
      : super(key: key);

  final LinkedHashMap songs;
  final SettingsProvider settingsProvider;

  @override
  State<MySearchSongPage> createState() => _MySearchSongPageState();
}

class _MySearchSongPageState extends State<MySearchSongPage> {
  List<SearchVerse> allSearchVerses = [];
  List<SearchVerse> foundVerses = [];
  String searchPhrase = '';

  @override
  void initState() {
    super.initState();
    // When the page is displayed, a full list of all verses is needed as a
    // search data source.
    widget.songs.forEach((key, value) {
      var verseNumber = 0;
      value['texts'].forEach((valueText) {
        allSearchVerses.add(SearchVerse(
          songKey: key,
          verseIndex: verseNumber,
          text: valueText,
        ));
        verseNumber++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // To save some screen estate, reuse the page title for the search input
        // field.
        title: PlatformAwareTextField(
          hintText: 'Keresendő szöveg (3+ betű)',
          onChanged: (searchText) {
            if (searchText.length >= 3) {
              // Remember the search text to be able to highlight it.
              searchPhrase = searchText;
              // Update the list of found verses if there are at least 3
              // characters typed.
              final suggestions = allSearchVerses.where((verse) {
                final verseText = verse.text.toLowerCase();
                final input = searchText.toLowerCase();
                return verseText.contains(input);
              }).toList();
              setState(() {
                foundVerses = suggestions;
              });
            } else {
              // When less than 3 characters typed, empty the list.
              if (foundVerses.isNotEmpty) {
                setState(() {
                  foundVerses = [];
                });
              }
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: foundVerses.length,
              itemBuilder: (context, index) {
                final verse = foundVerses[index];
                // Highlight search phrase by making it bold.
                final matchPosition = verse.text.toLowerCase().indexOf(searchPhrase.toLowerCase());
                List<TextSpan> titleSpans = [
                  TextSpan(
                    text: '${verse.songKey}/${verse.text.substring(0, matchPosition)}',
                  ),
                  TextSpan(
                    text: verse.text.substring(matchPosition, matchPosition + searchPhrase.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: verse.text.substring(matchPosition + searchPhrase.length),
                  ),
                ];

                return ListTile(
                  title: RichText(
                    text: TextSpan(
                      children: titleSpans,
                    ),
                  ),
                  onTap: () {
                    var tappedVerse = foundVerses[index];
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return MySongPage(
                            songsInBook: widget.songs,
                            settingsProvider: widget.settingsProvider,
                            songIndex: widget.songs.keys
                                .toList()
                                .indexOf(tappedVerse.songKey),
                            verseIndex: tappedVerse.verseIndex,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PlatformAwareTextField extends StatelessWidget {
  final String hintText;
  final void Function(String)? onChanged;

  const PlatformAwareTextField(
      {Key? key, required this.hintText, required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoTheme(
            data: const CupertinoThemeData(
              brightness: Brightness.dark,
            ),
            child: CupertinoTextField(
              placeholder: hintText,
              autofocus: true,
              onChanged: onChanged,
            ),
          )
        : TextField(
            decoration: InputDecoration(
              hintText: hintText,
            ),
            autofocus: true,
            onChanged: onChanged,
          );
  }
}
