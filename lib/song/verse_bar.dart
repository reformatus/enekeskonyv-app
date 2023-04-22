import 'package:enekeskonyv/settings_provider.dart';
import 'package:enekeskonyv/song/song_page_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerseBar extends StatelessWidget {
  const VerseBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, SongStateProvider>(
        builder: (context, settings, state, child) {
      return (settings.scoreDisplay == ScoreDisplay.all)
          ? Listener(
              // Making sure the verse bar is shown when the user
              // interacts with it.
              onPointerHover: (_) => state.showThenHideVerseBar(),
              onPointerMove: (_) => state.showThenHideVerseBar(),
              child: SizedBox(
                height: 50,
                child: Row(
                  children: [
                    // Empty box to make the tab bar centered
                    const SizedBox(width: 50),
                    Expanded(
                      child: Center(
                        child: Card(
                          elevation: 3,
                          // The tab bar is animated so that when the number
                          // of verses changes, the tab bar will be resized
                          // to fit the new number of verses with an animation.
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            child: TabBar(
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              isScrollable: true,
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              automaticIndicatorColorAdjustment: false,
                              controller: state.tabController,
                              tabs: [
                                for (var i = 0;
                                    i < state.tabController.length;
                                    i++)
                                  // Get the verse number from the text itself.
                                  // The 48 book skips some verses.
                                  Tab(
                                    text: songBooks[state.book.name]
                                            [state.songKey]['texts'][i]
                                        .split('.')[0],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Pin button
                    IconButton(
                        onPressed: () => settings
                            .changeIsVerseBarPinned(!settings.isVerseBarPinned),
                        icon: const Icon(Icons.push_pin),
                        color: settings.isVerseBarPinned
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).disabledColor)
                  ],
                ),
              ),
            )
          : Container();
    });
  }
}
