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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Énekeskönyv',
            style: TextStyle(
              fontSize: 20,
              height: 3,
            ),
            textAlign: TextAlign.center,
          ),
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
                        widget.settingsProvider
                            .changeBook(value ?? SettingsProvider.defaultBook);
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
        ],
      ),
    );
  }
}
