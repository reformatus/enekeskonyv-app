import 'dart:collection';

import 'package:enekeskonyv/settings_provider.dart';
import 'package:enekeskonyv/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Utils Tests', () {
    setUp(() {
      // Set up mock songBooks data for testing
      songBooks = {
        '21': {
          '1': {
            'title': 'Aki nem jár hitlenek tanácsán',
            'number': '1',
            'texts': [
              '1. Aki nem jár hitlenek tanácsán, bűnösök útján meg nem áll',
              '2. Hanem az Úr törvényében gyönyörködik',
            ]
          },
          '2': {
            'title': 'Miért zúgolódnak a pogányok?',
            'number': '2',
            'texts': [
              '1. Miért zúgolódnak a pogányok?',
              '2. És miért gondolnak hiábavalóságot a népek?',
            ]
          }
        },
        '48': {
          '1': {
            'title': 'Dicsőség legyen az Atyának',
            'number': '1',
            'texts': [
              '1. Dicsőség legyen az Atyának',
            ]
          }
        }
      };
    });

    tearDown(() {
      songBooks.clear();
    });

    group('getSongTitle', () {
      test('should return title with number when number exists', () {
        final song = LinkedHashMap<String, dynamic>.from({
          'title': 'Aki nem jár hitlenek tanácsán',
          'number': '1'
        });

        final result = getSongTitle(song);

        expect(result, equals('1: Aki nem jár hitlenek tanácsán'));
      });

      test('should return only title when number is null', () {
        final song = LinkedHashMap<String, dynamic>.from({
          'title': 'Test Song'
        });

        final result = getSongTitle(song);

        expect(result, equals('Test Song'));
      });
    });

    group('getVerseId', () {
      test('should generate correct verse ID format', () {
        final result = getVerseId(Book.blue, '1', 0);

        expect(result, equals('21.1.0'));
      });

      test('should handle different books correctly', () {
        final blueResult = getVerseId(Book.blue, '5', 2);
        final blackResult = getVerseId(Book.black, '10', 1);

        expect(blueResult, equals('21.5.2'));
        expect(blackResult, equals('48.10.1'));
      });
    });

    group('parseVerseId', () {
      test('should parse valid verse ID correctly', () {
        final result = parseVerseId('21.1.0');

        expect(result.book, equals(Book.blue));
        expect(result.songKey, equals('1'));
        expect(result.verseIndex, equals(0));
      });

      test('should parse verse ID for different book', () {
        final result = parseVerseId('48.1.0');

        expect(result.book, equals(Book.black));
        expect(result.songKey, equals('1'));
        expect(result.verseIndex, equals(0));
      });

      test('should throw when songBooks is empty', () {
        songBooks.clear();

        expect(
          () => parseVerseId('21.1.0'),
          throwsA(contains('Énekeskönyv nincs betöltve')),
        );
      });

      test('should throw when verse ID has insufficient parts', () {
        expect(
          () => parseVerseId('21.1'),
          throwsA(contains('Könyv, ének vagy versszak nincs megadva')),
        );
      });

      test('should throw when book is not found', () {
        expect(
          () => parseVerseId('99.1.0'),
          throwsA(contains('Könyv nem található')),
        );
      });

      test('should throw when song key is not found', () {
        expect(
          () => parseVerseId('21.999.0'),
          throwsA(contains('Ének nem található')),
        );
      });

      test('should throw when verse index is invalid', () {
        expect(
          () => parseVerseId('21.1.abc'),
          throwsA(contains('Versszakszám érvénytelen')),
        );
      });

      test('should throw when verse index is out of bounds', () {
        expect(
          () => parseVerseId('21.1.999'),
          throwsA(contains('Versszak nem található')),
        );
      });
    });

    group('songKeyFor', () {
      test('should return correct song key for given index', () {
        final result = songKeyFor(Book.blue, 0);

        expect(result, equals('1'));
      });

      test('should return correct song key for second index', () {
        final result = songKeyFor(Book.blue, 1);

        expect(result, equals('2'));
      });
    });

    group('songIndexFor', () {
      test('should return correct index for given song key', () {
        final result = songIndexFor(Book.blue, '1');

        expect(result, equals(0));
      });

      test('should return correct index for second song', () {
        final result = songIndexFor(Book.blue, '2');

        expect(result, equals(1));
      });

      test('should return -1 for non-existent song key', () {
        final result = songIndexFor(Book.blue, '999');

        expect(result, equals(-1));
      });
    });
  });
}