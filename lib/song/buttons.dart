import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../quick_settings_dialog.dart';
import '../settings_provider.dart';
import 'song_page_state.dart';
import 'text_icon_button.dart';

class ControllerButtons extends StatelessWidget {
  final Orientation orientation;
  final TickerProvider vsync;
  const ControllerButtons(
      {Key? key, required this.orientation, required this.vsync})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, SongStateProvider>(
        builder: (context, settings, state, child) {
      return Theme(
        data: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: state.book == Book.black ? Colors.amber : Colors.blue,
              brightness: settings.getCurrentSheetBrightness(context),
              background: settings.isOledTheme &&
                      settings.getCurrentSheetBrightness(context) ==
                          Brightness.dark
                  ? Colors.black
                  : null),
        ),
        child: Builder(
          builder: (BuildContext context) {
            return Material(
              color: Theme.of(context).colorScheme.background,
              child: Flex(
                direction: orientation == Orientation.portrait
                    ? Axis.vertical
                    : Axis.horizontal,
                children: [
                  Flex(
                    direction: orientation == Orientation.portrait
                        ? Axis.horizontal
                        : Axis.vertical,
                    // Make the buttons "justified" (ie. use all the
                    // screen width).
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        controllerButtons(settings, state, context, vsync),
                  ),
                  if (state.inCue) cueButtons(context, state, settings),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Card cueButtons(BuildContext context, SongStateProvider state,
      SettingsProvider settings) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: const StadiumBorder(),
      child: Flex(
        direction: orientation == Orientation.portrait
            ? Axis.horizontal
            : Axis.vertical,
        // Make the buttons "justified" (ie. use all the
        // screen width).
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (state.cueIndex! > 0)
            IconButton.filled(
                onPressed: () => state.changeToVerseIdInCue(
                    settings.cueStore[settings.selectedCue]
                        [state.cueIndex! - 1],
                    state.cueIndex! - 1,
                    context,
                    vsync),
                icon: const Icon(Icons.keyboard_double_arrow_left)),
          Expanded(
            child: RotatedBox(
              quarterTurns: orientation == Orientation.portrait ? 0 : 1,
              child: Row(
                children: [
                  if (state.cueIndex! > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: cueVerseLinkText(
                          settings.cueStore[settings.selectedCue]
                              [state.cueIndex! - 1],
                          state),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Kedvencek',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (state.cueIndex! <
                      settings.cueStore[settings.selectedCue].length - 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: cueVerseLinkText(
                          settings.cueStore[settings.selectedCue]
                              [state.cueIndex! + 1],
                          state),
                    ),
                ],
              ),
            ),
          ),
          if (state.cueIndex! <
              settings.cueStore[settings.selectedCue].length - 1)
            IconButton.filled(
                onPressed: () => state.changeToVerseIdInCue(
                    settings.cueStore[settings.selectedCue]
                        [state.cueIndex! + 1],
                    state.cueIndex! + 1,
                    context,
                    vsync),
                icon: const Icon(Icons.keyboard_double_arrow_right)),
        ],
      ),
    );
  }

  Widget cueVerseLinkText(String verseId, SongStateProvider state) {
    var parts = verseId.split('/');
    var book = parts[0];
    var songKey = parts[1];
    var verseIndex = int.parse(parts[2]);

    List<String> toDisplay = [
      if (state.book.name != book) '($book)',
      '$songKey/${songBooks[book][songKey]['texts'][verseIndex].split('.')[0]}'
    ];
    return Text(toDisplay.join(' '));
  }

  List<Widget> controllerButtons(SettingsProvider settings,
      SongStateProvider state, BuildContext context, TickerProvider vsync) {
    return [
      if (settings.scoreDisplay == ScoreDisplay.all || state.inCue)
        IconButton(
          key: const Key('_MySongPageState.IconButton.prevVerse'),
          onPressed: state.verseExists(next: false)
              ? () => state.switchVerse(
                  next: false,
                  settingsProvider: settings,
                  context: context,
                  vsync: vsync)
              : null,
          icon: const Icon(Icons.arrow_circle_left_outlined),
          tooltip: 'Előző vers',
          disabledColor: ThemeData.dark().highlightColor,
        ),
      TextIconButton(
        key: const Key('_MySongPageState.IconButton.prevSong'),
        text: state.songExists(next: false)
            ? songBooks[state.book.name].keys.elementAt(state.song - 1)
            : null,
        onTap: state.songExists(next: false)
            ? () =>
                state.switchSong(next: false, context: context, vsync: vsync)
            : null,
        iconData: Icons.arrow_upward,
        tooltip: 'Előző ének',
        disabledColor: ThemeData.dark().highlightColor,
        alignment: Alignment.bottomRight,
        context: context,
      ),
      if (!(settings.scoreDisplay == ScoreDisplay.all || state.inCue))
        IconButton(
          onPressed: settings.fontSize < 40.0
              ? () => settings.changeFontSize(settings.fontSize + 2.0)
              : null,
          icon: const Icon(Icons.text_increase),
          tooltip: 'Betűméret növelése',
          disabledColor: ThemeData.dark().highlightColor,
        ),
      IconButton(
        icon: const Icon(Icons.menu),
        tooltip: 'Gyorsmenü',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => QuickSettingsDialog(
              songData: songBooks[state.book.name][state.songKey],
              book: state.book,
              verseNumber: state.verse,
            ),
          );
        },
      ),
      if (!(settings.scoreDisplay == ScoreDisplay.all || state.inCue))
        IconButton(
          onPressed: settings.fontSize > 10.0
              ? () => {settings.changeFontSize(settings.fontSize - 2.0)}
              : null,
          icon: const Icon(Icons.text_decrease),
          tooltip: 'Betűméret csökkentése',
          disabledColor: ThemeData.dark().highlightColor,
        ),
      TextIconButton(
        key: const Key('_MySongPageState.IconButton.nextSong'),
        text: state.songExists(next: true)
            ? songBooks[state.book.name].keys.elementAt(state.song + 1)
            : null,
        onTap: state.songExists(next: true)
            ? () => state.switchSong(next: true, context: context, vsync: vsync)
            : null,
        iconData: Icons.arrow_downward,
        tooltip: 'Következő ének',
        disabledColor: ThemeData.dark().highlightColor,
        alignment: Alignment.topRight,
        context: context,
      ),
      if (settings.scoreDisplay == ScoreDisplay.all || state.inCue)
        IconButton(
          key: const Key('_MySongPageState.IconButton.nextVerse'),
          onPressed: state.verseExists(next: true)
              ? () => state.switchVerse(
                  next: true,
                  settingsProvider: settings,
                  context: context,
                  vsync: vsync)
              : null,
          icon: const Icon(Icons.arrow_circle_right_outlined),
          tooltip: 'Következő vers',
          disabledColor: ThemeData.dark().highlightColor,
        ),
    ];
  }
}
