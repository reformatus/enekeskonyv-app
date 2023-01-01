import 'dart:collection';
import 'dart:convert' show json;
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'book_provider.dart';
import 'goto_song_form.dart';
import 'search_song_page.dart';
import 'settings_page.dart';
import 'song_page.dart';
import 'util.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LinkedHashMap<String, dynamic> _songs = LinkedHashMap();

  // @see https://www.kindacode.com/article/how-to-read-local-json-files-in-flutter/
  Future<void> _readJson() async {
    final String response =
        await rootBundle.loadString('assets/enekeskonyv.json');
    setState(() {
      _songs = json.decode(response);
    });
  }

  @override
  void initState() {
    super.initState();
    // Read the JSON once, when the app starts.
    _readJson();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    // final selectedBook = Settings.getValue<String>('book', defaultValue: '48');

    // On the initial run this might be empty (while the song file is not read
    // yet). To prevent errors below, let's display a throbber instead.
    if (_songs.isEmpty) {
      return const Scaffold();
    }

    return Consumer<BookProvider>(
      builder: (context, provider, child) {
        // Do not show the list before the provider is initialized to avoid
        // flicking the default book's list when the user already selected a
        // non-default book before starting the app again.
        if (!provider.initialized) {
          return const Scaffold();
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('Énekeskönyv (${provider.bookAsString})'),
            actions: [
              IconButton(
                onPressed: () {
                  // @see https://www.youtube.com/watch?v=Xdt8TlwNRAM
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return MySearchSongPage(
                          songs: _songs[provider.bookAsString],
                          bookProvider: provider,
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.search_outlined),
                key: const Key('_MyHomePageState.SearchSongButton'),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return MyGotoSongForm(
                          songs: _songs[provider.bookAsString],
                          bookProvider: provider,
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.apps),
                key: const Key('_MyHomePageState.GotoSongButton'),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return MySettingsPage(provider: provider);
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
                key: const Key('_MyHomePageState.SettingsButton'),
              ),
            ],
          ),
          body: CupertinoScrollbar(
            // Using CupertinoScrollbar on Android too (looks better and is
            // interactive by default). Also, it should be wide enough to be
            // useful for a finger (to be able to scroll through the whole list
            // which is quite long).
            thickness: 10.0,
            child: ListView.builder(
              physics: Platform.isIOS ? const BouncingScrollPhysics() : null,
              itemCount: _songs[provider.bookAsString].length,
              itemBuilder: (context, i) {
                return ListTile(
                  title: Text(getSongTitle(_songs[provider.bookAsString]
                      [_songs[provider.bookAsString].keys.elementAt(i)])),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return MySongPage(
                            songsInBook: _songs[provider.bookAsString],
                            bookProvider: provider,
                            songIndex: i,
                          );
                        },
                      ),
                    );
                  },
                  key: const Key('_MyHomePageState.ListTile'),
                );
              },
            ),
          ),
          key: const Key('_MyHomePageState'),
        );
      },
    );
  }
}
