import 'package:enekeskonyv/settings_provider.dart';
import 'package:enekeskonyv/song/song_page_state.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerseBar extends StatefulWidget {
  const VerseBar({super.key});

  @override
  State<VerseBar> createState() => _VerseBarState();
}

class _VerseBarState extends State<VerseBar> {
  bool startEllipsis = false;
  bool endEllipsis = false;
  late ScrollController scrollController;

  updateEndEllipsies(position) {
    if (position.atEdge) {
      setState(() {
        startEllipsis = position.pixels == 0 ? false : true;
        endEllipsis =
            !startEllipsis && position.maxScrollExtent > position.pixels;
      });
    } else {
      setState(() {
        startEllipsis = true;
        endEllipsis = true;
      });
    }
  }

  @override
  void initState() {
    scrollController = ScrollController();
    scrollController.addListener(() {
      updateEndEllipsies(scrollController.position);
    });
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateEndEllipsies(scrollController.position);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, SongStateProvider>(
        builder: (context, settings, state, child) {
      if ((settings.scoreDisplay == ScoreDisplay.all)) {
        return Listener(
          // Making sure the verse bar is shown when the user
          // interacts with it.
          onPointerHover: (_) => state.showThenHideVerseBar(),
          onPointerMove: (_) => state.showThenHideVerseBar(),
          child: SizedBox(
            height: 50,
            child: Row(
              children: [
                // Empty box to make the tab bar centered
                const SizedBox(width: 40),
                AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: startEllipsis ? 1 : 0,
                    child: Icon(Icons.chevron_left,
                        color: Theme.of(context).disabledColor)),
                Expanded(
                  child: Center(
                    child: FadingEdgeScrollView.fromSingleChildScrollView(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        child: Card(
                          elevation: 3,
                          child: TabBar(
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            automaticIndicatorColorAdjustment: false,
                            controller: state.tabController,
                            isScrollable: true,
                            tabs: state.tabs,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: endEllipsis ? 1 : 0,
                    child: Icon(Icons.chevron_right,
                        color: Theme.of(context).disabledColor)),
                // Pin button
                SizedBox(
                  width: 40,
                  child: IconButton(
                      onPressed: () => settings
                          .changeIsVerseBarPinned(!settings.isVerseBarPinned),
                      icon: const Icon(Icons.push_pin),
                      color: settings.isVerseBarPinned
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).disabledColor),
                )
              ],
            ),
          ),
        );
      } else {
        return Container();
      }
    });
  }
}
