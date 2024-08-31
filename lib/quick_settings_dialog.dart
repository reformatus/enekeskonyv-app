import 'dart:io';

import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mailto/mailto.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cues/link.dart';
import 'settings_provider.dart';
import 'song/song_page.dart';
import 'utils.dart';

class QuickSettingsDialog extends StatelessWidget {
  final Map? songData;
  final String? songKey;
  final Book? book;
  final int verseIndex;

  const QuickSettingsDialog(
      {super.key, this.songKey, this.songData, this.book, this.verseIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Dialog(
          backgroundColor: Theme.of(context).canvasColor,
          child: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                child: FadingEdgeScrollView.fromScrollView(
                  child: ListView(
                    controller: ScrollController(),
                    shrinkWrap: true,
                    children: [
                      if (songData != null &&
                          songData!['links'] != null &&
                          songData!['links'].isNotEmpty) ...[
                        const SettingsSectionTitle('Kapcsolódó'),
                        ...songData!['links'].map(
                          (e) => RelatedTile(
                            songLink: e['link']!,
                            relatedReason: e['text']!,
                            provider: settings,
                          ),
                        ),
                        const Divider(
                          endIndent: 70,
                          indent: 70,
                        ),
                      ],
                      const SettingsSectionTitle('Beállítások'),
                      const SettingsSectionTitle(
                        'Kotta',
                        subtitle: true,
                      ),
                      Platform.isIOS
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: CupertinoSlidingSegmentedControl<
                                  ScoreDisplay>(
                                children: <ScoreDisplay, Widget>{
                                  ScoreDisplay.all: Text(
                                      getScoreDisplayName(ScoreDisplay.all)),
                                  ScoreDisplay.first: Text(
                                      getScoreDisplayName(ScoreDisplay.first)),
                                  ScoreDisplay.none: Text(
                                      getScoreDisplayName(ScoreDisplay.none)),
                                },
                                groupValue: settings.scoreDisplay,
                                onValueChanged: (ScoreDisplay? value) {
                                  settings.changeScoreDisplay(value ??
                                      SettingsProvider.defaultScoreDisplay);
                                },
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                RadioListTile<ScoreDisplay>(
                                  title: Text(
                                      getScoreDisplayName(ScoreDisplay.all)),
                                  value: ScoreDisplay.all,
                                  groupValue: settings.scoreDisplay,
                                  onChanged: (ScoreDisplay? value) {
                                    settings.changeScoreDisplay(value ??
                                        SettingsProvider.defaultScoreDisplay);
                                  },
                                ),
                                RadioListTile<ScoreDisplay>(
                                  title: Text(
                                      getScoreDisplayName(ScoreDisplay.first)),
                                  value: ScoreDisplay.first,
                                  groupValue: settings.scoreDisplay,
                                  onChanged: (ScoreDisplay? value) {
                                    settings.changeScoreDisplay(value ??
                                        SettingsProvider.defaultScoreDisplay);
                                  },
                                ),
                                RadioListTile<ScoreDisplay>(
                                  title: Text(
                                      getScoreDisplayName(ScoreDisplay.none)),
                                  value: ScoreDisplay.none,
                                  groupValue: settings.scoreDisplay,
                                  onChanged: (ScoreDisplay? value) {
                                    settings.changeScoreDisplay(value ??
                                        SettingsProvider.defaultScoreDisplay);
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
                          value: settings.appThemeMode,
                          items: ThemeMode.values
                              .map((brightnessSetting) => DropdownMenuItem(
                                    value: brightnessSetting,
                                    child: Text(
                                        getThemeModeName(brightnessSetting)),
                                  ))
                              .toList(),
                          onChanged: ((value) {
                            settings.changeAppBrightnessSetting(
                                value ?? SettingsProvider.defaultAppThemeMode);
                          }),
                        ),
                      ),
                      ListTile(
                        title: const Text('Kotta témája'),
                        trailing: DropdownButton<ThemeMode>(
                          value: settings.sheetThemeMode,
                          items: ThemeMode.values
                              .map((brightnessSetting) => DropdownMenuItem(
                                    value: brightnessSetting,
                                    child: Text(
                                        getThemeModeName(brightnessSetting)),
                                  ))
                              .toList(),
                          onChanged: ((value) {
                            settings.changeSheetBrightnessSetting(value ??
                                SettingsProvider.defaultSheetThemeMode);
                          }),
                        ),
                      ),
                      if (settings.getCurrentAppBrightness(context) ==
                              Brightness.dark ||
                          settings.getCurrentSheetBrightness(context) ==
                              Brightness.dark)
                        ListTile(
                          title: const Text('Teljesen fekete háttér'),
                          trailing: Platform.isIOS
                              ? CupertinoSwitch(
                                  value: settings.isOledTheme,
                                  onChanged: (value) {
                                    settings.changeIsOledTheme(value);
                                  },
                                )
                              : Switch(
                                  value: settings.isOledTheme,
                                  onChanged: (value) {
                                    settings.changeIsOledTheme(value);
                                  },
                                ),
                        ),
                      const SettingsSectionTitle(
                        'Navigáció',
                        subtitle: true,
                      ),
                      ListTile(
                        title:
                            const Text('Versszak- és énekváltás koppintással'),
                        trailing: Platform.isIOS
                            ? CupertinoSwitch(
                                value: settings.tapNavigation,
                                onChanged: (value) {
                                  settings.changeTapNavigation(value);
                                },
                              )
                            : Switch(
                                value: settings.tapNavigation,
                                onChanged: (value) {
                                  settings.changeTapNavigation(value);
                                },
                              ),
                      ),
                      if (settings.scoreDisplay == ScoreDisplay.all)
                        ListTile(
                          title: const Text('Versszakválasztó sáv'),
                          trailing: Platform.isIOS
                              ? CupertinoSwitch(
                                  value: settings.isVerseBarEnabled,
                                  onChanged: (value) {
                                    settings.changeIsVerseBarEnabled(value);
                                  },
                                )
                              : Switch(
                                  value: settings.isVerseBarEnabled,
                                  onChanged: (value) {
                                    settings.changeIsVerseBarEnabled(value);
                                  },
                                ),
                        ),
                      const Divider(
                        endIndent: 70,
                        indent: 70,
                      ),
                      if (songData != null)
                        ElevatedButton.icon(
                          onPressed: () => showShareDialog(context,
                              '${songData?['number']} / ${verseIndex + 1}.',
                              verseId: getVerseId(book!, songKey!, verseIndex)),
                          icon: const Icon(Icons.share),
                          label: const Text('Megosztás'),
                        ),
                      ElevatedButton.icon(
                        onPressed: () {
                          launchUrl(Uri.parse(Mailto(
                            to: ['app@reflabs.hu'],
                            subject: songData != null
                                ? 'Hibajelentés ${settings.packageInfo.version}+${settings.packageInfo.buildNumber}: ${songData?['number']} / ${verseIndex + 1}. vers (${book?.name} könyv)'
                                : 'Hibajelentés ${settings.packageInfo.version}+${settings.packageInfo.buildNumber}',
                            body: '''
Kérlek, írd le a hibát: App, kotta, szöveghiba? Melyik sorban? Egyéb megjegyzés?
Csatolhatsz képet is.''',
                          ).toString()));

                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.flag_rounded),
                        label: const Text('Hibajelentés'),
                      ),
                      if (songData == null) ...[
                        const Divider(
                          endIndent: 70,
                          indent: 70,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            '''
Református Énekeskönyv (21/48)
verzió: ${settings.packageInfo.version}+${settings.packageInfo.buildNumber}
by RefLabs''',
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.secondary),
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          child: FadingEdgeScrollView.fromScrollView(
                            child: ListView(
                              controller: ScrollController(),
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.all(6),
                              children: [
                                const SizedBox(width: 5),
                                TextButton.icon(
                                  label: const Text('Forráskód'),
                                  onPressed: () => launchUrl(Uri.parse(
                                      'https://github.com/reformatus/enekeskonyv-app')),
                                  icon: const Icon(Icons.code),
                                ),
                                const SizedBox(width: 5),
                                TextButton.icon(
                                  label: const Text('Licenszek'),
                                  onPressed: () => showLicensePage(
                                      context: context,
                                      applicationName:
                                          'Református Énekeskönyv (21/48)',
                                      applicationVersion:
                                          '${settings.packageInfo.version}+${settings.packageInfo.buildNumber}'),
                                  icon: const Icon(Icons.gavel),
                                ),
                                TextButton.icon(
                                  label: const Text('Visszaállítás'),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Visszaállítás'),
                                      content: const Text(
                                          'Biztosan törölsz minden alkalmazásadatot? Ez a beállításokat és a listákat is törli!'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Mégse'),
                                        ),
                                        FilledButton(
                                          onPressed: () {
                                            settings.factoryReset().then((value) =>
                                                // ignore: use_build_context_synchronously
                                                Navigator.pop(context));
                                          },
                                          child: const Text('Végleges törlés!'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  icon: const Icon(Icons.replay_outlined,
                                      color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class RelatedTile extends StatelessWidget {
  const RelatedTile({
    required this.songLink,
    required this.relatedReason,
    required this.provider,
    super.key,
  });

  final String songLink;
  final String relatedReason;
  final SettingsProvider provider;

  @override
  Widget build(BuildContext context) {
    String songId = songLink.split('/').last;
    Book book = songLink.split('/').first == '21' ? Book.blue : Book.black;

    return ListTile(
      leading: Card(
          child: Padding(
        padding: const EdgeInsets.all(7),
        child: Text(
          songId,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      )),
      title: Text(relatedReason),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return SongPage(
              book: book,
              songIndex: songBooks[book.name].keys.toList().indexOf(songId),
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 5,
        left: 15,
        bottom: 5,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: subtitle ? FontWeight.bold : FontWeight.normal,
            fontSize: subtitle ? 18 : 21),
      ),
    );
  }
}
