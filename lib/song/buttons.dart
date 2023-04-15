import 'package:enekeskonyv/settings_provider.dart';
import 'package:enekeskonyv/song/state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../quick_settings_dialog.dart';
import 'text_icon_button.dart';

class ButtonBar extends StatelessWidget {
  const ButtonBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, SongStateProvider>(
        builder: (context, settings, state, child) {
      return Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: settings.getCurrentSheetBrightness(context),
        ),
        child: Builder(
          builder: (BuildContext context) {
            return Material(
              color: Theme.of(context).cardColor,
              child: Flex(
                direction: state.orientation == Orientation.portrait
                    ? Axis.horizontal
                    : Axis.vertical,
                // Make the buttons "justified" (ie. use all the
                // screen width).
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: controllerButtons(settings, state, context),
              ),
            );
          },
        ),
      );
    });
  }

  List<Widget> controllerButtons(SettingsProvider settings,
      SongStateProvider state, BuildContext context) {
    return [
      if (settings.scoreDisplay == ScoreDisplay.all)
        IconButton(
          onPressed:
              state.verseExists(next: false) ? null : () => state.switchVerse(next: false),
          icon: const Icon(Icons.arrow_circle_left_outlined),
          tooltip: 'Előző vers',
          disabledColor: ThemeData.dark().highlightColor,
        ),
      TextIconButton(
        text: state.songExists(next: false)
            ? null
            : songBooks[state.book.name].keys.elementAt(state.song - 1),
        onTap: state.songExists(next: false)
            ? null
            : () => state.switchSong(next: false),
        iconData: Icons.arrow_upward,
        tooltip: 'Előző ének',
        disabledColor: ThemeData.dark().highlightColor,
        alignment: Alignment.topRight,
        context: context,
      ),
      if (settings.scoreDisplay != ScoreDisplay.all)
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
      if (settings.scoreDisplay != ScoreDisplay.all)
        IconButton(
          onPressed: settings.fontSize > 10.0
              ? () => {settings.changeFontSize(settings.fontSize - 2.0)}
              : null,
          icon: const Icon(Icons.text_decrease),
          tooltip: 'Betűméret csökkentése',
          disabledColor: ThemeData.dark().highlightColor,
        ),
      TextIconButton(
        text: state.songExists(next: true)
            ? null
            : songBooks[state.book.name].keys.elementAt(state.song + 1),
        onTap: state.songExists(next: true)
            ? null
            : () => state.switchSong(next: true),
        iconData: Icons.arrow_downward,
        tooltip: 'Következő ének',
        disabledColor: ThemeData.dark().highlightColor,
        alignment: Alignment.topRight,
        context: context,
      ),
      if (settings.scoreDisplay == ScoreDisplay.all)
      IconButton(
        onPressed:
            state.verseExists(next: true)
                ? null
                : () => state.switchVerse(next: true),
        icon: const Icon(Icons.arrow_circle_right_outlined),
        tooltip: 'Következő vers',
        disabledColor: ThemeData.dark().highlightColor,
      ),
    ];
  }
}