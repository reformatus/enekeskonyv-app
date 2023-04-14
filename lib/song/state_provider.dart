import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class SongStateProvider extends ChangeNotifier {
  int _song;
  int _verse;
  ScrollController scrollController = ScrollController();

  SongStateProvider({
    required int song,
    required int verse,
  })  : _song = song,
        _verse = verse;

  static SongStateProvider of(BuildContext context) {
    return Provider.of<SongStateProvider>(context, listen: false);
  }
}
