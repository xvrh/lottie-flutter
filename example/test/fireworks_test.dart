import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;
import 'utils.dart';

void main() {
  testWidgets('Animations with stroke', (tester) async {
    var size = Size(500, 400);
    tester.binding.window.physicalSizeTestValue = size;
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    var composition = await LottieComposition.fromBytes(
        File('assets/17297-fireworks.json').readAsBytesSync());

    await tester.pumpWidget(FilmStrip(composition, size: size));

    await expectLater(find.byType(FilmStrip),
        matchesGoldenFile(p.join('goldens/fireworks.png')));
  });
}
