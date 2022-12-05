import 'package:enekeskonyv/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('End-to-end test', (WidgetTester tester) async {
    app.main();
    // As the whole app is about the songs that are to be loaded from an asset,
    // we need to wait until that actually happens.
    // @fixme Learn a better way of doing this.
    while (find.byKey(const Key('_MyHomePageState.ListTile')).evaluate().isEmpty) {
      await tester.pumpAndSettle();
    }
    // Ensure the app's title is displayed.
    expect(find.textContaining('Református énekeskönyv (48-as fekete és 21-es kék)'), findsWidgets);
    // Ensure the first song is displayed in the list.
    expect(find.textContaining('Aki nem jár hitlenek tanácsán'), findsOneWidget);

    // expect(find.byKey(const Key('_MyHomePageState.ListTile'), skipOffstage: false).evaluate().length, 513, reason: 'All songs found');

    // Ensure there is one IconButton.
    final _iconButton = find.byKey(const Key('_MyHomePageState.IconButton'));
    expect(_iconButton, findsOneWidget);

    // Now let's do some song/verse navigation tests, starting from the first
    // page.
    await tester.tap(find.textContaining('Aki nem jár hitlenek tanácsán'));
    await tester.pumpAndSettle();
    final _mySongPageState = find.byKey(const Key('_MySongPageState'));
    expect(_mySongPageState, findsOneWidget);
    expect(find.textContaining('1. zsoltár'), findsOneWidget);
    final prevVerse = find.byKey(const Key('_MySongPageState.IconButton.prevVerse'));
    final prevSong = find.byKey(const Key('_MySongPageState.IconButton.prevSong'));
    final nextSong = find.byKey(const Key('_MySongPageState.IconButton.nextSong'));
    final nextVerse = find.byKey(const Key('_MySongPageState.IconButton.nextVerse'));
    // All four IconButtons should be present...
    expect(prevVerse, findsOneWidget);
    expect(prevSong, findsOneWidget);
    expect(nextSong, findsOneWidget);
    expect(nextVerse, findsOneWidget);
    // ...but only the first two should be disabled.
    expect(tester.widget<IconButton>(prevVerse).onPressed, null);
    expect(tester.widget<IconButton>(prevSong).onPressed, null);
    expect(tester.widget<IconButton>(nextSong).onPressed != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed != null, true);
    // Tapping the top half of the song page should switch to the previous
    // verse, even if it's the previous song's last verse - but only if there
    // _is_ a previous song/verse.
    final _mySongPageStateCenter = tester.getCenter(_mySongPageState);
    final _mySongPageStateSize = tester.getSize(_mySongPageState);
    await tester.tapAt(Offset(_mySongPageStateSize.width / 2 - _mySongPageStateCenter.dx / 2, _mySongPageStateSize.height / 2 - _mySongPageStateCenter.dy / 2));
    await tester.pumpAndSettle();
    // So only the first two IconButtons should be disabled still.
    expect(tester.widget<IconButton>(prevVerse).onPressed, null);
    expect(tester.widget<IconButton>(prevSong).onPressed, null);
    expect(tester.widget<IconButton>(nextSong).onPressed != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed != null, true);
    // Now let's navigate to the second verse.
    await tester.tap(nextVerse);
    await tester.pumpAndSettle();
    // Now the prevVerse IconButton should also be available.
    expect(tester.widget<IconButton>(prevVerse).onPressed != null, true);
    expect(tester.widget<IconButton>(prevSong).onPressed, null);
    expect(tester.widget<IconButton>(nextSong).onPressed != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed != null, true);
    // Now let's navigate to the fourth verse.
    await tester.tap(nextVerse);
    await tester.tap(nextVerse);
    await tester.pumpAndSettle();
    // On the last verse the nextVerse IconButton should not be available.
    expect(tester.widget<IconButton>(prevVerse).onPressed != null, true);
    expect(tester.widget<IconButton>(prevSong).onPressed, null);
    expect(tester.widget<IconButton>(nextSong).onPressed != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed, null);
    // Tapping on the bottom half of the song page should also switch to the
    // next verse, but even on the last verse of a song.
    await tester.tapAt(Offset(_mySongPageStateSize.width / 2 + _mySongPageStateCenter.dx / 2, _mySongPageStateSize.height / 2 + _mySongPageStateCenter.dy / 2));
    await tester.pumpAndSettle();
    // Now the second song's first verse should be displayed.
    expect(find.textContaining('2. zsoltár'), findsOneWidget);
    expect(tester.widget<IconButton>(prevVerse).onPressed, null);
    expect(tester.widget<IconButton>(prevSong).onPressed != null, true);
    expect(tester.widget<IconButton>(nextSong).onPressed != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed != null, true);
    // Go to the second verse.
    await tester.tap(nextVerse);
    await tester.pumpAndSettle();
    // Now the second song's second verse should be displayed.
    expect(tester.widget<IconButton>(prevVerse).onPressed != null, true);
    expect(tester.widget<IconButton>(prevSong).onPressed != null, true);
    expect(tester.widget<IconButton>(nextSong).onPressed != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed != null, true);

    // Now let's test the form.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(_iconButton);
    await tester.pumpAndSettle();
    // Ensure the proper page is displayed.
    expect(find.text('Ugrás énekre'), findsOneWidget);
    // Ensure there is one TextFormField.
    final _textFormField = find.byKey(const Key('_MyCustomFormState.TextFormField'));
    expect(_textFormField, findsOneWidget);
    // Ensure the limits are displayed.
    expect(find.text('(1 és 513 között)'), findsOneWidget);
    // Ensure it's empty.
    final _textFormFieldWidgetController = (_textFormField.evaluate().first.widget as TextFormField).controller;
    expect(_textFormFieldWidgetController?.text, '');
    // Ensure error messages when submitting invalid form values.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Hiányzó adat'), findsOneWidget);
    await tester.enterText(_textFormField, '0');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Hibás adat'), findsOneWidget);
    await tester.enterText(_textFormField, '514');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Hibás adat'), findsOneWidget);
    // Ensure that the song page gets displayed after submitting valid form
    // values.
    _textFormFieldWidgetController?.clear();

    // OK, let's move on to a song with a single verse.
    await tester.enterText(_textFormField, '117');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_mySongPageState, findsOneWidget);
    expect(find.textContaining('Az Urat minden nemzetek'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(prevVerse).onPressed, null);
    expect(tester.widget<IconButton>(prevSong).onPressed != null, true);
    expect(tester.widget<IconButton>(nextSong).onPressed != null, true);
    expect(tester.widget<IconButton>(nextVerse).onPressed, null);

    // Ensure the TextFormField is empty after returning from the song page.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_textFormFieldWidgetController?.text, '');

    // And also check the prev/next controls on the very last verse.
    await tester.enterText(_textFormField, '513');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(nextVerse);
    await tester.tap(nextVerse);
    await tester.tap(nextVerse);
    await tester.tap(nextVerse);
    await tester.tap(nextVerse);
    await tester.tap(nextVerse);
    await tester.tap(nextVerse);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(prevVerse).onPressed != null, true);
    expect(tester.widget<IconButton>(prevSong).onPressed != null, true);
    expect(tester.widget<IconButton>(nextSong).onPressed, null);
    expect(tester.widget<IconButton>(nextVerse).onPressed, null);
  });

}
