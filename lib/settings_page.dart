import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'settings_provider.dart';

class MySettingsPage extends StatefulWidget {
  const MySettingsPage({Key? key, required this.settingsProvider})
      : super(key: key);

  final SettingsProvider settingsProvider;

  @override
  State<MySettingsPage> createState() => _MySettingsPageState();
}

class _MySettingsPageState extends State<MySettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beállítások'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsSectionTitle('Énekeskönyv'),
              Platform.isIOS
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CupertinoSlidingSegmentedControl<Book>(
                        children: <Book, Widget>{
                          Book.black: Text(getBookName(Book.black)),
                          Book.blue: Text(getBookName(Book.blue))
                        },
                        groupValue: widget.settingsProvider.book,
                        onValueChanged: (Book? value) {
                          setState(() {
                            widget.settingsProvider.changeBook(
                                value ?? SettingsProvider.defaultBook);
                          });
                        },
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RadioListTile<Book>(
                          title: Text(getBookName(Book.black)),
                          value: Book.black,
                          groupValue: widget.settingsProvider.book,
                          onChanged: (Book? value) {
                            setState(() {
                              widget.settingsProvider.changeBook(
                                  value ?? SettingsProvider.defaultBook);
                            });
                          },
                        ),
                        RadioListTile<Book>(
                          title: Text(getBookName(Book.blue)),
                          value: Book.blue,
                          groupValue: widget.settingsProvider.book,
                          onChanged: (Book? value) {
                            setState(() {
                              widget.settingsProvider.changeBook(
                                  value ?? SettingsProvider.defaultBook);
                            });
                          },
                        ),
                      ],
                    ),
              const SettingsSectionTitle('Kotta'),
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
                        groupValue: widget.settingsProvider.scoreDisplay,
                        onValueChanged: (ScoreDisplay? value) {
                          setState(() {
                            widget.settingsProvider.changeScoreDisplay(
                                value ?? SettingsProvider.defaultScoreDisplay);
                          });
                        },
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RadioListTile<ScoreDisplay>(
                          title: Text(getScoreDisplayName(ScoreDisplay.all)),
                          value: ScoreDisplay.all,
                          groupValue: widget.settingsProvider.scoreDisplay,
                          onChanged: (ScoreDisplay? value) {
                            setState(() {
                              widget.settingsProvider.changeScoreDisplay(
                                  value ??
                                      SettingsProvider.defaultScoreDisplay);
                            });
                          },
                        ),
                        RadioListTile<ScoreDisplay>(
                          title: Text(getScoreDisplayName(ScoreDisplay.first)),
                          value: ScoreDisplay.first,
                          groupValue: widget.settingsProvider.scoreDisplay,
                          onChanged: (ScoreDisplay? value) {
                            setState(() {
                              widget.settingsProvider.changeScoreDisplay(
                                  value ??
                                      SettingsProvider.defaultScoreDisplay);
                            });
                          },
                        ),
                        RadioListTile<ScoreDisplay>(
                          title: Text(getScoreDisplayName(ScoreDisplay.none)),
                          value: ScoreDisplay.none,
                          groupValue: widget.settingsProvider.scoreDisplay,
                          onChanged: (ScoreDisplay? value) {
                            setState(() {
                              widget.settingsProvider.changeScoreDisplay(
                                  value ??
                                      SettingsProvider.defaultScoreDisplay);
                            });
                          },
                        ),
                      ],
                    ),
              const SettingsSectionTitle('Színek'),
              ListTile(
                title: const Text('Alkalmazás témája'),
                trailing: DropdownButton<ThemeMode>(
                  value: widget.settingsProvider.appThemeMode,
                  items: ThemeMode.values
                      .map((brightnessSetting) => DropdownMenuItem(
                            value: brightnessSetting,
                            child: Text(getThemeModeName(brightnessSetting)),
                          ))
                      .toList(),
                  onChanged: ((value) {
                    setState(() {
                      widget.settingsProvider.changeAppBrightnessSetting(
                          value ?? SettingsProvider.defaultAppThemeMode);
                    });
                  }),
                ),
              ),
              ListTile(
                title: const Text('Kotta témája'),
                trailing: DropdownButton<ThemeMode>(
                  value: widget.settingsProvider.sheetThemeMode,
                  items: ThemeMode.values
                      .map((brightnessSetting) => DropdownMenuItem(
                            value: brightnessSetting,
                            child: Text(getThemeModeName(brightnessSetting)),
                          ))
                      .toList(),
                  onChanged: ((value) {
                    setState(() {
                      widget.settingsProvider.changeSheetBrightnessSetting(
                          value ?? SettingsProvider.defaultSheetThemeMode);
                    });
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  final String title;

  const SettingsSectionTitle(
    this.title, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 18, left: 15, bottom: 5),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
