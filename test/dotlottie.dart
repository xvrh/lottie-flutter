import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/utils.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets('Dotlottie', (tester) async {
    var size = const Size(500, 400);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    var provider =
        FileLottie(File('example/assets/cat.lottie'), decoder: customDecoder);
    await tester.runAsync(() => provider.load());

    await tester.pumpWidget(LottieBuilder(lottie: provider));

    await expectLater(find.byType(Lottie),
        matchesGoldenFile(p.join('goldens/dotlottie.png')));
  });
}

Future<LottieComposition?> customDecoder(List<int> bytes) {
  return LottieComposition.decodeZip(bytes, filePicker: (files) {
    return files.firstWhereOrNull(
        (f) => f.name.startsWith('animations/') && f.name.endsWith('.json'));
  });
}
