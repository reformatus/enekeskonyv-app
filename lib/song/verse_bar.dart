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
      return SizedBox(
        height: 50,
        child: Row(
          children: [
            // Empty box to make the tab bar centered
            const SizedBox(width: 40),
            Expanded(
              child: Center(
                child: Card(
                  elevation: 5,
                  child: AnimatedSize(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: TabBar(
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      isScrollable: true,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                      automaticIndicatorColorAdjustment: false,
                      controller: state.tabController,
                      tabs: [
                        for (var i = 0; i < state.tabController.length; i++)
                          Tab(
                            text: songBooks[state.book.name][state.songKey]
                                    ['texts'][i]
                                .split('.')[0],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
                onPressed: () =>
                    settings.changeIsVerseBarPinned(!settings.isVerseBarPinned),
                icon: const Icon(Icons.push_pin),
                color: settings.isVerseBarPinned
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).disabledColor)
          ],
        ),
      );
    });
  }
}
