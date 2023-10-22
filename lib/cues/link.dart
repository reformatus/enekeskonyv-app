import 'package:enekeskonyv/cues/cues_page.dart';
import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../song/song_page.dart';
import '../utils.dart';

String? openAppLink(Uri uri, BuildContext context) {
  if (uri.host != 'reflabs.hu' || uri.queryParameters.isEmpty) {
    // When link is without a path, it's a link to the app itself.
    // Also app won't get launched if the host is not the expected one, so
    // that check is just to be sure.
    return null;
  }

  switch (uri.queryParameters.keys.first) {
    case 's': // Song
      Verse verse;
      try {
        verse = parseVerseId(uri.queryParameters['s']!);
      } catch (e) {
        return 'Helytelen link: $e';
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return SongPage(
              book: verse.book,
              songIndex: verse.songIndex,
              verseIndex: verse.verseIndex,
            );
          },
        ),
      );
      return null;
    case 'c': // Cue
      var settings = SettingsProvider.of(context);

      List<String> parts;

      try {
        parts = uri.queryParameters['c']!.split(',');
      } catch (e) {
        return 'Helytelen link: Lista formátum nem megfelelő.';
      }

      String cueName;
      try {
        cueName = parts[0];
      } catch (e) {
        return 'Helytelen link: Listanév hiányzik vagy érvénytelen';
      }

      int i = 2;
      if (settings.cueStore.keys.contains(cueName)) {
        while (settings.cueStore.keys.contains('$cueName-$i')) {
          i++;
        }
        cueName = '$cueName-$i';
      }

      List<String> cueContent;
      cueContent = parts.sublist(1);
      if (cueContent.isEmpty) return 'Helytelen link: Üres lista';

      for (var element in cueContent) {
        try {
          parseVerseId(element);
        } catch (e) {
          return 'Helytelen link: Lista érvénytelen versszakot tartalmaz:\n"$element" - $e';
        }
      }
      settings.saveCue(cueName, cueContent);
      settings.changeSelectedCue(cueName);

      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => CuesPage(context)));

      return null;
    default:
      return 'Helytelen link: Ismeretlen parancs.';
  }
}

Future showShareDialog(BuildContext context, String title,
    {List<String>? cueContent, String? verseId}) {
  String linkToShare;

  if (cueContent == null) {
    linkToShare = 'https://reflabs.hu/?s=$verseId';
  } else {
    linkToShare = 'https://reflabs.hu/?c=${[title, ...cueContent].join(',')}';
  }

  return showDialog(
    context: context,
    builder: (BuildContext context) => SimpleDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text('$title megosztása')),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      titlePadding: const EdgeInsets.only(left: 25, top: 15, right: 15),
      contentPadding: const EdgeInsets.all(25),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: QrImageView(
                data: linkToShare,
                version: QrVersions.auto,
                eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: Theme.of(context).colorScheme.secondary),
                dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Theme.of(context).colorScheme.secondary),
                gapless: false,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              linkToShare,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                ElevatedButton.icon(
                  label: const Text('Megosztás'),
                  onPressed: () => Share.share(linkToShare),
                  icon: const Icon(Icons.share),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  label: const Text('Másolás'),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: linkToShare)),
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
