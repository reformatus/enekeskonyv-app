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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Énekeskönyv',
      theme: ThemeData.dark(useMaterial3: true),
      home: ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider()..initialize(),
        child: const MyHomePage(),
      ),
    );
  }
}
