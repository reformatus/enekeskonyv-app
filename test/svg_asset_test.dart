import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  testWidgets('generated score SVGs render without errorBuilder', (
    WidgetTester tester,
  ) async {
    final all = Directory('assets/referdelyi')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.svg'))
        .toList();
    all.shuffle(Random(7));
    final files = all.take(40).map((f) => f.path).toList()
      ..addAll([
        'assets/referdelyi/referdelyi-280-v001.svg',
        'assets/referdelyi/referdelyi-335-v001.svg',
        'assets/referdelyi/referdelyi-396-v001.svg',
      ]);
    for (final f in files) {
      var errored = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SvgPicture.asset(
            f,
            errorBuilder: (context, error, stackTrace) {
              errored = true;
              return Text('ERR: $error');
            },
          ),
        ),
      );
      await tester.pump();
      expect(errored, isFalse, reason: f);
    }
  });
}
