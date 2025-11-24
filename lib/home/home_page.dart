import 'dart:async';
import 'dart:collection';
import 'dart:convert' show json;
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:enekeskonyv/home/chapter_utils.dart';
import 'package:enekeskonyv/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../cues/cues_page.dart';
import '../cues/link.dart';
import '../news/news_dialog.dart';
import '../news/news_service.dart';
import '../error_handler.dart';
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
  bool _newsChecked = false;

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

  Future<void> checkAndShowNews() async {
    if (_newsChecked || !mounted) return;
    _newsChecked = true;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.initialized) return;

    try {
      final allNews = await NewsService.fetchNews();
      final unreadNews = NewsService.getUnreadNews(
        allNews,
        settings.readNewsIds,
      );

      if (unreadNews.isNotEmpty && mounted) {
        // Wait a bit to ensure the UI is fully built
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          await NewsOverlay.showNewsSequence(
            context,
            unreadNews,
            (newsId) => settings.markNewsAsRead(newsId),
          );
        }
      }
    } catch (e) {
      // Silently handle any errors - news functionality should not break the app
    }
  }

  Future<void> readJson() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/enekeskonyv.json',
      );

      try {
        jsonSongBooks =
            (await compute(json.decode, response))
                as LinkedHashMap<String, dynamic>;
      } catch (e, s) {
        if (mounted) {
          await GlobalErrorHandler.handleDataError(
            context: context,
            error: e,
            stackTrace: s,
          );
        }
        return;
      }

      songBooks = jsonSongBooks;

      try {
        chapterTree = await getHomeChapterTree();
      } catch (e, s) {
        if (mounted) {
          await GlobalErrorHandler.handleError(
            context: context,
            title: 'Fejezetek betöltési hiba',
            message:
                'A fejezetek betöltése nem sikerült. Ellenőrizze az alkalmazás telepítését.',
            error: e,
            stackTrace: s,
          );
        }
        // Continue without chapter tree
      }

      if (mounted) {
        setState(() {});
        initDeepLinks();
      }
    } catch (e, s) {
      if (mounted) {
        await GlobalErrorHandler.handleError(
          context: context,
          title: 'Énekeskönyv betöltési hiba',
          message:
              'Az énekeskönyv adatainak betöltése sikertelen. Ellenőrizze az alkalmazás telepítését.',
          error: e,
          stackTrace: s,
        );
      }
    }
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
        final isIOS = Platform.isIOS;

        if (!settings.initialized || songBooks.isEmpty) {
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      songBooks.isEmpty
                          ? 'Énekeskönyvek betöltése...'
                          : 'Beállítások betöltése...',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        }

        // Schedule news check after the main UI is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          checkAndShowNews();
        });

        return Scaffold(
          body: CustomScrollView(
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
                      padding: const EdgeInsets.only(left: 16, right: 5),
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
                                              fontWeight: FontWeight.normal,
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
                            key: const Key('_MyHomePageState.SettingsButton'),
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
                          // Toggle-all button on the left
                          Tooltip(
                            message: 'Összes nyit/zár',
                            child: Card(
                              margin: const EdgeInsets.only(
                                top: 7,
                                left: 7,
                                bottom: 7,
                              ),
                              elevation: 3,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  final settings =
                                      Provider.of<SettingsProvider>(
                                        context,
                                        listen: false,
                                      );
                                  settings.changeChaptersExpanded(
                                    !settings.chaptersExpanded,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Builder(
                                    builder: (context) {
                                      final settings =
                                          Provider.of<SettingsProvider>(
                                            context,
                                          );
                                      return Icon(
                                        settings.chaptersExpanded
                                            ? Icons.unfold_less
                                            : Icons.unfold_more,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Search card (center, expands)
                          Expanded(
                            child: Hero(
                              tag: 'searchbutton',
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
                          ),
                          // Favorites button (right)
                          Tooltip(
                            message: 'Kedvencek és listák',
                            child: Hero(
                              tag: 'favouritesbutton',
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
                                      builder: (context) => CuesPage(context),
                                    ),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Center(child: Icon(Icons.star)),
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
              SliverList.list(
                children: buildHomepageItems(
                  chapterTree[settings.bookAsString]!,
                  settings,
                ).followedBy([SizedBox(height: 20)]).toList(),
              ),
            ],
          ),
          key: scaffoldKey,
        );
      },
    );
  }
}

List<Widget> buildHomepageItems(
  List<HomePageItem> items,
  SettingsProvider settings, {
  int initialDepth = 0,
}) {
  return items
      .map<Iterable<Widget>>(
        (e) => switch (e) {
          HomePageChapterItem chapter => [
            HomePageChapterWidget(chapter, settings, depth: initialDepth),
          ],
          HomePageSongsItem songs => songs.songKeys.map(
            (k) => HomePageSongWidget(k, settings),
          ),
        },
      )
      .reduce((j, k) => j.followedBy(k))
      .toList();
}

class HomePageSongWidget extends StatelessWidget {
  const HomePageSongWidget(this.songKey, this.settings, {super.key});
  final String songKey;
  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(getSongTitle(songBooks[settings.bookAsString][songKey])),
      dense: true,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                SongPage(book: settings.book, songKey: songKey),
          ),
        );
      },
      key: const Key('_MyHomePageState.ListTile'),
    );
  }
}

class HomePageChapterWidget extends StatefulWidget {
  const HomePageChapterWidget(
    this.chapterItem,
    this.settings, {
    required this.depth,
    super.key,
  });
  final HomePageChapterItem chapterItem;
  final SettingsProvider settings;
  final int depth;

  @override
  State<HomePageChapterWidget> createState() => _HomePageChapterWidgetState();
}

class _HomePageChapterWidgetState extends State<HomePageChapterWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: switch (widget.depth) {
        0 => 0.0,
        1 => 1.0,
        2 => 6.0,
        3 => 12.0,
        _ => 20.0,
      },
      shadowColor: Colors.transparent,
      surfaceTintColor: Theme.of(context).colorScheme.onPrimaryContainer,
      borderOnForeground: true,
      child:
          (widget.chapterItem.children.length == 1 &&
              widget.chapterItem.children.first is HomePageSongsItem &&
              (widget.chapterItem.children.first as HomePageSongsItem)
                      .songKeys
                      .length ==
                  1)
          ? HomePageSongWidget(
              widget.chapterItem.children.first.startingSongKey!,
              widget.settings,
            )
          : ExpansionTile(
              key: ValueKey(
                'chapter-${widget.settings.bookAsString}-${widget.settings.chaptersExpanded}-${widget.chapterItem.title}',
              ),
              shape: Border(),
              visualDensity: VisualDensity.compact,
              initiallyExpanded: widget.settings.chaptersExpanded,
              title: Row(
                children: [
                  Expanded(child: Text(widget.chapterItem.title)),
                  if (widget.chapterItem.startingSongKey != null &&
                      widget.chapterItem.startingSongKey!.length <= 3)
                    Padding(
                      padding: EdgeInsetsGeometry.only(left: 5),
                      child: Text(
                        widget.chapterItem.startingSongKey!,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
              children: buildHomepageItems(
                widget.chapterItem.children,
                widget.settings,
                initialDepth: widget.depth + 1,
              ),
            ),
    );
  }
}
