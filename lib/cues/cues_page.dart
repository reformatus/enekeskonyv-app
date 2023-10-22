import 'dart:io';

import 'package:enekeskonyv/search_song_page.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';

import '../settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../song/song_page.dart';
import 'link.dart';

class CuesPage extends StatelessWidget {
  CuesPage(this.context, {super.key});

  final BuildContext context;
  final GlobalKey dropdownKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
            appBar: AppBar(
                title: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                key: dropdownKey,
                isExpanded: true,
                value: settings.selectedCue,
                onChanged: (value) {
                  if (value == null) {
                    showNewCueDialog(context, settings);
                    return;
                  }
                  settings.changeSelectedCue(value);
                },
                selectedItemBuilder: (context) {
                  // Need to insert an element to the beginning of the list
                  // to account for New button
                  return ['', ...settings.cueStore.keys]
                      .map((cue) => Center(
                            widthFactor: 1,
                            child: Text(
                              settings.selectedCue,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.normal),
                            ),
                          ))
                      .toList();
                },
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.add,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        Text(
                          'Új lista',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  ...settings.cueStore.keys
                      .map((cue) => DropdownMenuItem<String?>(
                            value: cue,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  cue,
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => showDeleteCueDialog(
                                      cue, context, settings),
                                )
                              ],
                            ),
                          ))
                      .toList()
                ],
              ),
            )),
            body: Column(
              children: [
                Material(
                  elevation: 5,
                  child: SizedBox(
                    height: 45,
                    child: FadingEdgeScrollView.fromScrollView(
                      shouldDisposeScrollController: true,
                      child: ListView(
                        controller: ScrollController(),
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(6),
                        children: [
                          /* // TODO later
                          ElevatedButton.icon(
                            label: const Text('Lista beolvasás'),
                            onPressed: null,
                            icon: const Icon(Icons.qr_code_scanner),
                          ),*/
                          const SizedBox(width: 5),
                          ElevatedButton.icon(
                            label: const Text('Megosztás'),
                            onPressed: settings.getSelectedCueContent().isEmpty
                                ? null
                                : () => showShareDialog(
                                    context, settings.selectedCue,
                                    cueContent:
                                        settings.getSelectedCueContent()),
                            icon: const Icon(Icons.share),
                          ),
                          const SizedBox(width: 5),
                          ElevatedButton.icon(
                            label: const Text('Ének hozzáfűzés'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MySearchSongPage(
                                  book: settings.book,
                                  settingsProvider: settings,
                                  addToCueSearch: true,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.manage_search),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView(
                    onReorder: (oldIndex, newIndex) => settings.reorderCue(
                        settings.selectedCue, oldIndex, newIndex),
                    physics:
                        Platform.isIOS ? const BouncingScrollPhysics() : null,
                    children: getVerseTiles(settings),
                  ),
                ),
              ],
            ));
      },
    );
  }

  Future showDeleteCueDialog(
      String cueName, BuildContext context, SettingsProvider settings) {
    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Lista törlése'),
        content: Text('Biztosan törölni szeretnéd a(z) $cueName listát?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () {
              settings.clearCue(cueName);
              try {
                settings.changeSelectedCue(
                    settings.cueStore.keys.firstWhere((cue) => cue != cueName));
              } catch (_) {
                settings.changeSelectedCue(SettingsProvider.defaultSelectedCue);
              }
              Navigator.pop(context);
              Navigator.pop(dropdownKey.currentContext!);
            },
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
  }

  Future showNewCueDialog(BuildContext context, SettingsProvider settings) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();

        onTap(String text) {
          text = text.trim();

          if (settings.cueStore.containsKey(text)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('A(z) $text lista már létezik!')),
            );
            Navigator.pop(context);
            return;
          }
          if (text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A lista neve nem lehet üres!')),
            );
            Navigator.pop(context);
            return;
          }

          settings.saveCue(text, []);
          settings.changeSelectedCue(text);
          Navigator.pop(context);
        }

        return AlertDialog(
          title: const Text('Új lista'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Lista neve',
            ),
            autofocus: true,
            onSubmitted: (text) => onTap(text),
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mégse'),
            ),
            FilledButton(
              onPressed: () => onTap(controller.text),
              child: const Text('Létrehozás'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> getVerseTiles(SettingsProvider settings) {
    List<Widget> verseTiles = [];

    int i = 0;
    // Set to selected book so first time it's not displayed redundantly
    String lastBook = settings.book.name;
    String lastSong = "";
    for (String verseId in settings.getSelectedCueContent()) {
      List<String> parts = verseId.split('.');
      String bookName = parts[0];
      String songKey = parts[1];
      int verseIndex = int.parse(parts[2]);

      verseTiles.add(
        // Had to factor out for tile removing closure to work properly (???)
        verseTile(bookName, songKey, verseIndex, lastBook != bookName,
            lastSong != songKey, i, settings),
      );
      lastBook = bookName;
      lastSong = songKey;

      i++;
    }

    return verseTiles;
  }

  Widget verseTile(String bookName, String songKey, int verseIndex,
      bool newBook, bool newSong, int cueIndex, SettingsProvider settings) {
    Book book = Book.values.firstWhere((b) => b.name == bookName);
    String verse = songBooks[bookName][songKey]['texts'][verseIndex];
    String verseNumber = verse.split('.')[0];
    String verseText = verse.substring(verseNumber.length + 2);

    return InkWell(
      key: GlobalKey(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return SongPage(
                book: book,
                songIndex: songBooks[book.name].keys.toList().indexOf(songKey),
                verseIndex: verseIndex,
                initialCueIndex: cueIndex,
              );
            },
          ),
          // request focus to show keyboard when returning from song page
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (newBook) ...[
                  Container(
                    margin: const EdgeInsets.only(left: 15, top: 20),
                    child: Text(
                      '${book.displayName} énekeskönyv',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                if (newSong)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 15, top: 15, bottom: 5),
                    child: Text(
                      '$songKey. ${songBooks[bookName][songKey]['title']}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                  ),
                  margin: const EdgeInsets.only(left: 20),
                  padding: const EdgeInsets.all(11),
                  child: Row(
                    children: [
                      Text('$verseNumber. ',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          verseText,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 35,
            child: IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () =>
                  settings.removeFromCueAt(settings.selectedCue, cueIndex),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: Icon(Icons.drag_handle),
          ),
        ],
      ),
    );
  }
}
