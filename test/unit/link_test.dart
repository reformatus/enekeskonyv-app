import 'package:enekeskonyv/cues/link.dart';
import 'package:enekeskonyv/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../helpers/test_helper.dart';

void main() {
  group('Link Handler Tests', () {
    setUp(() {
      TestHelper.setupSharedPreferences();
      TestHelper.setupMockSongBooks();
    });

    tearDown(() {
      TestHelper.cleanup();
    });

    group('openAppLink', () {
      testWidgets('should return null for invalid host', (tester) async {
        await tester.pumpWidget(TestHelper.createTestWidget(
          child: Builder(
            builder: (context) {
              final uri = Uri.parse('https://example.com?s=21.1.0');
              final result = openAppLink(uri, context);
              expect(result, isNull);
              return Container();
            },
          ),
        ));
      });

      testWidgets('should return null for URI without query parameters', (tester) async {
        await tester.pumpWidget(TestHelper.createTestWidget(
          child: Builder(
            builder: (context) {
              final uri = Uri.parse('https://reflabs.hu');
              final result = openAppLink(uri, context);
              expect(result, isNull);
              return Container();
            },
          ),
        ));
      });

      testWidgets('should handle valid song link', (tester) async {
        await tester.pumpWidget(TestHelper.createTestWidget(
          child: Builder(
            builder: (context) {
              final uri = Uri.parse('https://reflabs.hu?s=21.1.0');
              final result = openAppLink(uri, context);
              // Should return null on success (no error)
              expect(result, isNull);
              return Container();
            },
          ),
        ));

        await tester.pumpAndSettle();
        
        // Verify that a song page was pushed
        expect(find.byType(MaterialPageRoute), findsOneWidget);
      });

      testWidgets('should return error for invalid verse ID', (tester) async {
        await tester.pumpWidget(TestHelper.createTestWidget(
          child: Builder(
            builder: (context) {
              final uri = Uri.parse('https://reflabs.hu?s=invalid');
              final result = openAppLink(uri, context);
              expect(result, contains('Helytelen link'));
              return Container();
            },
          ),
        ));
      });

      testWidgets('should handle cue list link', (tester) async {
        await tester.pumpWidget(TestHelper.createTestWidget(
          child: Builder(
            builder: (context) {
              final uri = Uri.parse('https://reflabs.hu?c=TestList');
              final result = openAppLink(uri, context);
              // Should return null on success (no error)
              expect(result, isNull);
              return Container();
            },
          ),
        ));
      });
    });

    group('Link Generation', () {
      testWidgets('should generate verse link correctly', (tester) async {
        await tester.pumpWidget(TestHelper.createTestWidget(
          child: Builder(
            builder: (context) {
              // Test would need to verify actual link generation functions
              // This is a placeholder for when those functions are exposed
              return Container();
            },
          ),
        ));
      });
    });

    group('QR Code Dialog', () {
      testWidgets('should display QR code dialog with correct content', (tester) async {
        const testTitle = 'Test Song';
        const testLink = 'https://reflabs.hu?s=21.1.0';

        await tester.pumpWidget(TestHelper.createTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showShareDialog(context, testTitle, verseId: testLink);
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ));

        // Tap button to show dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Verify dialog is shown
        expect(find.text('$testTitle megosztása'), findsOneWidget);
        expect(find.byType(SimpleDialog), findsOneWidget);

        // Verify QR code is displayed
        expect(find.byType(QrImageView), findsOneWidget);

        // Verify close button
        expect(find.byIcon(Icons.close), findsOneWidget);

        // Close dialog
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Verify dialog is closed
        expect(find.byType(SimpleDialog), findsNothing);
      });
    });
  });
}