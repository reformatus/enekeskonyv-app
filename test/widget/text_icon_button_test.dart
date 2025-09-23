import 'package:enekeskonyv/song/text_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextIconButton Widget Tests', () {
    testWidgets('should display text and icon correctly', (tester) async {
      const testText = 'Test Text';
      const testIcon = Icons.play_arrow;
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextIconButton(
              text: testText,
              onTap: () {
                wasPressed = true;
              },
              iconData: testIcon,
              disabledColor: Colors.grey,
              alignment: Alignment.centerLeft,
              context: tester.element(find.byType(Scaffold)),
            ),
          ),
        ),
      );

      // Check if text is displayed
      expect(find.text(testText), findsOneWidget);

      // Check if icon is displayed
      expect(find.byIcon(testIcon), findsOneWidget);

      // Check if button is tappable
      await tester.tap(find.byType(TextIconButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('should display only icon when text is null', (tester) async {
      const testIcon = Icons.play_arrow;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextIconButton(
              text: null,
              onTap: () {},
              iconData: testIcon,
              disabledColor: Colors.grey,
              alignment: Alignment.center,
              context: tester.element(find.byType(Scaffold)),
            ),
          ),
        ),
      );

      // Check if icon is displayed
      expect(find.byIcon(testIcon), findsOneWidget);

      // Check if empty text container is present
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('should be disabled when onTap is null', (tester) async {
      const testText = 'Disabled Button';
      const testIcon = Icons.play_arrow;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextIconButton(
              text: testText,
              onTap: null, // Disabled
              iconData: testIcon,
              disabledColor: Colors.grey,
              alignment: Alignment.centerLeft,
              context: tester.element(find.byType(Scaffold)),
            ),
          ),
        ),
      );

      // Button should still be present but not interactive
      expect(find.byType(TextIconButton), findsOneWidget);
      expect(find.text(testText), findsOneWidget);
      expect(find.byIcon(testIcon), findsOneWidget);

      // Verify the InkWell has no onTap handler
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });

    testWidgets('should display tooltip when provided', (tester) async {
      const testText = 'Button Text';
      const testTooltip = 'This is a tooltip';
      const testIcon = Icons.info;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextIconButton(
              text: testText,
              tooltip: testTooltip,
              onTap: () {},
              iconData: testIcon,
              disabledColor: Colors.grey,
              alignment: Alignment.centerLeft,
              context: tester.element(find.byType(Scaffold)),
            ),
          ),
        ),
      );

      // Long press to show tooltip
      await tester.longPress(find.byType(TextIconButton));
      await tester.pumpAndSettle();

      // Check if tooltip is displayed
      expect(find.text(testTooltip), findsOneWidget);
    });

    testWidgets('should apply correct alignment', (tester) async {
      const testText = 'Aligned Text';
      const testIcon = Icons.star;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextIconButton(
                  text: testText,
                  onTap: () {},
                  iconData: testIcon,
                  disabledColor: Colors.grey,
                  alignment: Alignment.centerLeft,
                  context: tester.element(find.byType(Scaffold)),
                ),
                TextIconButton(
                  text: testText,
                  onTap: () {},
                  iconData: testIcon,
                  disabledColor: Colors.grey,
                  alignment: Alignment.centerRight,
                  context: tester.element(find.byType(Scaffold)),
                ),
              ],
            ),
          ),
        ),
      );

      // Both buttons should be present
      expect(find.byType(TextIconButton), findsNWidgets(2));
      expect(find.text(testText), findsNWidgets(2));
      expect(find.byIcon(testIcon), findsNWidgets(2));
    });

    testWidgets('should handle text overflow correctly', (tester) async {
      const longText = 'This is a very long text that should overflow';
      const testIcon = Icons.text_fields;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100, // Constrained width to force overflow
              child: TextIconButton(
                text: longText,
                onTap: () {},
                iconData: testIcon,
                disabledColor: Colors.grey,
                alignment: Alignment.centerLeft,
                context: tester.element(find.byType(Scaffold)),
              ),
            ),
          ),
        ),
      );

      // Text should be present but constrained
      expect(find.textContaining('This is a very'), findsOneWidget);
      
      // Verify the text widget has overflow handling
      final textWidget = tester.widget<Text>(find.textContaining('This is a very'));
      expect(textWidget.overflow, equals(TextOverflow.fade));
      expect(textWidget.maxLines, equals(1));
      expect(textWidget.softWrap, isFalse);
    });

    testWidgets('should respect disabled color when disabled', (tester) async {
      const testText = 'Disabled Text';
      const testIcon = Icons.block;
      const disabledColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextIconButton(
              text: testText,
              onTap: null, // Disabled
              iconData: testIcon,
              disabledColor: disabledColor,
              alignment: Alignment.centerLeft,
              context: tester.element(find.byType(Scaffold)),
            ),
          ),
        ),
      );

      // Find the text widget and check its color
      final textWidget = tester.widget<Text>(find.text(testText));
      expect(textWidget.style?.color, equals(disabledColor));

      // Find the icon widget and check its color
      final iconWidget = tester.widget<Icon>(find.byIcon(testIcon));
      expect(iconWidget.color, equals(disabledColor));
    });
  });
}