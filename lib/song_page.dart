import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wakelock/wakelock.dart';

import 'settings_provider.dart';
import 'util.dart';

import 'quick_settings_dialog.dart';

class MySongPage extends StatefulWidget {
  const MySongPage(
      {Key? key,
      required this.book,
      required this.songIndex,
      required this.settingsProvider,
      this.verseIndex = 0})
      : super(key: key);

  final Book book;
  final SettingsProvider settingsProvider;
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
    var songKey = globalSongs[widget.book.name].keys.elementAt(_song);

    // Whenever this widget (screen) needs to be rebuilt, (re-)initialize this
    // page controller to point to the correct page. When coming from the list,
    // it's inherited via initState().
    final pageController = PageController(
      initialPage: _verse,
    );

    List<Widget> getFirstVerseHeader() {
      final List<Widget> firstVerseHeader = [];
      switch (widget.book) {
        // In case of the black book (48), the subtitle and the composer should
        // be displayed.
        case Book.black:
          if (globalSongs[widget.book.name][songKey]['subtitle'] is String) {
            firstVerseHeader
                .add(Text(globalSongs[widget.book.name][songKey]['subtitle']));
          }
          if (globalSongs[widget.book.name][songKey]['composer'] is String) {
            firstVerseHeader.add(Text(
              globalSongs[widget.book.name][songKey]['composer'],
              textAlign: TextAlign.right,
            ));
          }
          break;

        // In case of the blue book (21), all the metadata should be displayed.
        case Book.blue:
        default:
          final List<String> metadata = [];
          if (globalSongs[widget.book.name][songKey]['subtitle'] is String) {
            metadata.add(globalSongs[widget.book.name][songKey]['subtitle']);
          }
          if (globalSongs[widget.book.name][songKey]['poet'] is String) {
            metadata
                .add('sz: ${globalSongs[widget.book.name][songKey]['poet']}');
          }
          if (globalSongs[widget.book.name][songKey]['translator'] is String) {
            metadata.add(
                'f: ${globalSongs[widget.book.name][songKey]['translator']}');
          }
          if (globalSongs[widget.book.name][songKey]['composer'] is String) {
            metadata.add(
                'd: ${globalSongs[widget.book.name][songKey]['composer']}');
          }
          if (metadata.isNotEmpty) {
            firstVerseHeader.add(Text(metadata.join(' | ')));
          }
          break;
      }
      return firstVerseHeader;
    }

    Widget getScore(
        Orientation orientation, int verseIndex, BuildContext context) {
      // The actual verse number is the number (well, any text) before the first
      // dot of the verse text.
      final verseNumber = globalSongs[widget.book.name][songKey]['texts']
              [verseIndex]
          .split('.')[0];
      final fileName =
          // ignore: prefer_interpolation_to_compose_strings
          'assets/ref${widget.book.name}/ref${widget.book.name}-' +
              songKey.padLeft(3, '0') +
              '-' +
              verseNumber.padLeft(3, '0') +
              '.svg';
      return SvgPicture.asset(
        fileName,
        // The score should utilize the full width of the screen, regardless its
        // size. This covers two cases:
        // - rotating the device,
        // - devices with different widths.
        width: MediaQuery.of(context).size.width *
            ((orientation == Orientation.portrait) ? 1.0 : 0.7),
        color: Theme.of(context).textTheme.titleSmall!.color,
      );
    }

    // Builds the pages for the current song's verses.
    List<List<Widget>> buildPages(
        Orientation orientation, BuildContext context) {
      // Nested list; a page is just a list of widgets.
      final List<List<Widget>> pages = [];
      // Collects the list items for the current page. When not all verses
      // should have scores displayed, the song consists of one single page.
      var page = <Widget>[];
      for (var verseIndex = 0;
          verseIndex < globalSongs[widget.book.name][songKey]['texts'].length;
          verseIndex++) {
        // Only display certain info above the first verse.
        if (verseIndex == 0) {
          page.addAll(getFirstVerseHeader());
        }

        // Add either the score or the text of the current verse, as needed.
        if (widget.settingsProvider.scoreDisplay == ScoreDisplay.all ||
            (widget.settingsProvider.scoreDisplay == ScoreDisplay.first &&
                verseIndex == 0)) {
          page.add(getScore(orientation, verseIndex, context));
        } else {
          page.add(
            Padding(
              // Add space between verses.
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    fontSize: widget.settingsProvider.fontSize,
                  ),
                  children: [
                    // Display verse number (everything before and including
                    // the first dot) in bold.
                    TextSpan(
                      text:
                          '${globalSongs[widget.book.name][songKey]['texts'][verseIndex].split('.')[0]}.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Display rest of verse text normally (split at dots,
                    // skip the first slice, join the rest).
                    TextSpan(
                      text: globalSongs[widget.book.name][songKey]['texts']
                              [verseIndex]
                          .split('.')
                          .skip(1)
                          .join('.'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Only display the poet (if exists) below the last verse, and only do
        // it for the black (48) book.
        if (widget.book == Book.black &&
            verseIndex ==
                globalSongs[widget.book.name][songKey]['texts'].length - 1 &&
            globalSongs[widget.book.name][songKey]['poet'] is String) {
          page.add(Text(
            globalSongs[widget.book.name][songKey]['poet'],
            textAlign: TextAlign.right,
          ));
        }

        // When all verses should have scores displayed, every verse should have
        // its own page, and a new page should start (for the next verse, if
        // any).
        if (widget.settingsProvider.scoreDisplay == ScoreDisplay.all) {
          pages.add(page);
          page = <Widget>[];
        }
      }
      // When NOT all verses should have scores displayed, the single page that
      // has been built so far should definitely be displayed.
      if (widget.settingsProvider.scoreDisplay != ScoreDisplay.all) {
        pages.add(page);
      }
      return pages;
    }

    void switchVerse(bool next) {
      int originalVerse = _verse;
      int originalSong = _song;
      if (next) {
        // Only allow switching to the next verse when all verses should have
        // scores (and there _is_ a next verse).
        if ((widget.settingsProvider.scoreDisplay == ScoreDisplay.all) &&
            _verse <
                globalSongs[widget.book.name][songKey]['texts'].length - 1) {
          _verse++;
        } else if (_song < globalSongs[widget.book.name].length - 1) {
          _song++;
          _verse = 0;
        }
      } else {
        // Only allow switching to the previous verse when all verses should
        // have scores (and there _is_ a previous verse).
        if ((widget.settingsProvider.scoreDisplay == ScoreDisplay.all) &&
            _verse > 0) {
          _verse--;
        } else if (_song > 0) {
          _song--;
          if (widget.settingsProvider.scoreDisplay == ScoreDisplay.all) {
            // This songKey must be recalculated to be able to fetch the number
            // of verses for the previous song.
            songKey = globalSongs[widget.book.name].keys.elementAt(_song);
            _verse = globalSongs[widget.book.name][songKey]['texts'].length - 1;
          } else {
            // When not all verses should have their scores displayed,
            // technically always their first verse is displayed.
            _verse = 0;
          }
        }
      }
      if (originalVerse != _verse || originalSong != _song) {
        if (originalSong != _song) {
          pageController.jumpToPage(_verse);
          scrollController.jumpTo(0);
        } else {
          pageController.animateToPage(
            _verse,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    }

    // When the NestedScrollView-covered area (the whole screen/page without the
    // appBar and the bottomNavigationBar) gets tapped, page either to the
    // previous verse (or the last verse of the previous song) or the next verse
    // (or the first verse of the next song), if possible.
    // But the NestedScrollView might affect this badly, so let's only consider
    // those taps that ended up at (nearly) the same place they started at.
    Offset tapDownPosition = Offset.zero;

    List<Widget> controllerButtons = [];
    if (widget.settingsProvider.scoreDisplay == ScoreDisplay.all) {
      // Switch to the previous verse (if exists).
      controllerButtons.add(IconButton(
        onPressed: _verse == 0 ? null : () => switchVerse(false),
        icon: const Icon(Icons.arrow_circle_left_outlined),
        tooltip: 'Előző vers',
        disabledColor: ThemeData.dark().highlightColor,
        key: const Key('_MySongPageState.IconButton.prevVerse'),
      ));
    }
    // Switch to the previous song's first verse (if exists).
    controllerButtons.add(TextIconButton(
      text: _song == 0
          ? null
          : globalSongs[widget.book.name].keys.elementAt(_song - 1),
      onTap: _song == 0
          ? null
          : () {
              setState(() {
                _song--;
                _verse = 0;
                pageController.jumpToPage(_verse);
                scrollController.jumpTo(0);
              });
            },
      iconData: Icons.arrow_upward,
      tooltip: 'Előző ének',
      disabledColor: ThemeData.dark().highlightColor,
      key: const Key('_MySongPageState.IconButton.prevSong'),
      alignment: Alignment.topRight,
      context: context,
    ));
    if (widget.settingsProvider.scoreDisplay != ScoreDisplay.all) {
      // Change font size.
      controllerButtons.add(IconButton(
        onPressed: widget.settingsProvider.fontSize < 40.0
            ? () => {
                  setState(() {
                    widget.settingsProvider
                        .changeFontSize(widget.settingsProvider.fontSize + 1.0);
                  })
                }
            : null,
        icon: const Icon(Icons.text_increase),
        tooltip: 'Betűméret növelése',
        disabledColor: ThemeData.dark().highlightColor,
        key: const Key('_MySongPageState.IconButton.textIncrease'),
      ));
    }
    controllerButtons.add(IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Gyorsmenü',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => quickSettingsDialog(
              context, globalSongs[widget.book.name][songKey]),
        );
      },
    ));
    if (widget.settingsProvider.scoreDisplay != ScoreDisplay.all) {
      controllerButtons.add(IconButton(
        onPressed: widget.settingsProvider.fontSize > 10.0
            ? () => {
                  setState(() {
                    widget.settingsProvider
                        .changeFontSize(widget.settingsProvider.fontSize - 1.0);
                  })
                }
            : null,
        icon: const Icon(Icons.text_decrease),
        tooltip: 'Betűméret csökkentése',
        disabledColor: ThemeData.dark().highlightColor,
        key: const Key('_MySongPageState.IconButton.textDecrease'),
      ));
    }
    // Switch to the next song's first verse (if exists).
    controllerButtons.add(TextIconButton(
      text: _song == globalSongs[widget.book.name].length - 1
          ? null
          : globalSongs[widget.book.name].keys.elementAt(_song + 1),
      onTap: _song == globalSongs[widget.book.name].length - 1
          ? null
          : () {
              setState(() {
                _song++;
                _verse = 0;
                pageController.jumpToPage(_verse);
                scrollController.jumpTo(0);
              });
            },
      iconData: Icons.arrow_downward,
      tooltip: 'Következő ének',
      disabledColor: ThemeData.dark().highlightColor,
      key: const Key('_MySongPageState.IconButton.nextSong'),
      alignment: Alignment.bottomRight,
      context: context,
    ));
    if (widget.settingsProvider.scoreDisplay == ScoreDisplay.all) {
      // Switch to the next verse (if exists).
      controllerButtons.add(IconButton(
        onPressed: (_verse ==
                globalSongs[widget.book.name][songKey]['texts'].length - 1)
            ? null
            : () => switchVerse(true),
        icon: const Icon(Icons.arrow_circle_right_outlined),
        tooltip: 'Következő vers',
        disabledColor: ThemeData.dark().highlightColor,
        key: const Key('_MySongPageState.IconButton.nextVerse'),
      ));
    }

    return Scaffold(
      // @see https://api.flutter.dev/flutter/widgets/NestedScrollView-class.html
      body: OrientationBuilder(
        builder: (context, orientation) {
          return SafeArea(
            child: Container(
              // Prevent screen artifacts (single-pixel line with opposing
              // color) on certain devices.
              margin: const EdgeInsets.only(
                top: 1.0,
                bottom: 1.0,
              ),
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
                                getSongTitle(
                                    globalSongs[widget.book.name][songKey]),
                                style: const TextStyle(fontSize: 18),
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ];
                      }),
                      body: Theme(
                        data: ThemeData(
                          useMaterial3: true,
                          brightness: widget.settingsProvider
                              .getCurrentSheetBrightness(context),
                        ),
                        // Needs a separate [Material] and [Builder] for
                        // providing a new BuildContext to children properly.
                        child: Builder(
                          builder: (BuildContext context) {
                            return Material(
                              child: GestureDetector(
                                onTapDown: (details) {
                                  tapDownPosition = details.globalPosition;
                                },
                                onTapUp: (details) {
                                  // Bail out early if tap ended more than 3.0
                                  // away from where it started.
                                  if ((details.globalPosition - tapDownPosition)
                                          .distance >
                                      3.0) {
                                    return;
                                  }
                                  setState(() {
                                    if ((MediaQuery.of(context).size.width /
                                            2) >
                                        details.globalPosition.dx) {
                                      // Go backward (to the previous verse).
                                      switchVerse(false);
                                    } else {
                                      // Go forward (to the next verse).
                                      switchVerse(true);
                                    }
                                  });
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
                                  children: buildPages(orientation, context)
                                      .map((pageContentList) {
                                    return Builder(
                                      builder: (BuildContext context) {
                                        return Padding(
                                          // Prevent having score and/or text
                                          // sticking to the side of the
                                          // display.
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3.0,
                                          ),
                                          child: CustomScrollView(
                                            key:
                                                PageStorageKey(pageContentList),
                                            slivers: [
                                              SliverOverlapInjector(
                                                handle: NestedScrollView
                                                    .sliverOverlapAbsorberHandleFor(
                                                        context),
                                              ),
                                              SliverList(
                                                delegate:
                                                    SliverChildListDelegate
                                                        .fixed(pageContentList),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Theme(
                    data: ThemeData(
                      useMaterial3: true,
                      brightness: widget.settingsProvider
                          .getCurrentSheetBrightness(context),
                    ),
                    child: Builder(
                      builder: (BuildContext context) {
                        return Material(
                          color: Theme.of(context).cardColor,
                          child: Flex(
                            direction: orientation == Orientation.portrait
                                ? Axis.horizontal
                                : Axis.vertical,
                            // Make the buttons "justified" (ie. use all the
                            // screen width).
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: controllerButtons,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      key: const Key('_MySongPageState'),
    );
  }
}

class TextIconButton extends StatelessWidget {
  final void Function()? onTap;
  final String? text;
  final String? tooltip;
  final IconData iconData;
  final Color disabledColor;
  final BuildContext context;
  final Alignment alignment;

  const TextIconButton(
      {Key? key,
      this.tooltip,
      required this.text,
      required this.onTap,
      required this.iconData,
      required this.disabledColor,
      required this.alignment,
      required this.context})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Stack(
            alignment: text != null ? alignment : Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 13, 17, 13),
                child: Text(
                  text ?? '',
                  style: TextStyle(
                    color: onTap != null ? null : disabledColor,
                  ),
                ),
              ),
              Icon(
                iconData,
                color: onTap != null ? null : disabledColor,
              ),
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
      ),
    );
  }
}
