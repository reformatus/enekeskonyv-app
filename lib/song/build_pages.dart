// Builds the pages for the current song's verses.
import 'package:enekeskonyv/song/song_page_state.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/blocks/container/table.dart';
import 'package:markdown_widget/widget/markdown.dart';
import 'package:provider/provider.dart';

import '../settings_provider.dart';
import '../utils.dart';
import 'utils.dart';

List<List<Widget>> buildPages(
  Orientation orientation,
  Book book,
  String songKey,
  BuildContext context,
) {
  var state = SongStateProvider.of(context);
  // Nested list; a page is just a list of widgets.
  final List<List<Widget>> pages = [];
  SettingsProvider settings = Provider.of<SettingsProvider>(context, listen: false);

  var song = songBooks[book.name][songKey];

  if (song['markdown'] != null) {
    pages.add([
      Padding(
        padding: EdgeInsetsGeometry.all(5),
        child: MarkdownWidget(
          data: song['markdown'],
          shrinkWrap: true,
          selectable: false,
          config: MarkdownConfig(
            configs: [
              TableConfig(
                wrapper: (child) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  } else {
    // Collects the list items for the current page. When not all verses
    // should have scores displayed, the song consists of one single page.
    var page = <Widget>[];

    for (var verseIndex = 0; verseIndex < song['texts'].length; verseIndex++) {
      // Only display certain info above the first verse.
      if (verseIndex == 0) {
        page.addAll(getFirstVerseHeader(book, songKey, context));
      }

      var verseId = getVerseId(book, songKey, verseIndex);

      // Add either the score or the text of the current verse, as needed.
      if (state.inCue ||
          settings.scoreDisplay == ScoreDisplay.all ||
          (settings.scoreDisplay == ScoreDisplay.first && verseIndex == 0)) {
        Widget score = getScore(
          orientation,
          verseIndex,
          book,
          songKey,
          context,
        );

        // If song is displayed on single page, apply favourite functionality
        if (!(settings.scoreDisplay == ScoreDisplay.all || state.inCue)) {
          page.add(
            GestureDetector(
              onLongPress: settings.getIsInSelectedCue(verseId)
                  ? () => settings.removeAllInstancesFromCue(
                      settings.selectedCue,
                      verseId,
                    )
                  : () => settings.addToCue(settings.selectedCue, verseId),
              child: Column(
                children: [
                  if (settings.getIsInSelectedCue(verseId))
                    const Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [Icon(Icons.star, size: 18)],
                    ),
                  score,
                ],
              ),
            ),
          );
          // Otherwise just display a passive sheet widget
        } else {
          page.add(score);
        }
      } else {
        page.add(
          GestureDetector(
            onLongPress: settings.getIsInSelectedCue(verseId)
                ? () => settings.removeAllInstancesFromCue(
                    settings.selectedCue,
                    verseId,
                  )
                : () => settings.addToCue(settings.selectedCue, verseId),
            child: Padding(
              // Add space between verses.
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    fontSize: settings.fontSize,
                  ),
                  children: [
                    if (settings.getIsInSelectedCue(verseId))
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 1.5, right: 3),
                          child: Icon(Icons.star, size: settings.fontSize),
                        ),
                      ),
                    // Display verse number (everything before and including
                    // the first dot) in bold.
                    TextSpan(
                      text: '${song['texts'][verseIndex].split('.')[0]}.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Display rest of verse text normally (split at dots,
                    // skip the first slice, join the rest).
                    TextSpan(
                      text: song['texts'][verseIndex]
                          .split('.')
                          .skip(1)
                          .join('.'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Only display the poet (if exists) below the last verse, and only do
      // it for the black (48) book.
      if (book == Book.black &&
          verseIndex == song['texts'].length - 1 &&
          song['poet'] is String) {
        page.add(Text(song['poet'], textAlign: TextAlign.right));
      }

      // When all verses should have scores displayed, every verse should have
      // its own page, and a new page should start (for the next verse, if
      // any).
      if (settings.scoreDisplay == ScoreDisplay.all || state.inCue) {
        pages.add(page);
        page = <Widget>[];
      }
    }
    // When NOT all verses should have scores displayed, the single page that
    // has been built so far should definitely be displayed.
    if (!(settings.scoreDisplay == ScoreDisplay.all || state.inCue)) {
      pages.add(page);
    }
  }

  return pages;
}

int getNumOfPages(Book book, String songKey, BuildContext context, bool inCue) {
  // When all verses should have scores displayed, every verse should have
  // its own page.
  if (Provider.of<SettingsProvider>(context, listen: false).scoreDisplay == ScoreDisplay.all ||
      inCue) {
    if (songBooks[book.name][songKey]['markdown'] != null) return 1;
    return songBooks[book.name][songKey]['texts'].length;
  }
  // When not all verses should have scores displayed, the song consists of
  // one single page.
  return 1;
}
