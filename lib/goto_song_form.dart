// @see https://docs.flutter.dev/cookbook/forms/validation
import 'dart:collection';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'song_page.dart';

class MyGotoSongForm extends StatefulWidget {
  const MyGotoSongForm(
      {Key? key, required this.songs, required this.selectedBook})
      : super(key: key);

  final LinkedHashMap songs;
  final String selectedBook;

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
              PlatformAwareTextFormField(
                labelText: 'Ének száma:',
                helperText: '(1 és ${widget.songs.keys.last} között)',
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
                            // verse by verse), we need to go to the Nth song
                            // in the book (from the ListView the user sees).
                            // So we need to look up the index of the song
                            // whose number was entered (eg. for the 2021
                            // book, we need the 198th song from the list when
                            // the user wants to navigate to song #201).
                            songIndex:
                                widget.songs.keys.toList().indexOf(details),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Írj be egy számot!';
                  }
                  if (!widget.songs.containsKey(value)) {
                    return 'Nincs ilyen ének.';
                  }
                  return null;
                },
                key: const Key('_MyCustomFormState.TextFormField'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlatformAwareTextFormField extends StatelessWidget {
  final String labelText;
  final String helperText;
  final FocusNode focusNode;
  final TextEditingController controller;
  final void Function(String) onFieldSubmitted;
  final String? Function(String?)? validator;

  const PlatformAwareTextFormField(
      {required this.labelText,
      required this.helperText,
      required this.focusNode,
      required this.controller,
      required this.onFieldSubmitted,
      required this.validator,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid
        ? TextFormField(
            decoration: InputDecoration(
              labelText: labelText,
              helperText: helperText,
            ),
            focusNode: focusNode,
            controller: controller,
            onFieldSubmitted: onFieldSubmitted,
            validator: validator,
            autofocus: true,
            // @see https://stackoverflow.com/q/49577781
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          )
        : CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.dark),
            child: Column(
              children: [
                CupertinoTextFormFieldRow(
                  prefix: Text(labelText),
                  placeholder: helperText,
                  autofocus: true,
                  controller: controller,
                  // @see https://stackoverflow.com/q/49577781
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: validator,
                  onFieldSubmitted: onFieldSubmitted,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: CupertinoButton(
                    // Need a separate button on iOS; number keyboard does not
                    // have a Done button.
                    onPressed: () {
                      onFieldSubmitted(controller.text);
                    },
                    color: CupertinoTheme.of(context).barBackgroundColor,
                    child: Icon(
                      Icons.check,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  ),
                )
              ],
            ),
          );
  }
}
