import 'dart:io';

import 'package:flutter/cupertino.dart';
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
                    groupValue: widget.provider.book,
                    onValueChanged: (Book? value) {
                      setState(() {
                        widget.provider
                            .changeBook(value ?? BookProvider.defaultBook);
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
                      groupValue: widget.provider.book,
                      onChanged: (Book? value) {
                        setState(() {
                          widget.provider
                              .changeBook(value ?? BookProvider.defaultBook);
                        });
                      },
                    ),
                    RadioListTile<Book>(
                      title: Text(getBookName(Book.blue)),
                      value: Book.blue,
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
