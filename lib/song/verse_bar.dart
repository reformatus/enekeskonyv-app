import '../settings_provider.dart';
import 'song_page_state.dart';
import '../util.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerseBar extends StatefulWidget {
  const VerseBar({super.key});

  @override
  State<VerseBar> createState() => _VerseBarState();
}

class _VerseBarState extends State<VerseBar> {
  bool startArrow = false;
  bool endArrow = false;
  late ScrollController scrollController;

  updateEndArrows(position) {
    setState(() {
      // Only show if verse bar can be scrolled left.
      // If it's at the left edge, it can't be scrolled left.
      startArrow = position.pixels != 0;

      // Only show if verse bar can be scrolled right.
      // If it's at the right edge, it can't be scrolled right.
      endArrow = position.maxScrollExtent > position.pixels;
    });
  }

  @override
  void initState() {
    scrollController = ScrollController();
    scrollController.addListener(() {
      updateEndArrows(scrollController.position);
    });
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateEndArrows(scrollController.position);
      SongStateProvider.of(context).scrollVerseBarToCurrent(animate: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, SongStateProvider>(
        builder: (context, settings, state, child) {
      if (settings.scoreDisplay == ScoreDisplay.all || state.inCue) {
        return Listener(
          // Making sure the verse bar is shown when the user
          // interacts with it.
          onPointerHover: (_) => state.showThenHideVerseBar(),
          onPointerMove: (_) => state.showThenHideVerseBar(),
          child: SizedBox(
            height: 50,
            child: Row(
              children: [
                // Favourite button
                SizedBox(
                  width: 40,
                  child: settings.getIsInSelectedCue(
                          getVerseId(state.book, state.songKey, state.verse))
                      ? IconButton(
                          tooltip: 'Versszak törlése a kiválasztott listából',
                          onPressed: () {
                            settings.removeAllInstancesFromCue(
                                settings.selectedCue,
                                getVerseId(
                                    state.book, state.songKey, state.verse));
                            if (state.inCue) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.star),
                          color: Theme.of(context).colorScheme.secondary,
                        )
                      : IconButton(
                          tooltip:
                              'Versszak hozzáadása a kiválasztott listához',
                          onPressed: () => settings.addToCue(
                              settings.selectedCue,
                              getVerseId(
                                  state.book, state.songKey, state.verse)),
                          icon: const Icon(Icons.star_border),
                          color: Theme.of(context).disabledColor),
                ),
                if (state.tabs.length > 1 && settings.isVerseBarEnabled) ...[
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.passthrough,
                      children: [
                        Center(
                          child: FadingEdgeScrollView.fromSingleChildScrollView(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              scrollDirection: Axis.horizontal,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                                clipBehavior: Clip.antiAlias,
                                child: TabBar(
                                  indicator: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                  ),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  dividerColor: Colors.transparent,
                                  labelPadding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  automaticIndicatorColorAdjustment: false,
                                  controller: state.tabController,
                                  isScrollable: true,
                                  tabs: state.tabs,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: startArrow ? 1 : 0,
                              child: Icon(
                                Icons.chevron_left,
                                color: Theme.of(context).disabledColor,
                                size: 17,
                              )),
                        ),
                        Positioned(
                          right: 0,
                          child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: endArrow ? 1 : 0,
                              child: Icon(
                                Icons.chevron_right,
                                color: Theme.of(context).disabledColor,
                                size: 17,
                              )),
                        ),
                      ],
                    ),
                  ),

                  // Pin button
                  SizedBox(
                    width: 40,
                    child: IconButton(
                        tooltip: 'Versválasztó sáv rögzítése',
                        onPressed: () => settings
                            .changeIsVerseBarPinned(!settings.isVerseBarPinned),
                        icon: settings.isVerseBarPinned
                            ? const Icon(Icons.push_pin)
                            : const Icon(Icons.push_pin_outlined),
                        color: settings.isVerseBarPinned
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).disabledColor),
                  ),
                ]
              ],
            ),
          ),
        );
      } else {
        return const SizedBox();
      }
    });
  }
}
