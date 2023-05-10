import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'utils.dart';

void main() {
  var root = 'example/assets';

  testWidgets('Mirror animation', (tester) async {
    var size = const Size(500, 400);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    var composition = (await tester.runAsync(() =>
        FileLottie(File('$root/Tests/MatteTimeStretchScan.json')).load()))!;
    await tester.pumpWidget(FilmStrip(
      composition,
      size: size,
      delegates: LottieDelegates(values: [
        ValueDelegate.transformAnchorPoint([],
            value: Offset(composition.bounds.width.toDouble(), 0)),
        ValueDelegate.transformScale([], value: const Offset(-1, 1)),
      ]),
    ));

    await expectLater(
        find.byType(FilmStrip), matchesGoldenFile('goldens/mirror.png'));
  });
}
