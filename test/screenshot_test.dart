import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;

void main() {
  //TODO(xha): download all screenshots from lottie-android as golden screenshots
  // https://happo.io/api/a/27/p/27/reports/abe43ed3d2f25a3ea3c38b1740011cf84fea5e93-android28

  const animationPath = 'example/assets';

  var animations = <_Screenshot>[
    _Screenshot('AndroidWave.json'),
    _Screenshot('HamburgerArrow.json'),
    _Screenshot('HamburgerArrow.json', progress: 0.5),
    _Screenshot('HamburgerArrow.json', progress: 1.0),
    _Screenshot('Mobilo/A.json', progress: 0.5),
    _Screenshot('Mobilo/B.json', progress: 0.5),
    _Screenshot('Logo/LogoSmall.json', progress: 0.5),
    _Screenshot('lottiefiles/atm_link.json', progress: 1.0),
  ];
  for (var animation in animations) {
    testWidgets('Screenshot ${animation.name} at ${animation.progress}', (
      WidgetTester tester,
    ) async {
      var composition = await LottieComposition.fromBytes(
        File(p.join(animationPath, animation.name)).readAsBytesSync(),
      );

      var goldenName = animation.goldenName;

      await tester.pumpWidget(
        RawLottie(composition: composition, progress: animation.progress),
      );
      await expectLater(
        find.byType(RawLottie),
        matchesGoldenFile(
          p.join('golden', p.dirname(animation.name), '$goldenName.png'),
        ),
      );
    });
  }
}

class _Screenshot {
  final String name;
  final double progress;

  _Screenshot(this.name, {this.progress = 0.0});

  String get goldenName =>
      '${p.basenameWithoutExtension(name)}_${progress.toStringAsFixed(1).replaceAll('.', '_')}';
}
