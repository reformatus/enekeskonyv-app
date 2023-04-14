import 'dart:collection';
import 'dart:io';

import 'package:enekeskonyv/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'settings_provider.dart';
import 'song/song_page.dart';

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
  const MySearchSongPage({
    Key? key,
    required this.book,
    required this.settingsProvider,
  }) : super(key: key);

  final Book book;
  final SettingsProvider settingsProvider;

  @override
  State<MySearchSongPage> createState() => _MySearchSongPageState();
}

class _MySearchSongPageState extends State<MySearchSongPage> {
  List<SearchVerse> allSearchVerses = [];
  List<ListTile> searchResults = [];

  @override
  void initState() {
    super.initState();
    // When the page is displayed, a full list of all verses is needed as a
    // search data source.
    songBooks[widget.book.name].forEach((key, value) {
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

  void _updateSearchResults(String searchText) {
    searchResults = [];
    String lastSongSeen = '';
    for (var element in allSearchVerses) {
      // Continue with next verse if search text is not found in this one.
      if (!(element.text.toLowerCase().contains(searchText.toLowerCase()))) {
        continue;
      }
      // Add the song title as a header for its found verses.
      if (lastSongSeen != element.songKey) {
        lastSongSeen = element.songKey;
        searchResults.add(ListTile(
          title: Text(
            '${element.songKey}. ${songBooks[widget.book.name][element.songKey]['title']}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Song titles should have no left padding.
          contentPadding: const EdgeInsets.only(
            left: 3,
            right: 3,
          ),
        ));
      }

      // Highlight search text by making it bold.
      final matchPosition =
          element.text.toLowerCase().indexOf(searchText.toLowerCase());
      List<TextSpan> titleSpans = [
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
      ];

      searchResults.add(ListTile(
        title: RichText(
          text: TextSpan(
            // Without this explicit color, the search results would be
            // illegible when the app is in light mode. This makes it legible in
            // both dark and light modes.
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
            children: titleSpans,
          ),
        ),
        // Search result verses should be left-indented.
        contentPadding: const EdgeInsets.only(
          left: 15,
          right: 3,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return SongPage(
                  book: widget.settingsProvider.book,
                  songIndex: songBooks[widget.book.name]
                      .keys
                      .toList()
                      .indexOf(element.songKey),
                  settingsProvider: widget.settingsProvider,
                  verseIndex: element.verseIndex,
                );
              },
            ),
          );
        },
      ));
    }
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
              setState(() {
                _updateSearchResults(searchText);
              });
            } else {
              // When less than 3 characters typed, empty the list.
              if (searchResults.isNotEmpty) {
                setState(() {
                  searchResults = [];
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
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return searchResults[index];
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
            data: CupertinoThemeData(
                brightness: SettingsProvider.of(context)
                    .getCurrentAppBrightness(context)),
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
