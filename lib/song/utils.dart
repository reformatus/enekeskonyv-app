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

    // In case of the blue and Erdelyi books, all the metadata should be displayed.
    case Book.blue:
    case Book.erdelyi:
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

bool songHasScore(Book book, String songKey) {
  final song = songBooks[book.name][songKey];
  return song['hasScore'] != false;
}

bool songUsesSingleScorePage(Book book, String songKey) {
  final scoreFiles = songBooks[book.name][songKey]['scoreFiles'];
  if (scoreFiles is! List) return false;
  return scoreFiles.length == 1;
}

bool shouldRenderScore({
  required ScoreDisplay scoreDisplay,
  required bool inCue,
  required int verseIndex,
  required bool hasScore,
}) {
  if (!hasScore) return false;
  return inCue ||
      scoreDisplay == ScoreDisplay.all ||
      (scoreDisplay == ScoreDisplay.first && verseIndex == 0);
}

bool shouldSplitPagesByVerse({
  required ScoreDisplay scoreDisplay,
  required bool inCue,
  required bool hasScore,
  required bool usesSingleScorePage,
}) {
  // Cues always page by verse — a cue element targets a specific verse, and
  // a scoreless song still shows one text page per verse so the selected
  // verse is reached. Outside cues, verse paging exists to give each verse
  // its own score page, so it only applies in "all" mode when there is a
  // score to show.
  return inCue || (hasScore && scoreDisplay == ScoreDisplay.all);
}

bool shouldSupplementVerseTextForRepeatedScore(
  Book book,
  String songKey,
  int verseIndex,
) {
  return book == Book.erdelyi &&
      verseIndex > 0 &&
      songUsesSingleScorePage(book, songKey);
}

Widget getScore(
  Orientation orientation,
  int verseIndex,
  Book book,
  String songKey,
  BuildContext context, {
  bool isFullscreen = false,
}) {
  final fallbackText = songBooks[book.name][songKey]['texts'][verseIndex];
  final scoreCandidates = getScoreAssetCandidates(book, songKey, verseIndex);
  final mediaQuery = MediaQuery.of(context);
  final scoreWidth = isFullscreen
      ? (orientation == Orientation.portrait ? mediaQuery.size.width : null)
      : mediaQuery.size.width *
            ((orientation == Orientation.portrait) ? 1.0 : 0.7);
  return _buildScoreAsset(
    fileNames: scoreCandidates,
    width: scoreWidth,
    cacheWidth:
        ((scoreWidth ?? mediaQuery.size.width) * mediaQuery.devicePixelRatio)
            .round(),
    scoreColor: Theme.of(context).textTheme.titleSmall!.color!,
    fallbackText: fallbackText,
    context: context,
  );
}

List<String> getScoreAssetCandidates(
  Book book,
  String songKey,
  int verseIndex,
) {
  final song = songBooks[book.name][songKey];
  final scoreFiles = song['scoreFiles'];

  if (scoreFiles is List) {
    if (verseIndex < scoreFiles.length) {
      final fileName = scoreFiles[verseIndex];
      if (fileName is String && fileName.isNotEmpty) {
        return [fileName];
      }
    }
    if (book == Book.erdelyi && scoreFiles.length == 1) {
      final firstFile = scoreFiles.first;
      if (firstFile is String && firstFile.isNotEmpty) {
        return [firstFile];
      }
    }
    return [];
  }

  // The legacy books use the verse number in the text as the score page id.
  final verseNumber = song['texts'][verseIndex].split('.')[0];
  return [
    'assets/ref${book.name}/ref${book.name}-'
        '${songKey.padLeft(3, '0')}-'
        '${verseNumber.padLeft(3, '0')}.svg',
  ];
}

Widget _buildScoreAsset({
  required List<String> fileNames,
  required double? width,
  required int cacheWidth,
  required Color scoreColor,
  required String fallbackText,
  required BuildContext context,
  int index = 0,
}) {
  if (index >= fileNames.length) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(fallbackText, style: Theme.of(context).textTheme.bodyLarge),
    );
  }

  final fileName = fileNames[index];
  if (fileName.endsWith('.svg')) {
    return SvgPicture.asset(
      fileName,
      width: width,
      colorFilter: ColorFilter.mode(scoreColor, BlendMode.srcIn),
      errorBuilder: (context, error, stackTrace) => _buildScoreAsset(
        fileNames: fileNames,
        width: width,
        cacheWidth: cacheWidth,
        scoreColor: scoreColor,
        fallbackText: fallbackText,
        context: context,
        index: index + 1,
      ),
    );
  }

  return Image.asset(
    fileName,
    width: width,
    fit: BoxFit.contain,
    cacheWidth: cacheWidth,
    color: scoreColor,
    colorBlendMode: BlendMode.srcIn,
    errorBuilder: (context, error, stackTrace) => _buildScoreAsset(
      fileNames: fileNames,
      width: width,
      cacheWidth: cacheWidth,
      scoreColor: scoreColor,
      fallbackText: fallbackText,
      context: context,
      index: index + 1,
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
