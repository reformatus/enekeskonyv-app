import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../settings_provider.dart';
import 'song_page_state.dart';

List<Widget> getFirstVerseHeader(Book book, String songKey) {
  final List<Widget> firstVerseHeader = [];
  switch (book) {
    // In case of the black book (48), the subtitle and the composer should
    // be displayed.
    case Book.black:
      if (songBooks[book.name][songKey]['subtitle'] is String) {
        firstVerseHeader.add(Text(
          songBooks[book.name][songKey]['subtitle'],
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }
      if (songBooks[book.name][songKey]['composer'] is String) {
        firstVerseHeader.add(Text(
          songBooks[book.name][songKey]['composer'],
          textAlign: TextAlign.right,
        ));
      }
      break;

    // In case of the blue book (21), all the metadata should be displayed.
    case Book.blue:
      if (songBooks[book.name][songKey]['subtitle'] is String) {
        firstVerseHeader.add(Text(
          songBooks[book.name][songKey]['subtitle'],
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }
      firstVerseHeader.add(
        Wrap(
          children: [
            if (songBooks[book.name][songKey]['poet'] is String) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, size: 18),
                  Text('${songBooks[book.name][songKey]['poet']}'),
                  const SizedBox(width: 10)
                ],
              )
            ],
            if (songBooks[book.name][songKey]['translator'] is String) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate, size: 18),
                  Text('${songBooks[book.name][songKey]['translator']}'),
                  const SizedBox(width: 10)
                ],
              )
            ],
            if (songBooks[book.name][songKey]['composer'] is String) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note, size: 18),
                  Text('${songBooks[book.name][songKey]['composer']}'),
                ],
              )
            ],
          ],
        ),
      );
      break;
  }
  return firstVerseHeader;
}

Widget getScore(Orientation orientation, int verseIndex, Book book,
    String songKey, BuildContext context) {
  // The actual verse number is the number (well, any text) before the first
  // dot of the verse text.
  final verseNumber =
      songBooks[book.name][songKey]['texts'][verseIndex].split('.')[0];
  final fileName =
      // ignore: prefer_interpolation_to_compose_strings
      'assets/ref${book.name}/ref${book.name}-' +
          songKey.padLeft(3, '0') +
          '-' +
          verseNumber.padLeft(3, '0') +
          '.svg';
  return SvgPicture.asset(
    fileName,
    // The score should utilize the full width of the screen, regardless its
    // size. This covers two cases:
    // - rotating the device,
    // - devices with different widths.
    width: MediaQuery.of(context).size.width *
        ((orientation == Orientation.portrait) ? 1.0 : 0.7),
    color: Theme.of(context).textTheme.titleSmall!.color,
  );
}

void onTapUp(TapUpDetails details, BuildContext context, Offset tapDownPosition,
    TickerProvider vsync) {
  // Only do anything if tap navigation is enabled.
  if (!SettingsProvider.of(context).tapNavigation) return;

  // Bail out early if tap ended more than 3.0 away from where it started.
  if ((details.globalPosition - tapDownPosition).distance > 3.0) return;

  if ((MediaQuery.of(context).size.width / 2) > details.globalPosition.dx) {
    // Go backward (to the previous verse).
    SongStateProvider.of(context).switchVerse(
        next: false,
        settingsProvider: SettingsProvider.of(context),
        context: context,
        vsync: vsync);
  } else {
    // Go forward (to the next verse).
    SongStateProvider.of(context).switchVerse(
        next: true,
        settingsProvider: SettingsProvider.of(context),
        context: context,
        vsync: vsync);
  }
}
