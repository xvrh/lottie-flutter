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

    for (var asset in [
      'assets/Tests/Stroke.json',
      'assets/lottiefiles/loading_disc.json',
      'assets/Mobilo/G.json',
      'assets/lottiefiles/truecosmos.json',
      'assets/lottiefiles/intelia_logo_animation.json',
      'assets/lottiefiles/landing_page.json',
      'assets/lottiefiles/permission.json',
      'assets/lottiefiles/little_girl_jumping_-_loader.json',
      'assets/lottiefiles/playing.json',
      'assets/lottiefiles/win_result_2.json',
    ]) {
      var composition =
          await LottieComposition.fromBytes(File(asset).readAsBytesSync());

      await tester.pumpWidget(FilmStrip(composition, size: size));

      var fileName = '${p.basenameWithoutExtension(asset)}.png'.toLowerCase();
      await expectLater(find.byType(FilmStrip),
          matchesGoldenFile(p.join('goldens/strokes', fileName)));
    }
  });
}
