import 'package:enekeskonyv/settings_provider.dart';
import 'package:enekeskonyv/song/state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerseBar extends StatelessWidget {
  const VerseBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SongStateProvider>(builder: (context, state, child) {
      return Card(
        elevation: 5,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: SizedBox(
            height: 50,
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
                    text: songBooks[state.book.name][state.songKey]['texts'][i]
                        .split('.')[0],
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
