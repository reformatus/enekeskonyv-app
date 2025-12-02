import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../settings_provider.dart';
import 'song_page_state.dart';

List<Widget> getFirstVerseHeader(
  Book book,
  String songKey,
  BuildContext context,
) {
  final List<Widget> firstVerseHeader = [];
  switch (book) {
    // In case of the black book (48), the subtitle and the composer should
    // be displayed.
    case Book.black:
      if (songBooks[book.name][songKey]['subtitle'] is String) {
        firstVerseHeader.add(
          Text(
            songBooks[book.name][songKey]['subtitle'],
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
      if (songBooks[book.name][songKey]['composer'] is String) {
        firstVerseHeader.add(
          Text(
            songBooks[book.name][songKey]['composer'],
            textAlign: TextAlign.right,
          ),
        );
      }
      break;

    // In case of the blue book (21), all the metadata should be displayed.
    case Book.blue:
      if (songBooks[book.name][songKey]['subtitle'] is String) {
        firstVerseHeader.add(
          Text(
            songBooks[book.name][songKey]['subtitle'],
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
      firstVerseHeader.add(
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              if (songBooks[book.name][songKey]['poet'] is String) ...[
                const WidgetSpan(child: Icon(Icons.edit, size: 18)),
                TextSpan(text: ' ${songBooks[book.name][songKey]['poet']}  '),
              ],
              if (songBooks[book.name][songKey]['translator'] is String) ...[
                const WidgetSpan(child: Icon(Icons.translate, size: 18)),
                TextSpan(
                  text: ' ${songBooks[book.name][songKey]['translator']}  ',
                ),
              ],
              if (songBooks[book.name][songKey]['composer'] is String) ...[
                const WidgetSpan(child: Icon(Icons.music_note, size: 18)),
                TextSpan(
                  text: '${songBooks[book.name][songKey]['composer']}  ',
                ),
              ],
            ],
          ),
        ),
      );
      break;
  }
  return firstVerseHeader;
}

Widget getScore(
  Orientation orientation,
  int verseIndex,
  Book book,
  String songKey,
  BuildContext context, {
  bool isFullscreen = false,
}) {
  // The actual verse number is the number (well, any text) before the first
  // dot of the verse text.
  final verseNumber = songBooks[book.name][songKey]['texts'][verseIndex].split(
    '.',
  )[0];
  final fileName =
      // ignore: prefer_interpolation_to_compose_strings
      'assets/ref${book.name}/ref${book.name}-' +
      songKey.padLeft(3, '0') +
      // ignore: prefer_interpolation_to_compose_strings
      '-' +
      verseNumber.padLeft(3, '0') +
      '.svg';
  return SvgPicture.asset(
    fileName,
    // The score should utilize the full width of the screen, regardless its
    // size. This covers two cases:
    // - rotating the device,
    // - devices with different widths.
    width: isFullscreen
        ? (orientation == Orientation.portrait
              ? MediaQuery.of(context).size.width
              : null)
        : MediaQuery.of(context).size.width *
              ((orientation == Orientation.portrait) ? 1.0 : 0.7),
    colorFilter: ColorFilter.mode(
      Theme.of(context).textTheme.titleSmall!.color!,
      BlendMode.srcIn,
    ),
  );
}

void onTapUp(
  TapUpDetails details,
  BuildContext context,
  Offset tapDownPosition,
  TickerProvider vsync,
  VoidCallback onToggleFullscreen,
) {
  final settings = Provider.of<SettingsProvider>(context, listen: false);

  // Bail out early if tap ended more than 3.0 away from where it started.
  if ((details.globalPosition - tapDownPosition).distance > 3.0) return;

  final width = MediaQuery.of(context).size.width;
  final dx = details.globalPosition.dx;
  final isLeftThird = dx < width / 3;
  final isRightThird = dx > 2 * width / 3;
  final isMiddleThird = !isLeftThird && !isRightThird;

  // Always allow toggling fullscreen from the middle third.
  if (isMiddleThird) {
    onToggleFullscreen();
    return;
  }

  // When tap navigation is disabled, use any tap for fullscreen toggling.
  if (!settings.tapNavigation) {
    onToggleFullscreen();
    return;
  }

  final state = SongStateProvider.of(context);

  if (isLeftThird) {
    // Left third: Backward
    if (state.inCue) {
      if (state.cueElementExists(settings, next: false)) {
        state.advanceCue(context, settings, vsync, backward: true);
      }
    } else {
      state.switchVerse(
        next: false,
        settingsProvider: Provider.of<SettingsProvider>(context, listen: false),
        context: context,
        vsync: vsync,
      );
    }
  } else if (isRightThird) {
    // Right third: Forward
    if (state.inCue) {
      if (state.cueElementExists(settings, next: true)) {
        state.advanceCue(context, settings, vsync);
      }
    } else {
      state.switchVerse(
        next: true,
        settingsProvider: Provider.of<SettingsProvider>(context, listen: false),
        context: context,
        vsync: vsync,
      );
    }
  }
}
