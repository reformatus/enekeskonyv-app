import 'dart:collection';
import 'dart:convert' show json;
import 'dart:io';

import 'package:enekeskonyv/quick_settings_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'settings_provider.dart';
import 'goto_song_form.dart';
import 'search_song_page.dart';
import 'song/song_page.dart';
import 'util.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> _jsonSongBooks = {};

  // @see https://www.kindacode.com/article/how-to-read-local-json-files-in-flutter/
  Future<void> _readJson() async {
    final String response =
        await rootBundle.loadString('assets/enekeskonyv.json');
    _jsonSongBooks = (await compute(json.decode, response))
        as LinkedHashMap<String, dynamic>;
    songBooks = _jsonSongBooks;
    setState(() {});
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

    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        // Do not show the list before the provider is initialized to avoid
        // flicking the default book's list when the user already selected a
        // non-default book before starting the app again.
        if (!provider.initialized) {
          return const Scaffold();
        }
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: 'Válassz énekeskönyvet',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Book>(
                        isExpanded: true,
                        value: provider.book,
                        items: [
                          DropdownMenuItem(
                            value: Book.blue,
                            child: Text(
                              '${Book.blue.displayName} énekeskönyv',
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: Book.black,
                            child: Text(
                              '${Book.black.displayName} énekeskönyv',
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => provider.changeBook(value!),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // @see https://www.youtube.com/watch?v=Xdt8TlwNRAM
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return MySearchSongPage(
                            book: provider.book,
                            settingsProvider: provider,
                          );
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.search_outlined),
                  tooltip: 'Keresés',
                  key: const Key('_MyHomePageState.SearchSongButton'),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return MyGotoSongForm(
                            book: provider.book,
                            settingsProvider: provider,
                          );
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.apps),
                  tooltip: 'Ugrás énekre',
                  key: const Key('_MyHomePageState.GotoSongButton'),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          // Not in song context, therefore no links, thanks.
                          QuickSettingsDialog(),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  tooltip: 'Beállítások',
                  key: const Key('_MyHomePageState.SettingsButton'),
                ),
              ],
            ),
            bottom: (_jsonSongBooks.isEmpty)
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(3),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          body: (_jsonSongBooks.isEmpty)
              ? null
              : CupertinoScrollbar(
                  // Using CupertinoScrollbar on Android too (looks better and
                  // is interactive by default). Also, it should be wide enough
                  // to be useful for a finger (to be able to scroll through the
                  // whole list which is quite long).
                  thickness: 10.0,
                  child: ListView.builder(
                    physics:
                        Platform.isIOS ? const BouncingScrollPhysics() : null,
                    itemCount: _jsonSongBooks[provider.bookAsString].length,
                    itemBuilder: (context, i) {
                      return ListTile(
                        title: Text(getSongTitle(
                            _jsonSongBooks[provider.bookAsString][
                                _jsonSongBooks[provider.bookAsString]
                                    .keys
                                    .elementAt(i)])),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return SongPage(
                                  book: provider.book,
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
