import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_page.dart';
import 'settings_provider.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsProvider>(
      create: (_) => SettingsProvider()..initialize(),
      child: Consumer<SettingsProvider>(builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Énekeskönyv',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
                seedColor:
                    settings.book == Book.black ? Colors.amber : Colors.blue,
                brightness: settings.getCurrentAppBrightness(context),
                background: settings.isOledTheme &&
                        settings.getCurrentAppBrightness(context) ==
                            Brightness.dark
                    ? Colors.black
                    : null),
          ),
          home: const HomePage(),
        );
      }),
    );
  }
}
