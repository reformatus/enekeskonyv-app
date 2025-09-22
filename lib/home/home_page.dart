import 'dart:async';
import 'dart:collection';
import 'dart:convert' show json;
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../cues/cues_page.dart';
import '../cues/link.dart';
import '../quick_settings_dialog.dart';
import '../search_page.dart';
import '../settings_provider.dart';
import '../song/song_page.dart';
import '../utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> jsonSongBooks = {};
  late ScrollController scrollController;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (!mounted) return;
      final error = openAppLink(uri, context);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), duration: const Duration(seconds: 5)),
        );
      }
    });
  }

  Future<void> readJson() async {
    final String response = await rootBundle.loadString(
      'assets/enekeskonyv.json',
    );
    jsonSongBooks =
        (await compute(json.decode, response))
            as LinkedHashMap<String, dynamic>;
    songBooks = jsonSongBooks;
    setState(() {});
    initDeepLinks();
  }

  @override
  void initState() {
    super.initState();
    if (songBooks.isEmpty) readJson();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.initialized) {
          return Scaffold(appBar: AppBar(title: const Text('Betöltés...')));
        }

        final isIOS = Platform.isIOS;

        return Scaffold(
          body: (songBooks.isEmpty)
              ? CustomScrollView(
                  controller: scrollController,
                  physics: isIOS ? const BouncingScrollPhysics() : null,
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 59, // 56 (top) + thin bottom
                      toolbarHeight: 0,
                      automaticallyImplyLeading: false,
                      systemOverlayStyle: SystemUiOverlayStyle(
                        statusBarBrightness: settings.getCurrentAppBrightness(
                          context,
                        ),
                        statusBarIconBrightness:
                            settings.getCurrentAppBrightness(context) ==
                                Brightness.light
                            ? Brightness.dark
                            : Brightness.light,
                        systemNavigationBarColor: Theme.of(
                          context,
                        ).colorScheme.surface,
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        background: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Tooltip(
                                    message: 'Válassz énekeskönyvet',
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<Book>(
                                        value: settings.book,
                                        isExpanded: true,
                                        items: Book.values
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                  '${e.displayName} énekeskönyv',
                                                  overflow: TextOverflow.fade,
                                                  softWrap: false,
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) =>
                                            settings.changeBook(value!),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          const QuickSettingsDialog(),
                                    );
                                  },
                                  icon: const Icon(Icons.settings),
                                  tooltip: 'Beállítások',
                                  key: const Key(
                                    '_MyHomePageState.SettingsButton',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      bottom: const PreferredSize(
                        preferredSize: Size.fromHeight(3),
                        child: LinearProgressIndicator(),
                      ),
                    ),
                    const SliverFillRemaining(),
                  ],
                )
              : Scrollbar(
                  thickness: 10,
                  interactive: true,
                  radius: const Radius.circular(10),
                  controller: scrollController,
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: isIOS ? const BouncingScrollPhysics() : null,
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        floating: true,
                        expandedHeight: 105,
                        toolbarHeight: 0,
                        automaticallyImplyLeading: false,
                        systemOverlayStyle: SystemUiOverlayStyle(
                          statusBarBrightness: settings.getCurrentAppBrightness(
                            context,
                          ),
                          statusBarIconBrightness:
                              settings.getCurrentAppBrightness(context) ==
                                  Brightness.light
                              ? Brightness.dark
                              : Brightness.light,
                          systemNavigationBarColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          collapseMode: CollapseMode.parallax,
                          background: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 5,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Tooltip(
                                      message: 'Válassz énekeskönyvet',
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<Book>(
                                          value: settings.book,
                                          isExpanded: true,
                                          items: Book.values
                                              .map(
                                                (e) => DropdownMenuItem(
                                                  value: e,
                                                  child: Text(
                                                    '${e.displayName} énekeskönyv',
                                                    overflow: TextOverflow.fade,
                                                    softWrap: false,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) =>
                                              settings.changeBook(value!),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            const QuickSettingsDialog(),
                                      );
                                    },
                                    icon: const Icon(Icons.settings),
                                    tooltip: 'Beállítások',
                                    key: const Key(
                                      '_MyHomePageState.SettingsButton',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(58),
                          child: SafeArea(
                            top: false,
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Card(
                                      key: const Key(
                                        '_MyHomePageState.SearchSongButton',
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      elevation: 3,
                                      margin: const EdgeInsets.all(7),
                                      semanticContainer: true,
                                      child: InkWell(
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => SearchPage(
                                              book: settings.book,
                                              settingsProvider: settings,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.all(10),
                                              child: Icon(Icons.search),
                                            ),
                                            Text(
                                              'Keresés vagy ugrás...',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Kedvencek és listák',
                                    child: Card(
                                      margin: const EdgeInsets.only(
                                        top: 7,
                                        right: 7,
                                        bottom: 7,
                                      ),
                                      elevation: 3,
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CuesPage(context),
                                          ),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Center(
                                            child: Icon(Icons.star),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          return ListTile(
                            title: Text(
                              getSongTitle(
                                songBooks[settings
                                    .bookAsString][songBooks[settings
                                        .bookAsString]
                                    .keys
                                    .elementAt(i)],
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => SongPage(
                                    book: settings.book,
                                    songIndex: i,
                                  ),
                                ),
                              );
                            },
                            key: const Key('_MyHomePageState.ListTile'),
                          );
                        }, childCount: songBooks[settings.bookAsString].length),
                      ),
                    ],
                  ),
                ),
          key: const Key('_MyHomePageState'),
        );
      },
    );
  }
}
