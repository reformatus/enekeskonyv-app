import 'dart:convert';

import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/services.dart';

sealed class HomePageItem {
  String? get startingSongKey;
}

class HomePageSongsItem extends HomePageItem {
  final String? _startingSongKey;
  List<String> songKeys = [];

  @override
  String? get startingSongKey => _startingSongKey;

  HomePageSongsItem(this._startingSongKey);
}

class HomePageChapterItem extends HomePageItem {
  final String title;
  List<HomePageItem> children;

  @override
  String? get startingSongKey => children.firstOrNull?.startingSongKey;

  HomePageChapterItem(this.title, this.children);
}

Future<Map<String, List<HomePageItem>>> getHomeChapterTree() async {
  if (songBooks.isEmpty) {
    throw Exception('Load songBooks before using getHomePageItems!');
  }

  Map chaptersJson =
      (jsonDecode(await rootBundle.loadString('assets/fejezetek.json')) as Map);

  List<HomePageItem> getChapterTreeForBook(String bookKey) {
    Iterable<MapEntry> chapterEntries = chaptersJson[bookKey].entries;

    List<HomePageSongsItem> songsItems = [];

    List<HomePageItem> chaptersFromEntries(Iterable<MapEntry> entries) {
      List<HomePageItem> items = [];

      for (MapEntry entry in entries) {
        switch (entry.value) {
          case Map map:
            // Further nesting
            items.add(
              HomePageChapterItem(entry.key, chaptersFromEntries(map.entries)),
            );
            break;
          case String string:
            // Starting song key
            final songsItem = HomePageSongsItem(string);
            items.add(HomePageChapterItem(entry.key, [songsItem]));
            songsItems.add(songsItem);
            break;
          default:
            throw Exception('Invalid chapter data JSON');
        }
      }

      return items;
    }

    List<HomePageItem> chapterTree = chaptersFromEntries(chapterEntries);
    final firstSongsItem = HomePageSongsItem(null);
    chapterTree.insert(0, firstSongsItem);
    songsItems.insert(0, firstSongsItem);

    List<String> songKeys = (songBooks[bookKey] as Map<String, dynamic>).keys
        .toList();

    for (var i = 0; i < songsItems.length; i++) {
      final item = songsItems[i];

      // Does not handle songKey defined in fejezetek.json missing in enekeskonyv.json, make sure to validate data.
      item.songKeys.addAll(
        songKeys.getRange(
          item.startingSongKey == null
              ? 0
              : songKeys.indexOf(item.startingSongKey!),
          (i >= (songsItems.length - 1))
              ? songKeys.length
              : songKeys.indexOf(songsItems[i + 1].startingSongKey!),
        ),
      );
    }

    return chapterTree;
  }

  return chaptersJson.map((k, v) => MapEntry(k, getChapterTreeForBook(k)));
}
