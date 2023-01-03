import 'dart:collection';
import 'dart:io';

import 'package:enekeskonyv/book_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wakelock/wakelock.dart';

import 'util.dart';

class MySongPage extends StatefulWidget {
  const MySongPage(
      {Key? key,
      required this.songsInBook,
      required this.bookProvider,
      required this.songIndex,
      this.verseIndex = 0})
      : super(key: key);

  final LinkedHashMap songsInBook;
  final BookProvider bookProvider;
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

  ScrollController scrollController = ScrollController();

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
    // TODO instead change theme to light for the page.
    Text blackText(String data) {
      return Text(
        data,
        style: const TextStyle(
          color: Colors.black,
        ),
      );
    }

    // Builds the pages for the current song's verses.
    List<List<Widget>> buildPages(Orientation orientation) {
      // Nested list; a page is just a list of widgets.
      final List<List<Widget>> pages = [];
      for (var verseIndex = 0;
          verseIndex < widget.songsInBook[songKey]['texts'].length;
          verseIndex++) {
        // Let's collect the list items for the current page (verse).
        final children = <Widget>[];

        // Only display certain info above the first verse.
        if (verseIndex == 0) {
          switch (widget.bookProvider.book) {
            // In case of the black book (48), the subtitle and the composer
            // should be displayed.
            case Book.black:
              if (widget.songsInBook[songKey]['subtitle'] is String) {
                children
                    .add(blackText(widget.songsInBook[songKey]['subtitle']));
              }
              if (widget.songsInBook[songKey]['composer'] is String) {
                children
                    .add(blackText(widget.songsInBook[songKey]['composer']));
              }
              break;

            // In case of the blue book (21), all the metadata should be
            // displayed.
            case Book.blue:
            default:
              final List<String> metadata = [];
              if (widget.songsInBook[songKey]['subtitle'] is String) {
                metadata.add(widget.songsInBook[songKey]['subtitle']);
              }
              if (widget.songsInBook[songKey]['poet'] is String) {
                metadata.add('sz: ${widget.songsInBook[songKey]['poet']}');
              }
              if (widget.songsInBook[songKey]['translator'] is String) {
                metadata.add('f: ${widget.songsInBook[songKey]['translator']}');
              }
              if (widget.songsInBook[songKey]['composer'] is String) {
                metadata.add('d: ${widget.songsInBook[songKey]['composer']}');
              }
              if (metadata.isNotEmpty) {
                children.add(blackText(metadata.join(' | ')));
              }
              break;
          }
        }

        // The actual verse number is the number (well, any text) before the
        // first dot of the verse text.
        final verseNumber =
            widget.songsInBook[songKey]['texts'][verseIndex].split('.')[0];
        final fileName =
            // ignore: prefer_interpolation_to_compose_strings
            'assets/ref${widget.bookProvider.bookAsString}/ref${widget.bookProvider.bookAsString}-' +
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
          width: MediaQuery.of(context).size.width *
              ((orientation == Orientation.portrait) ? 1.0 : 0.7),
        ));

        // Only display the poet (if exists) below the last verse, and only do
        // it for the black (48) book.
        if (widget.bookProvider.book == Book.black &&
            verseIndex == widget.songsInBook[songKey]['texts'].length - 1 &&
            widget.songsInBook[songKey]['poet'] is String) {
          children.add(blackText(widget.songsInBook[songKey]['poet']));
        }

        pages.add(children);
      }
      return pages;
    }

    // When the NestedScrollView-covered area (the whole screen/page without the
    // appBar and the bottomNavigationBar) gets tapped, page either to the
    // previous verse (or the last verse of the previous song) or the next verse
    // (or the first verse of the next song), if possible.
    // But the NestedScrollView might affect this badly, so let's only consider
    // those taps that ended up at (nearly) the same place they started at.
    Offset tapDownPosition = Offset.zero;

    return Scaffold(
      // @see https://api.flutter.dev/flutter/widgets/NestedScrollView-class.html
      body: SafeArea(
        child: OrientationBuilder(builder: (context, orientation) {
          return Container(
            // TODO Make themeable.
            color: Colors.white,
            child: Flex(
              direction: orientation == Orientation.portrait
                  ? Axis.vertical
                  : Axis.horizontal,
              children: [
                Expanded(
                  child: NestedScrollView(
                    controller: scrollController,
                    headerSliverBuilder: ((context, innerBoxIsScrolled) {
                      return [
                        SliverOverlapAbsorber(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                                  context),
                          sliver: SliverAppBar(
                            pinned: orientation == Orientation.portrait,
                            // @see https://github.com/flutter/flutter/issues/79077#issuecomment-1226882532
                            expandedHeight: 57,
                            title: Text(
                              getSongTitle(widget.songsInBook[songKey]),
                              style: const TextStyle(fontSize: 18),
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ];
                    }),
                    body: GestureDetector(
                      onTapDown: (details) {
                        tapDownPosition = details.globalPosition;
                      },
                      onTapUp: (details) {
                        // Bail out early if tap ended more than 3.0 away from
                        // where it started.
                        if ((details.globalPosition - tapDownPosition)
                                .distance >
                            3.0) {
                          return;
                        }
                        int originalVerse = _verse;
                        int originalSong = _song;
                        setState(() {
                          if ((MediaQuery.of(context).size.width / 2) >
                              details.globalPosition.dx) {
                            // Go backward (to the previous verse).
                            if (_verse > 0) {
                              _verse--;
                            } else if (_song > 0) {
                              _song--;
                              // This songKey must be recalculated to be able to
                              // fetch the number of verses for the previous
                              // song.
                              songKey =
                                  widget.songsInBook.keys.elementAt(_song);
                              _verse =
                                  widget.songsInBook[songKey]['texts'].length -
                                      1;
                            }
                          } else {
                            // Go forward (to the next verse).
                            if (_verse <
                                widget.songsInBook[songKey]['texts'].length -
                                    1) {
                              _verse++;
                            } else if (_song < widget.songsInBook.length - 1) {
                              _song++;
                              _verse = 0;
                            }
                          }
                        });
                        if (originalVerse != _verse) {
                          if (originalSong != _song) {
                            pageController.jumpToPage(_verse);
                          } else {
                            pageController.animateToPage(
                              _verse,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      },
                      child: PageView(
                        controller: pageController,
                        onPageChanged: (i) {
                          setState(() {
                            _verse = i;
                          });
                        },
                        physics: Platform.isIOS
                            ? const BouncingScrollPhysics()
                            : null,
                        children:
                            buildPages(orientation).map((pageContentList) {
                          return Builder(builder: (BuildContext context) {
                            return CustomScrollView(
                              key: PageStorageKey(pageContentList),
                              slivers: [
                                SliverOverlapInjector(
                                  handle: NestedScrollView
                                      .sliverOverlapAbsorberHandleFor(context),
                                ),
                                SliverList(
                                  delegate: SliverChildListDelegate.fixed(
                                      pageContentList),
                                )
                              ],
                            );
                          });
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                Theme(
                  // TODO Make themable.
                  data: ThemeData(brightness: Brightness.light),
                  child: Material(
                    // @see https://stackoverflow.com/a/58304632/6460986
                    color: Theme.of(context).highlightColor,
                    child: Flex(
                      direction: orientation == Orientation.portrait
                          ? Axis.horizontal
                          : Axis.vertical,
                      // Make the buttons "justified" (ie. use all the screen
                      // width).
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Switch to the previous verse (if exists).
                        IconButton(
                          onPressed: _verse == 0
                              ? null
                              : () {
                                  setState(() {
                                    _verse--;
                                    pageController.animateToPage(
                                      _verse,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  });
                                },
                          icon: const Icon(Icons.arrow_circle_left_outlined),
                          disabledColor: ThemeData.dark().highlightColor,
                          key: const Key(
                              '_MySongPageState.IconButton.prevVerse'),
                        ),
                        // Switch to the previous song's first verse (if exists).
                        TextIconButton(
                          text: widget.songsInBook.keys.tryElementAt(_song - 1),
                          onTap: _song == 0
                              ? null
                              : () {
                                  setState(() {
                                    _song--;
                                    _verse = 0;
                                    pageController.jumpToPage(_verse);
                                    scrollController.animateTo(0,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut);
                                  });
                                },
                          iconData: Icons.arrow_upward,
                          disabledColor: ThemeData.dark().highlightColor,
                          key:
                              const Key('_MySongPageState.IconButton.prevSong'),
                          alignment: Alignment.topRight,
                          context: context,
                        ),
                        // Switch to the next song's first verse (if exists).
                        TextIconButton(
                          text: widget.songsInBook.keys.tryElementAt(_song + 1),
                          onTap: _song == widget.songsInBook.length - 1
                              ? null
                              : () {
                                  setState(() {
                                    _song++;
                                    _verse = 0;
                                    pageController.jumpToPage(_verse);
                                    scrollController.animateTo(0,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut);
                                  });
                                },
                          iconData: Icons.arrow_downward,
                          disabledColor: ThemeData.dark().highlightColor,
                          key:
                              const Key('_MySongPageState.IconButton.nextSong'),
                          alignment: Alignment.bottomRight,
                          context: context,
                        ),
                        // Switch to the next verse (if exists).
                        IconButton(
                          onPressed: (_verse ==
                                  widget.songsInBook[songKey]['texts'].length -
                                      1)
                              ? null
                              : () {
                                  setState(() {
                                    _verse++;
                                    pageController.animateToPage(
                                      _verse,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  });
                                },
                          icon: const Icon(Icons.arrow_circle_right_outlined),
                          disabledColor: ThemeData.dark().highlightColor,
                          key: const Key(
                              '_MySongPageState.IconButton.nextVerse'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
      key: const Key('_MySongPageState'),
    );
  }
}

class TextIconButton extends StatelessWidget {
  final void Function()? onTap;
  final String? text;
  final IconData iconData;
  final Color disabledColor;
  final BuildContext context;
  final Alignment alignment;

  const TextIconButton(
      {Key? key,
      required this.text,
      required this.onTap,
      required this.iconData,
      required this.disabledColor,
      required this.alignment,
      required this.context})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Stack(
          alignment: text != null ? alignment : Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 13, 17, 13),
              child: Text(
                text ?? '',
                style: TextStyle(color: onTap != null ? null : disabledColor),
              ),
            ),
            Icon(iconData, color: onTap != null ? null : disabledColor),
          ],
        ),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 50,
            height: 50,
          ),
        ),
      ],
    );
  }
}

extension TryElementAt on Iterable {
  String? tryElementAt(int index) {
    try {
      return elementAt(index);
    } catch (_) {
      return null;
    }
  }
}
