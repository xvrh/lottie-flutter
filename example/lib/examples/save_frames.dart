import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// This example shows how to save the frame of an animation to files on disk.
void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<File>? _frames;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _export,
                child: const Text('Export all frames'),
              ),
              if (_frames != null)
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 10,
                    children: [..._frames!.map((f) => Image.file(f))],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export() async {
    var composition =
        await AssetLottie('assets/lottiefiles/airbnb.json').load();

    var frames = await exportFrames(
        composition, await _createTempDirectory('export-lottie'),
        progresses: [for (var i = 0.0; i <= 1; i += 0.1) i],
        size: const Size(50, 50));

    setState(() {
      _frames = frames;
    });
  }
}

Future<List<File>> exportFrames(LottieComposition composition, String directory,
    {required Size size, required List<double> progresses}) async {
  var drawable = LottieDrawable(composition);

  var frames = <File>[];
  for (var progress in progresses) {
    drawable.setProgress(progress);

    var bytes = await _toByteData(drawable, size);
    var fileName = (progress * 100).round().toString().padLeft(3, '0');

    var file = File(p.join(directory, '$fileName.png'));
    await file.writeAsBytes(bytes.buffer.asUint8List());

    frames.add(file);
  }

  return frames;
}

Future<ByteData> _toByteData(LottieDrawable drawable, Size size) async {
  var pictureRecorder = PictureRecorder();
  var canvas = Canvas(pictureRecorder);

  drawable.draw(canvas, Offset.zero & size);

  var picture = pictureRecorder.endRecording();
  var image = await picture.toImage(size.width.toInt(), size.height.toInt());
  return (await image.toByteData(format: ImageByteFormat.png))!;
}

Future<String> _createTempDirectory(String folderName) async {
  final tempDirectory = await getTemporaryDirectory();
  var dir = Directory(p.join(tempDirectory.path, folderName));
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  return dir.path;
}
