import 'dart:convert';
import 'dart:io';

import 'package:enekeskonyv/settings_provider.dart';
import 'package:enekeskonyv/song/utils.dart';
import 'package:enekeskonyv/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Book supports the Erdelyi songbook key', () {
    expect(Book.fromName('21'), Book.blue);
    expect(Book.fromName('48'), Book.black);
    expect(Book.fromName('erdelyi'), Book.erdelyi);
    expect(Book.erdelyi.displayName, 'Erdélyi Református');
  });

  test('score rendering falls back to text for songs without score assets', () {
    expect(
      shouldRenderScore(
        scoreDisplay: ScoreDisplay.all,
        inCue: false,
        verseIndex: 0,
        hasScore: false,
      ),
      isFalse,
    );
    expect(
      shouldRenderScore(
        scoreDisplay: ScoreDisplay.first,
        inCue: false,
        verseIndex: 0,
        hasScore: false,
      ),
      isFalse,
    );
    expect(
      shouldRenderScore(
        scoreDisplay: ScoreDisplay.none,
        inCue: false,
        verseIndex: 0,
        hasScore: true,
      ),
      isFalse,
    );
    expect(
      shouldRenderScore(
        scoreDisplay: ScoreDisplay.first,
        inCue: false,
        verseIndex: 1,
        hasScore: true,
      ),
      isFalse,
    );
    expect(
      shouldRenderScore(
        scoreDisplay: ScoreDisplay.all,
        inCue: false,
        verseIndex: 1,
        hasScore: true,
      ),
      isTrue,
    );
  });

  test('legacy songbooks keep direct svg score lookups', () {
    songBooks = {
      '21': {
        '1': {
          'texts': ['1. Verse one'],
        },
      },
    };

    expect(getScoreAssetCandidates(Book.blue, '1', 0), [
      'assets/ref21/ref21-001-001.svg',
    ]);
  });

  test('erdelyi single-sheet song reuses score for all verses', () {
    songBooks = {
      'erdelyi': {
        '481': {
          'texts': ['1. First verse', '2. Second verse'],
          'scoreFiles': ['assets/referdelyi/referdelyi-481-001.png'],
        },
      },
    };

    expect(getScoreAssetCandidates(Book.erdelyi, '481', 0), [
      'assets/referdelyi/referdelyi-481-001.png',
    ]);
    expect(getScoreAssetCandidates(Book.erdelyi, '481', 1), [
      'assets/referdelyi/referdelyi-481-001.png',
    ]);
  });

  test('erdelyi multi-sheet song does not reuse verse one for later verses', () {
    songBooks = {
      'erdelyi': {
        '90': {
          'texts': ['1. First verse', '2. Second verse'],
          'scoreFiles': [
            'assets/referdelyi/referdelyi-090-v001.svg',
            'assets/referdelyi/referdelyi-090-v002.svg',
          ],
        },
      },
    };

    expect(getScoreAssetCandidates(Book.erdelyi, '90', 0), [
      'assets/referdelyi/referdelyi-090-v001.svg',
    ]);
    expect(getScoreAssetCandidates(Book.erdelyi, '90', 1), [
      'assets/referdelyi/referdelyi-090-v002.svg',
    ]);
  });

  test('verse-specific score pages still split the song by verse', () {
    songBooks = {
      'erdelyi': {
        '90': {
          'texts': ['1. First verse', '2. Second verse', '3. Third verse'],
          'scoreFiles': [
            'assets/referdelyi/referdelyi-090-v001.svg',
            'assets/referdelyi/referdelyi-090-v002.svg',
            'assets/referdelyi/referdelyi-090-v003.svg',
          ],
        },
      },
      '21': {
        '90': {
          'texts': ['1. First verse', '2. Second verse', '3. Third verse'],
        },
      },
    };

    expect(
      shouldSplitPagesByVerse(
        scoreDisplay: ScoreDisplay.all,
        inCue: false,
        hasScore: true,
        usesSingleScorePage: false,
      ),
      isTrue,
    );
  });

  test('cues page scoreless songs by verse, all-mode does not', () {
    // A cue element targets a specific verse, so verse paging stays on even
    // without a score (each verse gets a text page). In all-mode a scoreless
    // song is a single text page — paging would buy nothing and out-of-range
    // tab indices crash the controller.
    expect(
      shouldSplitPagesByVerse(
        scoreDisplay: ScoreDisplay.all,
        inCue: true,
        hasScore: false,
        usesSingleScorePage: false,
      ),
      isTrue,
    );
    expect(
      shouldSplitPagesByVerse(
        scoreDisplay: ScoreDisplay.all,
        inCue: false,
        hasScore: false,
        usesSingleScorePage: false,
      ),
      isFalse,
    );
    expect(
      shouldSplitPagesByVerse(
        scoreDisplay: ScoreDisplay.first,
        inCue: false,
        hasScore: true,
        usesSingleScorePage: false,
      ),
      isFalse,
    );
  });

  test('songUsesSingleScorePage detects single-sheet erdelyi songs', () {
    songBooks = {
      'erdelyi': {
        '91': {
          'texts': ['1. First verse', '2. Second verse'],
          'scoreFiles': ['assets/referdelyi/referdelyi-091-001.png'],
        },
        '90': {
          'texts': ['1. First verse', '2. Second verse'],
          'scoreFiles': [
            'assets/referdelyi/referdelyi-090-v001.svg',
            'assets/referdelyi/referdelyi-090-v002.svg',
          ],
        },
      },
      '21': {
        '1': {
          'texts': ['1. First verse'],
        },
      },
    };

    expect(songUsesSingleScorePage(Book.erdelyi, '91'), isTrue);
    expect(songUsesSingleScorePage(Book.erdelyi, '90'), isFalse);
    expect(songUsesSingleScorePage(Book.blue, '1'), isFalse);
  });

  test('shouldSupplementVerseTextForRepeatedScore returns true only for erdelyi single-sheet verses after verse 0', () {
    songBooks = {
      'erdelyi': {
        '91': {
          'texts': ['1. First verse', '2. Second verse'],
          'scoreFiles': ['assets/referdelyi/referdelyi-091-001.png'],
        },
        '90': {
          'texts': ['1. First verse', '2. Second verse'],
          'scoreFiles': [
            'assets/referdelyi/referdelyi-090-v001.svg',
            'assets/referdelyi/referdelyi-090-v002.svg',
          ],
        },
      },
      '21': {
        '1': {
          'texts': ['1. First verse', '2. Second verse'],
        },
      },
    };

    // Single-sheet erdelyi: only supplement for verse > 0
    expect(shouldSupplementVerseTextForRepeatedScore(Book.erdelyi, '91', 0), isFalse);
    expect(shouldSupplementVerseTextForRepeatedScore(Book.erdelyi, '91', 1), isTrue);
    // Multi-sheet erdelyi: never supplement
    expect(shouldSupplementVerseTextForRepeatedScore(Book.erdelyi, '90', 1), isFalse);
    // Non-erdelyi: never supplement
    expect(shouldSupplementVerseTextForRepeatedScore(Book.blue, '1', 1), isFalse);
  });

  test('song lookup helpers keep stable index and key mapping', () {
    songBooks = {
      'erdelyi': {
        '1': {
          'texts': ['1. First verse'],
        },
        '481': {
          'texts': ['1. Another verse'],
        },
        '504': {
          'texts': ['1. Last verse'],
        },
      },
    };

    expect(songKeyFor(Book.erdelyi, 1), '481');
    expect(songIndexFor(Book.erdelyi, '504'), 2);
  });

  test('bundled assets include the Erdelyi songbook import', () {
    final songbooks =
        jsonDecode(File('assets/enekeskonyv.json').readAsStringSync())
            as Map<String, dynamic>;
    final chapters =
        jsonDecode(File('assets/fejezetek.json').readAsStringSync())
            as Map<String, dynamic>;

    expect(songbooks['erdelyi'], isA<Map<String, dynamic>>());
    expect(chapters['erdelyi'], isA<Map<String, dynamic>>());

    final erdelyi = songbooks['erdelyi'] as Map<String, dynamic>;
    expect(erdelyi.length, 504);
    expect(erdelyi['1']['title'], 'Aki nem jár hitlenek tanácsán');
    expect(erdelyi['1']['texts'], isA<List<dynamic>>());
    expect(
      (erdelyi['1']['scoreFiles'] as List<dynamic>).length,
      (erdelyi['1']['texts'] as List<dynamic>).length,
    );
    expect(erdelyi['481']['title'], 'Tégy, Uram, engem áldássá');
    expect(erdelyi['481']['hasScore'], isTrue);
    expect(
      (erdelyi['481']['scoreFiles'] as List<dynamic>).length,
      (erdelyi['481']['texts'] as List<dynamic>).length,
    );
    expect(erdelyi['488']['title'], 'Áldásoddal megyünk');
    // 488 was confirmed absent from the printed source book — hasScore is
    // intentionally false rather than shipping an unrelated melody.
    expect(erdelyi['488']['hasScore'], isFalse);
    for (final songKey in ['219', '270', '271', '272', '274', '275', '427']) {
      expect(
        (erdelyi[songKey]['scoreFiles'] as List<dynamic>).length,
        (erdelyi[songKey]['texts'] as List<dynamic>).length,
      );
      expect(
        (erdelyi[songKey]['scoreFiles'] as List<dynamic>).first,
        contains('assets/referdelyi/referdelyi-${songKey.padLeft(3, '0')}-v001.svg'),
      );
    }
    expect(erdelyi['504']['title'], 'Áldjon meg téged');

    expect(chapters['erdelyi']['Erdélyi Református Énekeskönyv'], '1');
  });
}
