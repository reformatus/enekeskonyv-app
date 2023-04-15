import 'dart:collection';
import 'dart:io';

import 'package:enekeskonyv/song/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wakelock/wakelock.dart';

import '../settings_provider.dart';
import '../util.dart';

import '../quick_settings_dialog.dart';

import 'buttons.dart';

class SongPage extends StatefulWidget {
  const SongPage({
    Key? key,
    required this.book,
    required this.songIndex,
    this.verseIndex = 0,
  }) : super(key: key);

  final Book book;
  final int songIndex;
  final int verseIndex;

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  @override
  Widget build(BuildContext context) {
    // When the NestedScrollView-covered area (the whole screen/page without the
    // appBar and the bottomNavigationBar) gets tapped, page either to the
    // previous verse (or the last verse of the previous song) or the next verse
    // (or the first verse of the next song), if possible.
    // But the NestedScrollView might affect this badly, so let's only consider
    // those taps that ended up at (nearly) the same place they started at.
    Offset tapDownPosition = Offset.zero;

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
                              // Instead of the back button on the left, use
                              // this to go home immediately.
                              leading: IconButton(
                                tooltip: 'Főoldal',
                                icon: const Icon(Icons.list),
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/', (route) => false);
                                },
                              ),
                              pinned: orientation == Orientation.portrait,
                              // @see https://github.com/flutter/flutter/issues/79077#issuecomment-1226882532
                              expandedHeight: 57,
                              title: Text(
                                getSongTitle(
                                    songBooks[widget.book.name][songKey]),
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
                                onTapDown: widget.settingsProvider.tapNavigation
                                    ? (details) {
                                        tapDownPosition =
                                            details.globalPosition;
                                      }
                                    : null,
                                onTapUp: widget.settingsProvider.tapNavigation
                                    ? (details) {
                                        // Bail out early if tap ended more than
                                        // 3.0 away from where it started.
                                        if ((details.globalPosition -
                                                    tapDownPosition)
                                                .distance >
                                            3.0) {
                                          return;
                                        }
                                        setState(() {
                                          if ((MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2) >
                                              details.globalPosition.dx) {
                                            // Go backward (to the previous
                                            // verse).
                                            switchVerse(false);
                                          } else {
                                            // Go forward (to the next verse).
                                            switchVerse(true);
                                          }
                                        });
                                      }
                                    : null,
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
                  ButtonBar(),
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
