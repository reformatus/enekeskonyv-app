import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'book_provider.dart';
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
      home: ChangeNotifierProvider<BookProvider>(
        create: (_) => BookProvider()..initialize(),
        child: const MyHomePage(),
      ),
    );
  }
}
