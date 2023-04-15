import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../settings_provider.dart';

List<Widget> getFirstVerseHeader(Book book, String songKey) {
  final List<Widget> firstVerseHeader = [];
  switch (book) {
    // In case of the black book (48), the subtitle and the composer should
    // be displayed.
    case Book.black:
      if (songBooks[book.name][songKey]['subtitle'] is String) {
        firstVerseHeader.add(Text(songBooks[book.name][songKey]['subtitle']));
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
    default:
      final List<String> metadata = [];
      if (songBooks[book.name][songKey]['subtitle'] is String) {
        metadata.add(songBooks[book.name][songKey]['subtitle']);
      }
      if (songBooks[book.name][songKey]['poet'] is String) {
        metadata.add('sz: ${songBooks[book.name][songKey]['poet']}');
      }
      if (songBooks[book.name][songKey]['translator'] is String) {
        metadata.add('f: ${songBooks[book.name][songKey]['translator']}');
      }
      if (songBooks[book.name][songKey]['composer'] is String) {
        metadata.add('d: ${songBooks[book.name][songKey]['composer']}');
      }
      if (metadata.isNotEmpty) {
        firstVerseHeader.add(Text(metadata.join(' | ')));
      }
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