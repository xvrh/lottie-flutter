import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/frame_changes.dart';
import 'package:path/path.dart' as p;

/// The animations in which a frame is drawn differently from the previous one
/// although the drawable reports no change. This is not related to
/// [FrameChanges]: `LottieDrawable.setProgress` returns false for that frame.
const _notInvalidated = {
  'Tests/FillBlur.json',
  'Tests/PrecompBlur.json',
  'Tests/PrecompBlurDecimapPrecompSize.json',
  'lottiefiles/45668-arrow-with-light-passing-through.json',
};

/// The longest side of the rendered frames.
const _maxSide = 200.0;

Future<Uint32List> _render(LottieDrawable drawable, Size size) async {
  var recorder = PictureRecorder();
  drawable.draw(Canvas(recorder), Offset.zero & size, fit: BoxFit.contain);
  var picture = recorder.endRecording();
  var image = await picture.toImage(size.width.round(), size.height.round());
  var pixels = await image.toByteData();
  image.dispose();
  picture.dispose();
  return pixels!.buffer.asUint32List();
}

bool _areSame(Uint32List a, Uint32List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void main() {
  var root = 'example/assets';
  for (var asset
      in Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => p.extension(f.path) == '.json')) {
    var name = p.relative(asset.path, from: root);

    test(
      'unchanged frames of $name are drawn alike',
      skip: _notInvalidated.contains(name)
          ? 'A frame is not invalidated by the drawable'
          : null,
      () async {
        var composition = await LottieComposition.fromBytes(
          asset.readAsBytesSync(),
        );
        var changes = FrameChanges.of(composition);
        double progressOf(int frame) =>
            min(1, (frame + 0.5) / changes.frameCount);

        // Playing the composition fills its record.
        var player = LottieDrawable(composition);
        for (var frame = 0; frame <= changes.lastFrame; frame++) {
          player.setProgress(progressOf(frame));
        }
        var changed = <int>{};
        for (var frame = 0; frame <= changes.lastFrame;) {
          frame = changes.nextChangeAfter(frame);
          changed.add(frame);
        }
        bool isUnchanged(int frame) =>
            frame > 0 && frame <= changes.lastFrame && !changed.contains(frame);

        var bounds = composition.bounds;
        var scale = min(1.0, _maxSide / max(bounds.width, bounds.height));
        var size = Size(
          max(1, (bounds.width * scale).roundToDouble()),
          max(1, (bounds.height * scale).roundToDouble()),
        );

        // Every frame is given to the drawable, like when the animation is
        // played, but only the frames to compare are rendered.
        var drawable = LottieDrawable(composition)..setProgress(0);
        Uint32List? previous;
        for (var frame = 0; frame <= changes.lastFrame; frame++) {
          if (frame > 0) {
            drawable.setProgress(progressOf(frame));
          }
          if (!isUnchanged(frame) && !isUnchanged(frame + 1)) continue;

          var pixels = await _render(drawable, size);
          if (isUnchanged(frame)) {
            expect(_areSame(pixels, previous!), isTrue, reason: 'frame $frame');
          }
          previous = pixels;
        }
      },
    );
  }
}
