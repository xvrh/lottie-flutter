import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;
import 'utils/utils_golden.dart';

void main() {
  //TODO(xha): download all screenshots from lottie-android as golden screenshots
  // https://happo.io/api/a/27/p/27/reports/abe43ed3d2f25a3ea3c38b1740011cf84fea5e93-android28

  final sampleFiles = 'example/assets';

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
    test('Screenshot ${animation.name} at ${animation.progress}', () async {
      var result = await screenshot(p.join(sampleFiles, animation.name),
          (drawable, canvas) {
        drawable.draw(canvas, Offset.zero & drawable.size,
            progress: animation.progress);
      });

      var goldenName = animation.goldenName;
      expect(
          result,
          equalsGolden(p.join(
              'test/golden', p.dirname(animation.name), '$goldenName.png')));
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

Future<Uint8List> screenshot(String compositionPath,
    void Function(LottieDrawable, Canvas) drawCallback) async {
  var drawable = LottieDrawable(await LottieComposition.fromBytes(
      File(compositionPath).readAsBytesSync()));
  var size = drawable.size;

  var recorder = PictureRecorder();
  var canvas = Canvas(recorder);
  drawCallback(drawable, canvas);
  var picture = recorder.endRecording();
  var image = await picture.toImage(size.width.ceil(), size.height.ceil());
  return (await image.toByteData(format: ImageByteFormat.png))
      .buffer
      .asUint8List();
}

Future<Uint8List> filmStrip(
    String compositionPath, void Function(LottieDrawable, Canvas) drawCallback,
    {int frameRate}) async {
  //TODO(xha): loop for each progress (drawable.duration * frameRate)
  // translate the canvas and draw the frame time above

  throw UnimplementedError();
}
