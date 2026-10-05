import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:enekeskonyv/main.dart';

void main() {
  testWidgets('app boots to the home page', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const Enekeskonyv());
    // pumpAndSettle would block on the app's long-lived timers; a couple of
    // bounded frames are enough to let the widget tree build.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
