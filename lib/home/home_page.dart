import 'dart:async';
import 'dart:collection';
import 'dart:convert' show json;
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:enekeskonyv/home/chapter_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../cues/cues_page.dart';
import '../cues/link.dart';
import '../error_handler.dart';
import '../error_test_widget.dart';
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

  // Collect controllers of all chapter ExpansionTiles currently in the tree
  final List<_ChapterControllerRef> _chapterControllers = [];
  // All chapter titles for the current book; used for bulk state updates
  List<String> _allChapterTitles = [];

  void _registerChapterController(
    ExpansibleController controller,
    String title,
  ) {
    _chapterControllers.add(_ChapterControllerRef(controller, title));
  }

  void _unregisterChapterController(ExpansibleController controller) {
    _chapterControllers.removeWhere((e) => e.controller == controller);
  }

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
    try {
      final String response = await rootBundle.loadString(
        'assets/enekeskonyv.json',
      );
      
      try {
        jsonSongBooks = (await compute(json.decode, response)) as LinkedHashMap<String, dynamic>;
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
            message: 'A fejezetek betöltése nem sikerült, de az énekek továbbra is elérhetők.',
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
          message: 'Az énekeskönyv adatainak betöltése sikertelen. Ellenőrizze az alkalmazás telepítését.',
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
        if (!settings.initialized) {
          return Scaffold(appBar: AppBar(title: const Text('Betöltés...')));
        }

        final isIOS = Platform.isIOS;

        if (songBooks.isEmpty) {
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Énekeskönyvek betöltése...',
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

        // Update cached chapter titles for current book
        _allChapterTitles = _collectChapterTitlesForBook(settings.bookAsString);

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
                                  final settings = SettingsProvider.of(context);
                                  final bookKey = settings.bookAsString;
                                  final anyClosed = _chapterControllers.any(
                                    (e) => !settings.getIsChapterExpanded(
                                      bookKey,
                                      e.title,
                                    ),
                                  );
                                  final targetOpen = anyClosed;
                                  // Persist for all chapters (including off-screen)
                                  settings.setAllChaptersExpandedState(
                                    settings.book,
                                    targetOpen,
                                    _allChapterTitles,
                                  );
                                  // Update visible controllers
                                  for (final ref in _chapterControllers) {
                                    if (targetOpen) {
                                      ref.controller.expand();
                                    } else {
                                      ref.controller.collapse();
                                    }
                                  }
                                  setState(() {});
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Builder(
                                    builder: (context) {
                                      final settings = SettingsProvider.of(
                                        context,
                                      );
                                      final bookKey = settings.bookAsString;
                                      final anyClosed = _chapterControllers.any(
                                        (e) => !settings.getIsChapterExpanded(
                                          bookKey,
                                          e.title,
                                        ),
                                      );
                                      return Icon(
                                        anyClosed
                                            ? Icons.unfold_more
                                            : Icons.unfold_less,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Search card (center, expands)
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                          // Favorites button (right)
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
                  registerController: _registerChapterController,
                  unregisterController: _unregisterChapterController,
                ),
              ),
            ],
          ),
          key: const Key('_MyHomePageState'),
        );
      },
    );
  }
}

List<Widget> buildHomepageItems(
  List<HomePageItem> items,
  SettingsProvider settings, {
  int initialDepth = 0,
  void Function(ExpansibleController controller, String title)?
  registerController,
  void Function(ExpansibleController controller)? unregisterController,
}) {
  final widgets = items
      .map<Iterable<Widget>>(
        (e) => switch (e) {
          HomePageChapterItem chapter => [
            HomePageChapterWidget(
              chapter,
              settings,
              depth: initialDepth,
              registerController: registerController,
              unregisterController: unregisterController,
            ),
          ],
          HomePageSongsItem songs => songs.songKeys.map(
            (k) => HomePageSongWidget(k, settings),
          ),
        },
      )
      .reduce((j, k) => j.followedBy(k))
      .toList();

  // Add error test widget in debug mode only at the top level
  if (kDebugMode && initialDepth == 0) {
    widgets.insert(0, const ErrorTestWidget());
  }

  return widgets;
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
    this.registerController,
    this.unregisterController,
    super.key,
  });
  final HomePageChapterItem chapterItem;
  final SettingsProvider settings;
  final int depth;
  final void Function(ExpansibleController controller, String title)?
  registerController;
  final void Function(ExpansibleController controller)? unregisterController;

  @override
  State<HomePageChapterWidget> createState() => _HomePageChapterWidgetState();
}

class _HomePageChapterWidgetState extends State<HomePageChapterWidget> {
  late final ExpansibleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExpansibleController();
    widget.registerController?.call(_controller, widget.chapterItem.title);
  }

  @override
  void dispose() {
    widget.unregisterController?.call(_controller);
    super.dispose();
  }

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
                  1 &&
              (widget.chapterItem.children.first as HomePageSongsItem)
                      .songKeys
                      .first ==
                  widget.chapterItem.title)
          ? HomePageSongWidget(widget.chapterItem.title, widget.settings)
          : ExpansionTile(
              key: ValueKey(
                'chapter-${widget.settings.bookAsString}-${widget.chapterItem.title}',
              ),
              controller: _controller,
              shape: Border(),
              visualDensity: VisualDensity.compact,
              initiallyExpanded: widget.settings.getIsChapterExpanded(
                widget.settings.bookAsString,
                widget.chapterItem.title,
              ),
              title: Row(
                children: [
                  Expanded(child: Text(widget.chapterItem.title)),
                  if (widget.chapterItem.startingSongKey != null &&
                      widget.chapterItem.startingSongKey!.length < 7)
                    Padding(
                      padding: EdgeInsetsGeometry.only(left: 5),
                      child: Text(
                        widget.chapterItem.startingSongKey!,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
              onExpansionChanged: (isOpen) {
                widget.settings.setChapterExpandedState(
                  widget.settings.book,
                  widget.chapterItem.title,
                  isOpen,
                );
              },
              children: buildHomepageItems(
                widget.chapterItem.children,
                widget.settings,
                initialDepth: widget.depth + 1,
                registerController: widget.registerController,
                unregisterController: widget.unregisterController,
              ),
            ),
    );
  }
}

class _ChapterControllerRef {
  _ChapterControllerRef(this.controller, this.title);
  final ExpansibleController controller;
  final String title;
}

// Utility: collect all chapter titles recursively for a given book
List<String> _collectChapterTitlesForItems(List<HomePageItem> items) {
  final titles = <String>[];
  for (final item in items) {
    if (item is HomePageChapterItem) {
      titles.add(item.title);
      titles.addAll(_collectChapterTitlesForItems(item.children));
    }
  }
  return titles;
}

List<String> _collectChapterTitlesForBook(String bookKey) {
  final tree = chapterTree[bookKey] ?? const <HomePageItem>[];
  return _collectChapterTitlesForItems(tree);
}
