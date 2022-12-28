import 'dart:collection';

import 'package:enekeskonyv/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
      {Key? key, required this.songs, required this.selectedBook})
      : super(key: key);

  final LinkedHashMap songs;
  final Book selectedBook;

  @override
  State<MySearchSongPage> createState() => _MySearchSongPageState();
}

class _MySearchSongPageState extends State<MySearchSongPage> {
  List<SearchVerse> allSearchVerses = [];
  List<SearchVerse> foundVerses = [];

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
        // To save some screen estate, reuse the page title for the search
        // input field.
        title: PlatformAwareTextField(
          hintText: "Keresendő szöveg (3+ betű)",
          onChanged: (searchText) {
            if (searchText.length >= 3) {
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

                return ListTile(
                  title: Text('${verse.songKey}/${verse.text}'),
                  onTap: () {
                    var tappedVerse = foundVerses[index];
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return MySongPage(
                            songsInBook: widget.songs,
                            selectedBook: widget.selectedBook,
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
  String hintText;
  void Function(String)? onChanged;
  PlatformAwareTextField({required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return isAndroid
        ? TextField(
            decoration: InputDecoration(
              hintText: hintText,
            ),
            autofocus: true,
            onChanged: onChanged)
        : CupertinoTheme(
            data: CupertinoThemeData(brightness: Brightness.dark),
            child: CupertinoTextField(
              placeholder: hintText,
              autofocus: true,
              onChanged: onChanged,
            ),
          );
  }
}
