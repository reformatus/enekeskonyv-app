import 'dart:io';

import 'package:enekeskonyv/settings_provider.dart';
import 'package:enekeskonyv/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'song_page.dart';

Widget quickSettingsDialog(BuildContext context, Map songData) =>
    Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        return Dialog(
          backgroundColor: Theme.of(context).canvasColor,
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 10),
              if (songData["links"].isNotEmpty)
                const SettingsSectionTitle('Kapcsolódó'),
              ...songData["links"].map(
                (e) => RelatedTile(
                  songLink: e["link"]!,
                  relatedReason: e["text"]!,
                  provider: provider,
                ),
              ),
              if (songData["links"].isNotEmpty)
                const Divider(endIndent: 70, indent: 70),
              const SettingsSectionTitle('Beállítások'),
              const SettingsSectionTitle('Kotta', subtitle: true),
              Platform.isIOS
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CupertinoSlidingSegmentedControl<ScoreDisplay>(
                        children: <ScoreDisplay, Widget>{
                          ScoreDisplay.all:
                              Text(getScoreDisplayName(ScoreDisplay.all)),
                          ScoreDisplay.first:
                              Text(getScoreDisplayName(ScoreDisplay.first)),
                          ScoreDisplay.none:
                              Text(getScoreDisplayName(ScoreDisplay.none)),
                        },
                        groupValue: provider.scoreDisplay,
                        onValueChanged: (ScoreDisplay? value) {
                          provider.changeScoreDisplay(
                              value ?? SettingsProvider.defaultScoreDisplay);
                        },
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RadioListTile<ScoreDisplay>(
                          title: Text(getScoreDisplayName(ScoreDisplay.all)),
                          value: ScoreDisplay.all,
                          groupValue: provider.scoreDisplay,
                          onChanged: (ScoreDisplay? value) {
                            provider.changeScoreDisplay(
                                value ?? SettingsProvider.defaultScoreDisplay);
                          },
                        ),
                        RadioListTile<ScoreDisplay>(
                          title: Text(getScoreDisplayName(ScoreDisplay.first)),
                          value: ScoreDisplay.first,
                          groupValue: provider.scoreDisplay,
                          onChanged: (ScoreDisplay? value) {
                            provider.changeScoreDisplay(
                                value ?? SettingsProvider.defaultScoreDisplay);
                          },
                        ),
                        RadioListTile<ScoreDisplay>(
                          title: Text(getScoreDisplayName(ScoreDisplay.none)),
                          value: ScoreDisplay.none,
                          groupValue: provider.scoreDisplay,
                          onChanged: (ScoreDisplay? value) {
                            provider.changeScoreDisplay(
                                value ?? SettingsProvider.defaultScoreDisplay);
                          },
                        ),
                      ],
                    ),
              const SettingsSectionTitle(
                'Színek',
                subtitle: true,
              ),
              ListTile(
                title: const Text('Alkalmazás témája'),
                trailing: DropdownButton<ThemeMode>(
                  value: provider.appThemeMode,
                  items: ThemeMode.values
                      .map((brightnessSetting) => DropdownMenuItem(
                            value: brightnessSetting,
                            child: Text(getThemeModeName(brightnessSetting)),
                          ))
                      .toList(),
                  onChanged: ((value) {
                    provider.changeAppBrightnessSetting(
                        value ?? SettingsProvider.defaultAppThemeMode);
                  }),
                ),
              ),
              ListTile(
                title: const Text('Kotta témája'),
                trailing: DropdownButton<ThemeMode>(
                  value: provider.sheetThemeMode,
                  items: ThemeMode.values
                      .map((brightnessSetting) => DropdownMenuItem(
                            value: brightnessSetting,
                            child: Text(getThemeModeName(brightnessSetting)),
                          ))
                      .toList(),
                  onChanged: ((value) {
                    provider.changeSheetBrightnessSetting(
                        value ?? SettingsProvider.defaultSheetThemeMode);
                  }),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

class RelatedTile extends StatelessWidget {
  const RelatedTile({
    required this.songLink,
    required this.relatedReason,
    required this.provider,
    Key? key,
  }) : super(key: key);

  final String songLink;
  final String relatedReason;
  final SettingsProvider provider;

  @override
  Widget build(BuildContext context) {
    String songId = songLink.split("/").last;
    Book book = songLink.split("/").first == '21' ? Book.blue : Book.black;

    return ListTile(
      leading: Card(
          child: Padding(
        padding: const EdgeInsets.all(7),
        child: Text(
          songId,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      )),
      title: Text(relatedReason),
      onTap: () async {
        // HACK - needs refactor
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) {
            provider.changeBook(book);
            return MySongPage(
              songsInBook: globalSongs[provider.bookAsString],
              settingsProvider: provider,
              songIndex: globalSongs[provider.bookAsString]
                  .keys
                  .toList()
                  .indexOf(songId),
            );
          },
        ));
      },
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  final String title;
  final bool subtitle;
  const SettingsSectionTitle(
    this.title, {
    this.subtitle = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 5, left: 15, bottom: 5),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: subtitle ? FontWeight.bold : FontWeight.normal,
            fontSize: subtitle ? 17 : 23),
      ),
    );
  }
}
