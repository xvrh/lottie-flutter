import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

Future<Uint8List> _render(LottieDrawable drawable) async {
  var recorder = PictureRecorder();
  drawable.draw(Canvas(recorder), Offset.zero & drawable.size);
  var picture = recorder.endRecording();
  var image = await picture.toImage(
    drawable.size.width.round(),
    drawable.size.height.round(),
  );
  var pixels = await image.toByteData();
  image.dispose();
  picture.dispose();
  return pixels!.buffer.asUint8List();
}

LottieComposition _load(String name) => LottieComposition.parseJsonBytes(
  File('example/assets/Tests/$name').readAsBytesSync(),
);

void main() {
  test('A constant blur is drawn on every frame', () async {
    // The blurriness animates until frame 24, then stays the same.
    var drawable = LottieDrawable(_load('FillBlur.json'))..setProgress(0.5);

    var first = await _render(drawable);
    var second = await _render(drawable);

    expect(second, first);
  });

  test('LottieDrawable takes value delegates in its constructor', () async {
    var delegates = LottieDelegates(
      values: [
        ValueDelegate.dropShadow(
          ['**'],
          value: const DropShadow(
            color: Color(0xff0000ff),
            direction: 90,
            distance: 50,
            radius: 0,
          ),
        ),
      ],
    );
    var composition = _load('StaticShadow.json');

    var fromConstructor = LottieDrawable(composition, delegates: delegates)
      ..setProgress(0);
    var fromSetter = LottieDrawable(composition)
      ..setProgress(0)
      ..delegates = delegates;

    expect(await _render(fromConstructor), await _render(fromSetter));
  });

  for (var alpha in [1.0, 0.5]) {
    test(
      'A drop shadow delegate keeps the alpha of its color ($alpha)',
      () async {
        // A red rectangle with a drop shadow.
        var drawable = LottieDrawable(_load('StaticShadow.json'))
          ..setProgress(0)
          ..delegates = LottieDelegates(
            values: [
              ValueDelegate.dropShadow(
                ['**'],
                value: DropShadow(
                  color: Color.fromRGBO(0, 0, 255, alpha),
                  direction: 90,
                  distance: 50,
                  radius: 0,
                ),
              ),
            ],
          );

        var pixels = await _render(drawable);

        // The most opaque pixel where only the blue shadow shows.
        var shadowAlpha = 0;
        for (var i = 0; i < pixels.length; i += 4) {
          if (pixels[i] == 0 && pixels[i + 2] > 0) {
            shadowAlpha = max(shadowAlpha, pixels[i + 3]);
          }
        }
        expect(shadowAlpha, closeTo(alpha * 255, 1));
      },
    );
  }
}
