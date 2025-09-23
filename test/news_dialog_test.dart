import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enekeskonyv/models/news.dart';
import 'package:enekeskonyv/widgets/news_dialog.dart';

void main() {
  testWidgets('NewsDialog displays news content correctly', (WidgetTester tester) async {
    bool closeCalled = false;
    
    final news = News(
      id: 'test-1',
      title: 'Test News Title',
      markdownText: 'This is **test** content with markdown.',
      archived: false,
      actionButtons: [
        const NewsActionButton(
          title: 'Test Button',
          uri: 'https://example.com',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewsDialog(
            news: news,
            onClose: () => closeCalled = true,
          ),
        ),
      ),
    );

    // Check if the dialog displays the news title
    expect(find.text('Test News Title'), findsOneWidget);
    
    // Check if the close button is present
    expect(find.text('Bezárás'), findsOneWidget);
    
    // Check if action button is present
    expect(find.text('Test Button'), findsOneWidget);
    
    // Tap the close button
    await tester.tap(find.text('Bezárás'));
    await tester.pump();
    
    // Verify onClose was called
    expect(closeCalled, isTrue);
  });
}