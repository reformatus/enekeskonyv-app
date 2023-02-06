import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget quickSettingsDialog(BuildContext context) => Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
        );
      },
    );
