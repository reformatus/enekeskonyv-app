# Refactor plan - Overview
 - Főoldal: SongList-et mutat
 - Ének oldal: eeeh


# Refactor plan details (TBD!)
## class Verse
 - int id - Versszak száma
 - String text - Versszak szövege
 - Future\<Widget> sheet - Vershez tartozó kottát adja vissza. Amíg meg nem épül, throbber használható.

## class Song
 - constructor 1: Song(List\<Verse>)
 - constructor 2: Song.json(Map json)
 - int id - Ének száma az énekeskönyvben (pl '1')
 - String number - Ének száma meghatározással (pl '1. zsoltár')
 - String title - Ének címe (pl 'E földön ti minden népek')
 - Widget beforeText - Teljes 1. versszak előtt megjelenítendő rész, adott énekeskönyvhöz épül meg
 - Widget afterText - Teljes utolsó versszak utáni rész, ...
 - List\<Verse> - verses - Versszakok
 - nextVerseId ???
 - prevVerseId ??? needed?
 - List\<SongLink> links - Kapcsolódó énekek

## class SongList
 - constructor 1: SongList(List\<Song>)
 - constructor 2: SongList.json(Map json)
   - Továbbadja az egyes énekek építését on-demand a Song.json konstruktornak
 - List\<Song> songs - Tartalmazott összes ének
 - String? nextSongId - Következő ének száma (vagy null ha nincs ilyen)
 - String? prevSongId - Előző ének száma (vagy null ha nincs ilyen)
