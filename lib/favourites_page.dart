import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'song/song_page.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage(this.context, {super.key});

  final BuildContext context;

  // parse verseId list to data structure
  // Book -> Song -> Verse
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
  Widget build(BuildContext context) {
    Map<String, Map<String, Set<String>>> favourites =
        getFavourites(SettingsProvider.of(context).getSelectedCueContent());

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kedvencek'),
            actions: [
              PopupMenuButton(
                itemBuilder: (i) => [
                  /*// Import button
                  const PopupMenuItem(
                    enabled: false,
                    child: ListTile(
                      leading: Icon(Icons.content_paste),
                      title: Text('Importálás'),
                    ),
                  ),
                  // Export button
                  const PopupMenuItem(
                    enabled: false,
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Exportálás'),
                    ),
                  ),*/
                  // Delete all button
                  PopupMenuItem(
                    onTap: () => settings.clearCue(settings.selectedCue),
                    child: const ListTile(
                      leading: Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      title: Text('Összes törlése'),
                    ),
                  ),
                ],
              )
            ],
          ),
          body: ListView(
            children: [
              bookTile(favourites, Book.black, settings),
              bookTile(favourites, Book.blue, settings),
              ListTile(
                subtitle: Text(
                  '''
Megjelölhetsz versszakokat kedvencként.

A jelöléshez használd a versválasztó sáv melletti csillag gombot, ha minden kottát megjelenítesz az appban.

Ha nem jelenítesz meg minden kottát, az adott versszakot tartsd hosszan lenyomva a hozzáadáshoz.''',
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.secondary),
                ),
              )
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
                      verseTile(book, songKey, int.parse(verseIndex), 1, settings)) // TOOD replace 1 with actual cue index
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
      Book book, String songKey, int verseIndex, int cueIndex, SettingsProvider settings) {
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
                '${songBooks[book.name][songKey]['texts'][verseIndex].split('.')[0]}. versszak',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => settings.removeFromCueAt(settings.selectedCue, cueIndex),
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
