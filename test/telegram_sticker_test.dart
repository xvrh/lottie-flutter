import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets('Telegram sticker', (tester) async {
    var size = const Size(500, 400);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    var provider = FileLottie(File('example/assets/LightningBug_file.tgs'),
        decoder: LottieComposition.decodeGZip);
    await tester.runAsync(() => provider.load());

    await tester.pumpWidget(LottieBuilder(lottie: provider));

    await expectLater(find.byType(Lottie),
        matchesGoldenFile(p.join('goldens/lightningbug_file.png')));
  });
}
