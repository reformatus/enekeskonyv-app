import 'package:flutter_test/flutter_test.dart';

// Import all test files to run them together
import 'unit/utils_test.dart' as utils_tests;
import 'unit/settings_provider_test.dart' as settings_tests;
import 'unit/link_test.dart' as link_tests;
import 'widget/text_icon_button_test.dart' as text_icon_button_tests;
import 'widget/home_page_test.dart' as home_page_tests;
import 'widget/search_page_test.dart' as search_page_tests;
import 'widget/cues_page_test.dart' as cues_page_tests;
import 'widget/song_page_test.dart' as song_page_tests;

void main() {
  group('Énekeskönyv App Test Suite', () {
    group('Unit Tests', () {
      group('Utils', utils_tests.main);
      group('Settings Provider', settings_tests.main);
      group('Link Handler', link_tests.main);
    });

    group('Widget Tests', () {
      group('TextIconButton', text_icon_button_tests.main);
      group('HomePage', home_page_tests.main);
      group('SearchPage', search_page_tests.main);
      group('CuesPage', cues_page_tests.main);
      group('SongPage', song_page_tests.main);
    });
  });
}