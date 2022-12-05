import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wakelock/wakelock.dart';

import 'util.dart';

class MySongPage extends StatefulWidget {
  const MySongPage({Key? key, required this.songsInBook, required this.selectedBook, required this.songIndex}) : super(key: key);

  final LinkedHashMap songsInBook;
  final String selectedBook;
  final int songIndex;

  @override
  State<MySongPage> createState() => _MySongPageState();
}

class _MySongPageState extends State<MySongPage> {
  // When coming from the list, always display the first verse of the song.
  int _verse = 0;
  // Initialize this to a number that cannot be picked in the list.
  int _song = -1;

  @override
  void initState() {
    super.initState();
    // Don't allow sleeping during singing a song! :)
    Wakelock.enable();
  }

  @override
  void dispose() {
    // Do allow sleeping in the list, tho.
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When coming from the list, the internal song number is invalid - so let's
    // inherit it by overriding it with the caller's parameter.
    if (_song == -1) {
      _song = widget.songIndex;
    }
    // To retrieve the song data, the key (the actual number of the song) is
    // needed, not the index (the position in the list).
    var songKey = widget.songsInBook.keys.elementAt(_song);

    // An internal utility function.
    Text blackText(String data) {
      return Text(
        data,
        style: const TextStyle(
          color: Colors.black,
        ),
      );
    }

    // As the song page is basically a ListView (with a Scrollbar for songs
    // taller than the screen), let's collect the list items.
    final children = <Widget>[];

    // Only display the composer (if exists) above the first verse.
    if (_verse == 0 && widget.songsInBook[songKey]['composer'] is String) {
      children.add(blackText(widget.songsInBook[songKey]['composer']));
    }

    // The actual verse number is the number (well, any text) before the first
    // dot of the verse text.
    final verseNumber = widget.songsInBook[songKey]['texts'][_verse].split('.')[0];
    final fileName = 'assets/ref${widget.selectedBook}/ref${widget.selectedBook}-' + songKey.padLeft(3, '0') + '-' + verseNumber.padLeft(3, '0') + '.svg';
    children.add(SvgPicture.asset(
      fileName,
      // The score should utilize the full width of the screen, regardless its
      // size. This covers two cases:
      // - rotating the device,
      // - devices with different widths.
      width: MediaQuery.of(context).size.width,
    ));

    // Only display the poet (if exists) below the last verse.
    if (_verse == widget.songsInBook[songKey]['texts'].length - 1 && widget.songsInBook[songKey]['poet'] is String) {
      children.add(blackText(widget.songsInBook[songKey]['poet']));
    }

    // When the Scrollbar-covered area (the whole screen/page without the appBar
    // and the bottomNavigationBar) gets tapped, page either to the previous
    // verse (or the last verse of the previous song) or the next verse (or the
    // first verse of the next song), if possible.
    // But the Scrollbar might affect this badly, so let's only consider those
    // taps that ended up at (nearly) the same place they started at.
    Offset tapDownPosition = Offset.zero;

    // This controller is needed to be able to jump to the top of the list/score
    // after paging.
    final ScrollController scrollController = ScrollController();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(Util.getSongTitle(widget.songsInBook[songKey])),
      ),
      body: GestureDetector(
        onTapDown: (details) {
          tapDownPosition = details.globalPosition;
        },
        onTapUp: (details) {
          // Bail out early if tap ended more than 3.0 away from where it
          // started.
          if ((details.globalPosition - tapDownPosition).distance > 3.0) {
            return;
          }
          var jump = false;
          setState(() {
            if ((MediaQuery.of(context).size.height / 2) > details.globalPosition.dy) {
              // Go backward (to the previous verse).
              if (_verse > 0) {
                _verse--;
                jump = true;
              } else if (_song > 0) {
                _song--;
                // This songKey must be recalculated to be able to fetch the
                // number of verses for the previous song.
                songKey = widget.songsInBook.keys.elementAt(_song);
                _verse = widget.songsInBook[songKey]['texts'].length - 1;
                jump = true;
              }
            } else {
              // Go forward (to the next verse).
              if (_verse < widget.songsInBook[songKey]['texts'].length - 1) {
                _verse++;
                jump = true;
              } else if (_song < widget.songsInBook.length - 1) {
                _song++;
                _verse = 0;
                jump = true;
              }
            }
          });
          if (jump) {
            scrollController.jumpTo(0);
          }
        },
        child: Scrollbar(
          controller: scrollController,
          // As some scores are taller than the screen, a tiny scrollbar is always
          // displayed.
          thumbVisibility: true,
          thickness: 3.0,
          child: ListView(
            controller: scrollController,
            // As there's always a tiny scrollbar displayed, let's add the same
            // amount of padding (to avoid having the rightmost part of the score
            // covered by the scrollbar).
            padding: const EdgeInsets.all(3.0),
            children: children,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: ThemeData.dark().highlightColor,
        child: Row(
          // Make the buttons "justified" (ie. use all the screen width).
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Switch to the previous verse (if exists).
            IconButton(
              onPressed: _verse == 0 ? null : () {
                setState(() {
                  _verse--;
                });
                scrollController.jumpTo(0);
              },
              icon: const Icon(Icons.arrow_circle_up),
              color: Colors.black,
              disabledColor: ThemeData.dark().highlightColor,
              key: const Key('_MySongPageState.IconButton.prevVerse'),
            ),
            // Switch to the previous song's first verse (if exists).
            IconButton(
              onPressed: _song == 0 ? null : () {
                setState(() {
                  _song--;
                  _verse = 0;
                });
                scrollController.jumpTo(0);
              },
              icon: const Icon(Icons.arrow_circle_left_outlined),
              color: Colors.black,
              disabledColor: ThemeData.dark().highlightColor,
              key: const Key('_MySongPageState.IconButton.prevSong'),
            ),
            // Switch to the next song's first verse (if exists).
            IconButton(
              onPressed: _song == widget.songsInBook.length -1 ? null : () {
                setState(() {
                  _song++;
                  _verse = 0;
                });
                scrollController.jumpTo(0);
              },
              icon: const Icon(Icons.arrow_circle_right_outlined),
              color: Colors.black,
              disabledColor: ThemeData.dark().highlightColor,
              key: const Key('_MySongPageState.IconButton.nextSong'),
            ),
            // Switch to the next verse (if exists).
            IconButton(
              onPressed: (_verse == widget.songsInBook[songKey]['texts'].length - 1) ? null : () {
                setState(() {
                  _verse++;
                });
                scrollController.jumpTo(0);
              },
              icon: const Icon(Icons.arrow_circle_down),
              color: Colors.black,
              disabledColor: ThemeData.dark().highlightColor,
              key: const Key('_MySongPageState.IconButton.nextVerse'),
            ),
          ],
        ),
      ),
      key: const Key('_MySongPageState'),
    );
  }
}
