import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wakelock/wakelock.dart';

import 'util.dart';

class MySongPage extends StatefulWidget {
  const MySongPage(
      {Key? key,
      required this.songsInBook,
      required this.selectedBook,
      required this.songIndex,
      this.verseIndex = 0})
      : super(key: key);

  final LinkedHashMap songsInBook;
  final Book selectedBook;
  final int songIndex;
  final int verseIndex;

  @override
  State<MySongPage> createState() => _MySongPageState();
}

class _MySongPageState extends State<MySongPage> {
  // Initialize these to numbers that cannot be picked in the list (or just make
  // no sense at all). Also, it's much easier to maintain these as state
  // variables than trying to retrieve the current verse number from the
  // pageController.
  int _song = -1;
  int _verse = -1;

  @override
  void initState() {
    // When coming from the list, these internal numbers are invalid - so let's
    // inherit them from the caller's parameters.
    _song = widget.songIndex;
    _verse = widget.verseIndex;
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
    // To retrieve the song data, the key (the actual number of the song) is
    // needed, not the index (the position in the list).
    var songKey = widget.songsInBook.keys.elementAt(_song);

    // Whenever this widget (screen) needs to be rebuilt, (re-)initialize this
    // page controller to point to the correct page. When coming from the list,
    // it's inherited via initState().
    final pageController = PageController(
      initialPage: _verse,
    );

    // An internal utility function.
    Text blackText(String data) {
      return Text(
        data,
        style: const TextStyle(
          color: Colors.black,
        ),
      );
    }

    // Builds the pages for the current song's verses.
    List<Widget> buildPages() {
      final pages = <Widget>[];
      for (var verseIndex = 0;
          verseIndex < widget.songsInBook[songKey]['texts'].length;
          verseIndex++) {
        // As the song page is basically a ListView (with a Scrollbar for songs
        // taller than the screen), let's collect the list items for the current
        // page (verse).
        final children = <Widget>[];

        // Only display the composer (if exists) above the first verse.
        if (verseIndex == 0 &&
            widget.songsInBook[songKey]['composer'] is String) {
          children.add(blackText(widget.songsInBook[songKey]['composer']));
        }

        // The actual verse number is the number (well, any text) before the
        // first dot of the verse text.
        final verseNumber =
            widget.songsInBook[songKey]['texts'][verseIndex].split('.')[0];
        final fileName =
            'assets/ref${widget.selectedBook}/ref${widget.selectedBook}-' +
                songKey.padLeft(3, '0') +
                '-' +
                verseNumber.padLeft(3, '0') +
                '.svg';
        children.add(SvgPicture.asset(
          fileName,
          // The score should utilize the full width of the screen, regardless
          // its size. This covers two cases:
          // - rotating the device,
          // - devices with different widths.
          width: MediaQuery.of(context).size.width,
        ));

        // Only display the poet (if exists) below the last verse.
        if (verseIndex == widget.songsInBook[songKey]['texts'].length - 1 &&
            widget.songsInBook[songKey]['poet'] is String) {
          children.add(blackText(widget.songsInBook[songKey]['poet']));
        }

        pages.add(Scrollbar(
          // As some scores are taller than the screen, it would be nice to have
          // a tiny scrollbar always displayed. However, the PageView()
          // conflicts with thumbVisibility: true, so this is the best we can
          // do.
          thickness: 3.0,
          child: ListView(
            // Let's add the same amount of padding (to avoid having the
            // rightmost part of the score covered by the scrollbar).
            padding: const EdgeInsets.all(3.0),
            children: children,
          ),
        ));
      }
      return pages;
    }

    // When the Scrollbar-covered area (the whole screen/page without the appBar
    // and the bottomNavigationBar) gets tapped, page either to the previous
    // verse (or the last verse of the previous song) or the next verse (or the
    // first verse of the next song), if possible.
    // But the Scrollbar might affect this badly, so let's only consider those
    // taps that ended up at (nearly) the same place they started at.
    Offset tapDownPosition = Offset.zero;

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
            if ((MediaQuery.of(context).size.width / 2) >
                details.globalPosition.dx) {
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
            pageController.jumpToPage(_verse);
          }
        },
        child: PageView(
          controller: pageController,
          children: buildPages(),
          // Update internal verse index when page has changed. This must be
          // wrapped in a setState() because the buttons might need updating,
          // too.
          onPageChanged: (i) {
            setState(() {
              _verse = i;
            });
          },
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
              onPressed: _verse == 0
                  ? null
                  : () {
                      setState(() {
                        _verse--;
                        pageController.jumpToPage(_verse);
                      });
                    },
              icon: const Icon(Icons.arrow_circle_left_outlined),
              color: Colors.black,
              disabledColor: ThemeData.dark().highlightColor,
              key: const Key('_MySongPageState.IconButton.prevVerse'),
            ),
            // Switch to the previous song's first verse (if exists).
            IconButton(
              onPressed: _song == 0
                  ? null
                  : () {
                      setState(() {
                        _song--;
                        _verse = 0;
                        pageController.jumpToPage(_verse);
                      });
                    },
              icon: const Icon(Icons.arrow_circle_up_outlined),
              color: Colors.black,
              disabledColor: ThemeData.dark().highlightColor,
              key: const Key('_MySongPageState.IconButton.prevSong'),
            ),
            // Switch to the next song's first verse (if exists).
            IconButton(
              onPressed: _song == widget.songsInBook.length - 1
                  ? null
                  : () {
                      setState(() {
                        _song++;
                        _verse = 0;
                        pageController.jumpToPage(_verse);
                      });
                    },
              icon: const Icon(Icons.arrow_circle_down_outlined),
              color: Colors.black,
              disabledColor: ThemeData.dark().highlightColor,
              key: const Key('_MySongPageState.IconButton.nextSong'),
            ),
            // Switch to the next verse (if exists).
            IconButton(
              onPressed:
                  (_verse == widget.songsInBook[songKey]['texts'].length - 1)
                      ? null
                      : () {
                          setState(() {
                            _verse++;
                            pageController.jumpToPage(_verse);
                          });
                        },
              icon: const Icon(Icons.arrow_circle_right_outlined),
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
