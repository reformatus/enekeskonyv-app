import 'package:enekeskonyv/util.dart';
import 'package:flutter/material.dart';

import 'book_provider.dart';

class MySettingsPage extends StatefulWidget {
  const MySettingsPage({Key? key, required this.provider}) : super(key: key);

  final BookProvider provider;

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
      body: Column(
        children: [
          const Text(
            'Énekeskönyv',
            style: TextStyle(
              fontSize: 20,
              height: 2,
            ),
          ),
          Column(
            children: [
              RadioListTile<Book>(
                title: const Text('48-as énekeskönyv (fekete)'),
                value: Book.fekete,
                groupValue: widget.provider.book,
                onChanged: (Book? value) {
                  setState(() {
                    widget.provider
                        .changeBook(value ?? BookProvider.defaultBook);
                  });
                },
              ),
              RadioListTile<Book>(
                title: const Text('21-es énekeskönyv (kék)'),
                value: Book.kek,
                groupValue: widget.provider.book,
                onChanged: (Book? value) {
                  setState(() {
                    widget.provider
                        .changeBook(value ?? BookProvider.defaultBook);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
