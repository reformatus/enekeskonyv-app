// @see https://docs.flutter.dev/cookbook/forms/validation
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings_provider.dart';
import 'song/song_page.dart';

class MyGotoSongForm extends StatefulWidget {
  const MyGotoSongForm({
    Key? key,
    required this.book,
    required this.settingsProvider,
  }) : super(key: key);

  final Book book;
  final SettingsProvider settingsProvider;

  @override
  State<MyGotoSongForm> createState() => _MyGotoSongFormState();
}

// @see https://docs.flutter.dev/cookbook/forms/validation
class _MyGotoSongFormState extends State<MyGotoSongForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController controller;

  // @see https://stackoverflow.com/q/63492002
  final _myFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ugrás énekre'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                      child: PlatformAwareTextFormField(
                        labelText: 'Ének száma:',
                        helperText:
                            '(1 és ${songBooks[widget.book.name].keys.last} között)',
                        focusNode: _myFocusNode,
                        controller: controller,
                        onFieldSubmitted: _onFieldSubmitted,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Írj be egy számot!';
                          }
                          if (!songBooks[widget.book.name].containsKey(value)) {
                            return 'Nincs ilyen ének.';
                          }
                          return null;
                        },
                        key: const Key('_MyCustomFormState.TextFormField'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (Platform.isIOS)
              Material(
                color: Theme.of(context).bottomAppBarTheme.color,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // TODO Add 'Next' button here for entering verse number.
                    SizedBox(
                      width: 100,
                      child: CupertinoDialogAction(
                          child: const Text('Ugrás'),
                          onPressed: () {
                            _onFieldSubmitted(controller.text);
                          }),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  _onFieldSubmitted(details) {
    // Validate returns true if the form is valid, or false
    // otherwise.
    if (_formKey.currentState!.validate()) {
      // If the form is valid, display the given song page.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return SongPage(
              book: widget.settingsProvider.book,
              // As we want to be able to turn page by page (ie. verse by
              // verse), we need to go to the Nth song in the book (from the
              // ListView the user sees). So we need to look up the index of the
              // song whose number was entered (eg. for the 2021 book, we need
              // the 198th song from the list when the user wants to navigate to
              // song #201).
              songIndex:
                  songBooks[widget.book.name].keys.toList().indexOf(details),
            );
          },
        ),
      );
      // Clear the TextFormField after returning from the song page.
      // @see https://stackoverflow.com/a/57747739
      controller.clear();
    }
    // Keep the TextFormField focused for both of these cases:
    // - If the form is invalid.
    // - When we're returning from the song page.
    _myFocusNode.requestFocus();
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
    return Platform.isIOS
        ? CupertinoTheme(
            data: CupertinoThemeData(
                brightness: SettingsProvider.of(context)
                    .getCurrentAppBrightness(context)),
            child: CupertinoTextFormFieldRow(
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
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextFormField(
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
            ),
          );
  }
}
