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

Widget _buildVerseText(
  BuildContext context,
  SettingsProvider settings,
  String verseId,
  String verseText,
) {
  return GestureDetector(
    onLongPress: settings.getIsInSelectedCue(verseId)
        ? () => settings.removeAllInstancesFromCue(settings.selectedCue, verseId)
        : () => settings.addToCue(settings.selectedCue, verseId),
    child: Padding(
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
            TextSpan(
              text: '${verseText.split('.')[0]}.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: verseText.split('.').skip(1).join('.')),
          ],
        ),
      ),
    ),
  );
}

List<List<Widget>> buildPages(
  Orientation orientation,
  Book book,
  String songKey,
  BuildContext context,
  bool isFullscreen,
) {
  var state = SongStateProvider.of(context);
  // Nested list; a page is just a list of widgets.
  final List<List<Widget>> pages = [];
  SettingsProvider settings = Provider.of<SettingsProvider>(
    context,
    listen: false,
  );

  var song = songBooks[book.name][songKey];
  final hasScore = songHasScore(book, songKey);
  final usesSingleScorePage = songUsesSingleScorePage(book, songKey);
  final splitPagesByVerse = shouldSplitPagesByVerse(
    scoreDisplay: settings.scoreDisplay,
    inCue: state.inCue,
    hasScore: hasScore,
    usesSingleScorePage: usesSingleScorePage,
  );

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
      if (shouldRenderScore(
        scoreDisplay: settings.scoreDisplay,
        inCue: state.inCue,
        verseIndex: verseIndex,
        hasScore: hasScore,
      )) {
        final supplementVerseText = shouldSupplementVerseTextForRepeatedScore(
          book,
          songKey,
          verseIndex,
        );
        Widget score = getScore(
          orientation,
          verseIndex,
          book,
          songKey,
          context,
          isFullscreen: isFullscreen,
        );

        // If song is displayed on single page, apply favourite functionality
        if (!splitPagesByVerse) {
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
          if (isFullscreen && !supplementVerseText) {
            page.add(Expanded(child: score));
          } else {
            page.add(score);
          }
          if (supplementVerseText) {
            page.add(
              _buildVerseText(
                context,
                settings,
                verseId,
                song['texts'][verseIndex],
              ),
            );
          }
        }
      } else {
        page.add(
          _buildVerseText(
            context,
            settings,
            verseId,
            song['texts'][verseIndex],
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
      if (splitPagesByVerse) {
        pages.add(page);
        page = <Widget>[];
      }
    }
    // When NOT all verses should have scores displayed, the single page that
    // has been built so far should definitely be displayed.
    if (!splitPagesByVerse) {
      pages.add(page);
    }
  }

  return pages;
}

int getNumOfPages(Book book, String songKey, BuildContext context, bool inCue) {
  final settings = Provider.of<SettingsProvider>(context, listen: false);
  final hasScore = songHasScore(book, songKey);
  final usesSingleScorePage = songUsesSingleScorePage(book, songKey);
  // When all verses should have scores displayed, every verse should have
  // its own page.
  if (shouldSplitPagesByVerse(
    scoreDisplay: settings.scoreDisplay,
    inCue: inCue,
    hasScore: hasScore,
    usesSingleScorePage: usesSingleScorePage,
  )) {
    if (songBooks[book.name][songKey]['markdown'] != null) return 1;
    return songBooks[book.name][songKey]['texts'].length;
  }
  // When not all verses should have scores displayed, the song consists of
  // one single page.
  return 1;
}
