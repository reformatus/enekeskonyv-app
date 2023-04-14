import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_provider.dart';
import 'home_page.dart';

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
      child: Consumer<SettingsProvider>(builder: (context, provider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Énekeskönyv',
          themeMode: provider.appThemeMode,
          theme: ThemeData(useMaterial3: true),
          darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: const HomePage(),
        );
      }),
    );
  }
}
