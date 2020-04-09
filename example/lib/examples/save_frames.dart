import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            RaisedButton(
              child: Text('Save Film Strip'),
              onPressed: () async {
                var data = await rootBundle.load('assets/HamburgerArrow.json');
                var result = await exportFilmStrip(data);
                await File('output.png')
                    .writeAsBytes(result.buffer.asUint8List());
              },
            ),
            RaisedButton(
              child: Text('Save all frames'),
              onPressed: () async {
                var data = await rootBundle.load('assets/HamburgerArrow.json');
                await saveAllFrames(data, 'output_folder');
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<ByteData> exportFilmStrip(ByteData data) async {
  var composition = await LottieComposition.fromByteData(data);
  var drawable = LottieDrawable(composition);

  var pictureRecorder = PictureRecorder();
  var canvas = Canvas(pictureRecorder);

  var size = Size(500, 500);
  var columns = 10;
  for (var i = composition.startFrame; i < composition.endFrame; i += 1) {
    drawable.setProgress(i / composition.durationFrames);

    var destRect = Offset(i % columns * 50.0, i ~/ 10 * 80.0) & (size / 5);
    drawable.draw(canvas, destRect);
  }

  var picture = pictureRecorder.endRecording();
  var image = await picture.toImage(size.width.toInt(), size.height.toInt());
  var bytes = await image.toByteData(format: ImageByteFormat.png);
  return bytes;
}

Future<void> saveAllFrames(ByteData data, String destination) async {
  var composition = await LottieComposition.fromByteData(data);
  var drawable = LottieDrawable(composition);

  var size = Size(composition.bounds.width.toDouble(),
      composition.bounds.height.toDouble());
  for (var i = composition.startFrame; i < composition.endFrame; i += 1) {
    drawable.setProgress(i / composition.durationFrames);

    var pictureRecorder = PictureRecorder();
    var canvas = Canvas(pictureRecorder);

    drawable.draw(canvas, Offset.zero & size);

    var picture = pictureRecorder.endRecording();
    var image = await picture.toImage(size.width.toInt(), size.height.toInt());
    var bytes = await image.toByteData(format: ImageByteFormat.png);
    await File(p.join(destination, '$i.png'))
        .writeAsBytes(bytes.buffer.asUint8List());
  }
}
