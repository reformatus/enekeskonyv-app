import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../settings_provider.dart';
import '../util.dart';
import 'build_pages.dart';
import 'buttons.dart';
import 'song_page_state.dart';
import 'utils.dart';
import 'verse_bar.dart';

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

class _SongPageState extends State<SongPage> with TickerProviderStateMixin {
  bool _listenerAdded = false;

  @override
  Widget build(BuildContext context) {
    // When the NestedScrollView-covered area (the whole screen/page without the
    // appBar and the bottomNavigationBar) gets tapped, page either to the
    // previous verse (or the last verse of the previous song) or the next verse
    // (or the first verse of the next song), if possible.
    // But the NestedScrollView might affect this badly, so let's only consider
    // those taps that ended up at (nearly) the same place they started at.
    Offset tapDownPosition = Offset.zero;

    return ChangeNotifierProvider<SongStateProvider>(
      create: (context) => SongStateProvider(
        song: widget.songIndex,
        verse: widget.verseIndex,
        book: widget.book,
        vsync: this,
        context: context,
      ),
      child: Consumer2<SettingsProvider, SongStateProvider>(
          builder: (context, settings, state, child) {
        if (!_listenerAdded) {
          SettingsProvider.of(context).addListener(() {
            SongStateProvider.of(context)
                .settingsListener(context: context, vsync: this);
          });
          _listenerAdded = true;
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
                          controller: state.scrollController,
                          headerSliverBuilder: ((context, innerBoxIsScrolled) {
                            return [
                              SliverOverlapAbsorber(
                                handle: NestedScrollView
                                    .sliverOverlapAbsorberHandleFor(context),
                                sliver: SliverAppBar(
                                  // Instead of the back button on the left, use
                                  // this to go home immediately.
                                  leading: IconButton(
                                    tooltip: 'Főoldal',
                                    icon: const Icon(Icons.menu_book),
                                    onPressed: () {
                                      Navigator.pushNamedAndRemoveUntil(
                                          context, '/', (route) => false);
                                    },
                                  ),
                                  pinned: orientation == Orientation.portrait,
                                  // @see https://github.com/flutter/flutter/issues/79077#issuecomment-1226882532
                                  expandedHeight: 57,
                                  title: Text(
                                    getSongTitle(songBooks[widget.book.name]
                                        [state.songKey]),
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
                              brightness:
                                  settings.getCurrentSheetBrightness(context),
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
                                    onTapUp: (details) => onTapUp(details,
                                        context, tapDownPosition, this),
                                    child: (settings.isVerseBarPinned)
                                        ? Column(
                                            children: [
                                              Expanded(
                                                child: buildTabBarView(state,
                                                    orientation, context),
                                              ),
                                              if (settings.scoreDisplay ==
                                                  ScoreDisplay.all)
                                                const VerseBar(),
                                            ],
                                          )
                                        : Stack(
                                            alignment: Alignment.bottomCenter,
                                            children: [
                                              buildTabBarView(
                                                  state, orientation, context),
                                              if (settings.scoreDisplay ==
                                                  ScoreDisplay.all)
                                                AnimatedPositioned(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  curve: Curves
                                                      .easeInOutCubicEmphasized,
                                                  right: 0,
                                                  left: 0,
                                                  bottom:
                                                      state.isVerseBarVisible
                                                          ? 0
                                                          : -70,
                                                  child: const VerseBar(),
                                                ),
                                            ],
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      ControllerButtons(
                        orientation: orientation,
                        vsync: this,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          key: const Key('_MySongPageState'),
        );
      }),
    );
  }

  TabBarView buildTabBarView(
      SongStateProvider state, Orientation orientation, BuildContext context) {
    return TabBarView(
      controller: state.tabController,
      physics: Platform.isIOS ? const BouncingScrollPhysics() : null,
      children: buildPages(orientation, state.book, state.songKey, context)
          .map((tabContentList) {
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
                slivers: [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate.fixed(tabContentList),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
