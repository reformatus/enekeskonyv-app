import 'dart:collection';
import 'dart:convert' show json;
import 'dart:io';

import 'cues_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'quick_settings_dialog.dart';
import 'search_song_page.dart';
import 'settings_provider.dart';
import 'song/song_page.dart';
import 'util.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> jsonSongBooks = {};
  late ScrollController scrollController;
  bool fabVisible = false;

  // @see https://www.kindacode.com/article/how-to-read-local-json-files-in-flutter/
  Future<void> readJson() async {
    final String response =
        await rootBundle.loadString('assets/enekeskonyv.json');
    jsonSongBooks = (await compute(json.decode, response))
        as LinkedHashMap<String, dynamic>;
    songBooks = jsonSongBooks;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Read the JSON once, when the app starts.
    if (songBooks.isEmpty) readJson();
    scrollController = ScrollController();
    scrollController.addListener(() {
      setState(() {
        fabVisible = scrollController.position.pixels > 40;
      });
    });
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
          return Scaffold(appBar: AppBar(title: const Text('Betöltés...')));
        }
        return Scaffold(
          floatingActionButton: fabVisible
              ? FloatingActionButton.small(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return MySearchSongPage(
                          book: provider.book, settingsProvider: provider);
                    }),
                  ),
                  tooltip: 'Keresés vagy ugrás...',
                  child: const Icon(Icons.search),
                )
              : null,
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
                        items: Book.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  '${e.displayName} énekeskönyv',
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => provider.changeBook(value!),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          // Not in song context, therefore no links, thanks.
                          const QuickSettingsDialog(),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  tooltip: 'Beállítások',
                  key: const Key('_MyHomePageState.SettingsButton'),
                ),
              ],
            ),
            bottom: (songBooks.isEmpty)
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(3),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          body: (songBooks.isEmpty)
              ? null
              // TODO check why this does not work on android
              : CupertinoScrollbar(
                  // Using CupertinoScrollbar on Android too (looks better and
                  // is interactive by default). Also, it should be wide enough
                  // to be useful for a finger (to be able to scroll through the
                  // whole list which is quite long).
                  thickness: 9.0,
                  thicknessWhileDragging: 12.0,
                  radius: const Radius.circular(15.0),
                  child: ListView.builder(
                    controller: scrollController,
                    physics:
                        Platform.isIOS ? const BouncingScrollPhysics() : null,
                    itemCount: songBooks[provider.bookAsString].length + 1,
                    itemBuilder: (context, i) {
                      // Display search box as first item.
                      if (i == 0) {
                        return IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  elevation: 3,
                                  margin: const EdgeInsets.all(7),
                                  semanticContainer: true,
                                  child: InkWell(
                                    onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) {
                                      return MySearchSongPage(
                                          book: provider.book,
                                          settingsProvider: provider);
                                    })),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Icon(Icons.search),
                                        ),
                                        Text('Keresés vagy ugrás...',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Card(
                                margin: const EdgeInsets.only(
                                    top: 7, right: 7, bottom: 7),
                                elevation: 3,
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) {
                                    return FavouritesPage(context);
                                  })),
                                  child: const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Center(child: Icon(Icons.star)),
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      }

                      i--;
                      return ListTile(
                        title: Text(getSongTitle(
                            songBooks[provider.bookAsString][
                                songBooks[provider.bookAsString]
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
