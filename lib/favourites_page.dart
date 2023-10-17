import 'package:enekeskonyv/settings_provider.dart';
import 'package:enekeskonyv/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'song/song_page.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  // book / song / verse

  Map<String, Map<String, Set<String>>> getFavourites(List<String> verseIds) {
    Map<String, Map<String, Set<String>>> favourites = {};

    for (String id in verseIds) {
      List<String> parts = id.split('/');
      String book = parts[0];
      String song = parts[1];
      String verse = parts[2];

      if (!favourites.containsKey(book)) {
        favourites[book] = {};
      }
      if (!favourites[book]!.containsKey(song)) {
        favourites[book]![song] = {};
      }
      favourites[book]![song]!.add(verse);
    }

    return favourites;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, Map<String, Set<String>>> favourites =
        getFavourites(SettingsProvider.of(context).favouriteVerses);

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kedvencek'),
            actions: [
              PopupMenuButton(
                itemBuilder: (i) => [
                  // Import button
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.content_paste),
                      title: Text('Importálás'),
                    ),
                    onTap: () {
                      // TODO implement
                    },
                  ),
                  // Export button
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Exportálás'),
                    ),
                    onTap: () {
                      // TODO implement
                    },
                  ),
                  // Delete all button
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Összes törlése'),
                    ),
                    onTap: () {
                      // TODO implement
                    },
                  ),
                ],
              )
            ],
          ),
          body: ListView(
            children: [
              bookTile(favourites, Book.black, settings),
              bookTile(favourites, Book.blue, settings),
            ],
          ),
        );
      },
    );
  }

  Widget bookTile(Map<String, Map<String, Set<String>>> favourites, Book book,
      SettingsProvider settings) {
    if (favourites.keys.contains(book.name) &&
        favourites[book.name]!.isNotEmpty) {
      var songs = favourites[book.name]!.keys.toList();
      songs.sort();

      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: settings.book == book,
          title: Text(book.displayName, style: const TextStyle(fontSize: 19)),
          children: songs.map((songKey) {
            var verses = favourites[book.name]![songKey]!.toList();
            verses.sort();

            return songCard(
              book,
              songKey,
              verses
                  .map((verseIndex) =>
                      verseTile(book, songKey, int.parse(verseIndex), settings))
                  .toList(),
            );
          }).toList(),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget verseTile(
      Book book, String songKey, int verseIndex, SettingsProvider settings) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return SongPage(
              book: book,
              songIndex: songBooks[book.name].keys.toList().indexOf(songKey),
              // HACK Could be better handled on song page.
              // Maybe even implement scrolling to matching verse there
              // when showing texts?
              verseIndex: (SettingsProvider.of(context).scoreDisplay ==
                      ScoreDisplay.all)
                  ? verseIndex
                  : 0,
            );
          },
        ),
        // request focus to show keyboard when returning from song page
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
        ),
        margin: const EdgeInsets.only(left: 10, right: 10),
        padding: const EdgeInsets.all(7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${songBooks[book.name][songKey]['texts'][verseIndex].split('.')[0]}. vers',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => setState(
                () {
                  settings.removeFromFavouriteVerses(
                      getVerseId(book, songKey, verseIndex));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget songCard(Book book, String songKey, List<Widget> verseTiles) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
              margin: const EdgeInsets.only(
                  left: 10, right: 10, top: 10, bottom: 5),
              child: Text(
                '$songKey. ${songBooks[book.name][songKey]['title']}',
                style: Theme.of(context).textTheme.bodyLarge,
              )),
          ...verseTiles,
        ],
      ),
    );
  }
}
