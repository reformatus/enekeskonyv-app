// @see https://docs.flutter.dev/cookbook/forms/validation
import 'dart:collection';

import 'package:enekeskonyv/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'song_page.dart';

class MyGotoSongForm extends StatefulWidget {
  const MyGotoSongForm({Key? key, required this.songs, required this.selectedBook}) : super(key: key);

  final LinkedHashMap songs;
  final Book selectedBook;

  @override
  State<MyGotoSongForm> createState() => _MyGotoSongFormState();
}

// @see https://docs.flutter.dev/cookbook/forms/validation
class _MyGotoSongFormState extends State<MyGotoSongForm> {
  final _formKey = GlobalKey<FormState>();
  // @see https://stackoverflow.com/q/63492002
  final _myFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    var controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ugrás énekre'),
      ),
      body: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Ének száma:',
                    helperText: '(1 és ${widget.songs.keys.last} között)',
                  ),
                  autofocus: true,
                  focusNode: _myFocusNode,
                  controller: controller,
                  onFieldSubmitted: (details) {
                    // Validate returns true if the form is valid, or false
                    // otherwise.
                    if (_formKey.currentState!.validate()) {
                      // If the form is valid, display the given song page.
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return MySongPage(
                              songsInBook: widget.songs,
                              selectedBook: widget.selectedBook,
                              // As we want to be able to turn page by page (ie.
                              // verse by verse), we need to go to the Nth song in
                              // the book (from the ListView the user sees). So we
                              // need to look up the index of the song whose
                              // number was entered (eg. for the 2021 book, we
                              // need the 198th song from the list when the user
                              // wants to navigate to song #201).
                              songIndex: widget.songs.keys.toList().indexOf(details),
                            );
                          },
                        ),
                      );
                      // Clear the TextFormField after returning from the song
                      // page.
                      // @see https://stackoverflow.com/a/57747739
                      controller.clear();
                    }
                    // Keep the TextFormField focused for both of these cases:
                    // - If the form is invalid.
                    // - When we're returning from the song page.
                    _myFocusNode.requestFocus();
                  },
                  // @see https://stackoverflow.com/q/49577781
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Hiányzó adat';
                    }
                    if (!widget.songs.containsKey(value)) {
                      return 'Hibás adat';
                    }
                    return null;
                  },
                  key: const Key('_MyCustomFormState.TextFormField')
              ),
            ],
          ),
        ),
      ),
    );
  }
}
