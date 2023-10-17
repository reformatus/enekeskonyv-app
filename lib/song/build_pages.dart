// Builds the pages for the current song's verses.
import 'package:flutter/material.dart';

import '../settings_provider.dart';
import 'utils.dart';

List<List<Widget>> buildPages(
    Orientation orientation, Book book, String songKey, BuildContext context) {
  // Nested list; a page is just a list of widgets.
  final List<List<Widget>> pages = [];
  SettingsProvider settings = SettingsProvider.of(context);
  // Collects the list items for the current page. When not all verses
  // should have scores displayed, the song consists of one single page.
  var page = <Widget>[];
  for (var verseIndex = 0;
      verseIndex < songBooks[book.name][songKey]['texts'].length;
      verseIndex++) {
    // Only display certain info above the first verse.
    if (verseIndex == 0) {
      page.addAll(getFirstVerseHeader(book, songKey, context));
    }

    // Add either the score or the text of the current verse, as needed.
    if (settings.scoreDisplay == ScoreDisplay.all ||
        (settings.scoreDisplay == ScoreDisplay.first &&
            verseIndex == 0)) {
      page.add(getScore(orientation, verseIndex, book, songKey, context));
    } else {
      page.add(
        Padding(
          // Add space between verses.
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontSize: settings.fontSize,
              ),
              children: [
                // Display verse number (everything before and including
                // the first dot) in bold.
                TextSpan(
                  text:
                      '${songBooks[book.name][songKey]['texts'][verseIndex].split('.')[0]}.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // Display rest of verse text normally (split at dots,
                // skip the first slice, join the rest).
                TextSpan(
                  text: songBooks[book.name][songKey]['texts'][verseIndex]
                      .split('.')
                      .skip(1)
                      .join('.'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Only display the poet (if exists) below the last verse, and only do
    // it for the black (48) book.
    if (book == Book.black &&
        verseIndex == songBooks[book.name][songKey]['texts'].length - 1 &&
        songBooks[book.name][songKey]['poet'] is String) {
      page.add(Text(
        songBooks[book.name][songKey]['poet'],
        textAlign: TextAlign.right,
      ));
    }

    // When all verses should have scores displayed, every verse should have
    // its own page, and a new page should start (for the next verse, if
    // any).
    if (settings.scoreDisplay == ScoreDisplay.all) {
      pages.add(page);
      page = <Widget>[];
    }
  }
  // When NOT all verses should have scores displayed, the single page that
  // has been built so far should definitely be displayed.
  if (settings.scoreDisplay != ScoreDisplay.all) {
    pages.add(page);
  }
  return pages;
}

int getNumOfPages(Book book, String songKey, BuildContext context) {
  SettingsProvider settingsProvider = SettingsProvider.of(context);
  // When all verses should have scores displayed, every verse should have
  // its own page.
  if (settingsProvider.scoreDisplay == ScoreDisplay.all) {
    return songBooks[book.name][songKey]['texts'].length;
  }
  // When not all verses should have scores displayed, the song consists of
  // one single page.
  return 1;
}
