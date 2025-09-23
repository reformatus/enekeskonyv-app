import 'dart:collection';

import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock test environment for the Énekeskönyv app
/// Sets up common test fixtures and mock data
class MockTestEnvironment {
  /// Set up the test environment with mock asset bundles
  static void setUp() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        return null;
      },
    );

    // Mock asset bundle for loading song data
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter/assets'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'loadString' &&
            methodCall.arguments == 'assets/enekeskonyv.json') {
          return _getMockSongBooksJson();
        }
        if (methodCall.method == 'loadString' &&
            methodCall.arguments == 'assets/fejezetek.json') {
          return _getMockChaptersJson();
        }
        return null;
      },
    );

    // Mock wakelock
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/wakelock_plus'),
      (MethodCall methodCall) async {
        return true;
      },
    );

    // Mock app links
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/messages'),
      (MethodCall methodCall) async {
        return null;
      },
    );

    // Mock package info
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info_plus'),
      (MethodCall methodCall) async {
        return {
          'appName': 'Énekeskönyv',
          'packageName': 'hu.reflabs.enekeskonyv',
          'version': '3.2.0',
          'buildNumber': '55',
        };
      },
    );

    // Set up global songBooks with mock data
    songBooks = _createMockSongBooksMap();
  }

  /// Clean up the test environment
  static void tearDown() {
    songBooks.clear();
    
    // Reset method call handlers
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      null,
    );
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter/assets'),
      null,
    );
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/wakelock_plus'),
      null,
    );
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/messages'),
      null,
    );
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info_plus'),
      null,
    );
  }

  /// Create mock song books data structure
  static Map<String, dynamic> _createMockSongBooksMap() {
    return {
      '21': LinkedHashMap<String, dynamic>.from({
        '1': {
          'title': 'Aki nem jár hitlenek tanácsán',
          'number': '1',
          'texts': [
            '1. Aki nem jár hitlenek tanácsán, bűnösök útján meg nem áll',
            '2. Hanem az Úr törvényében gyönyörködik',
            '3. És az ő törvényén gondolkodik éjjel és nappal',
            '4. Olyan lesz, mint a folyóvizek mellé ültetett fa',
          ],
          'markdown': null,
        },
        '2': {
          'title': 'Miért zúgolódnak a pogányok?',
          'number': '2',
          'texts': [
            '1. Miért zúgolódnak a pogányok?',
            '2. És miért gondolnak hiábavalóságot a népek?',
            '3. A föld királyai felállanak',
          ],
          'markdown': null,
        },
        '3': {
          'title': 'Úr, mily sokasodtak ellenségeim!',
          'number': '3',
          'texts': [
            '1. Úr, mily sokasodtak ellenségeim!',
            '2. Sokan vannak, akik ellenem támadnak',
          ],
          'markdown': null,
        }
      }),
      '48': LinkedHashMap<String, dynamic>.from({
        '1': {
          'title': 'Dicsőség legyen az Atyának',
          'number': '1',
          'texts': [
            '1. Dicsőség legyen az Atyának és a Fiúnak és a Szentlélek Istennek',
          ],
          'markdown': null,
        },
        '2': {
          'title': 'Jöjj, Szentlélek Úristen',
          'number': '2',
          'texts': [
            '1. Jöjj, Szentlélek Úristen, töltsd be híveid szívét',
            '2. És gerjesd fel őbennük a te szeretetednek tüzét',
          ],
          'markdown': null,
        }
      })
    };
  }

  /// Get mock song books JSON string
  static String _getMockSongBooksJson() {
    return '''
    {
      "21": {
        "1": {
          "title": "Aki nem jár hitlenek tanácsán",
          "number": "1",
          "texts": [
            "1. Aki nem jár hitlenek tanácsán, bűnösök útján meg nem áll",
            "2. Hanem az Úr törvényében gyönyörködik",
            "3. És az ő törvényén gondolkodik éjjel és nappal",
            "4. Olyan lesz, mint a folyóvizek mellé ültetett fa"
          ]
        },
        "2": {
          "title": "Miért zúgolódnak a pogányok?",
          "number": "2",
          "texts": [
            "1. Miért zúgolódnak a pogányok?",
            "2. És miért gondolnak hiábavalóságot a népek?",
            "3. A föld királyai felállanak"
          ]
        }
      },
      "48": {
        "1": {
          "title": "Dicsőség legyen az Atyának",
          "number": "1",
          "texts": [
            "1. Dicsőség legyen az Atyának és a Fiúnak és a Szentlélek Istennek"
          ]
        }
      }
    }
    ''';
  }

  /// Get mock chapters JSON string
  static String _getMockChaptersJson() {
    return '''
    {
      "21": [
        {"title": "Zsoltárok", "start": 1, "end": 150}
      ],
      "48": [
        {"title": "Dicsőítő énekek", "start": 1, "end": 100}
      ]
    }
    ''';
  }
}