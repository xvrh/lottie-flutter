import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: MyWidget(),
      ),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final Future<LottieComposition> _composition;

  @override
  void initState() {
    super.initState();

    _composition = _loadComposition();
  }

  Future<LottieComposition> _loadComposition() async {
    var assetData = await rootBundle
        .load('assets/lottiefiles/little_girl_jumping_-_loader.json');
    return LottieComposition.fromByteData(assetData);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LottieComposition>(
      future: _composition,
      builder: (context, snapshot) {
        var composition = snapshot.data;
        if (composition != null) {
          return CustomDrawer(composition);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

//--- example
class CustomDrawer extends StatelessWidget {
  final LottieComposition composition;

  const CustomDrawer(this.composition, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Painter(composition),
      size: const Size(400, 400),
    );
  }
}

class _Painter extends CustomPainter {
  final LottieDrawable drawable;

  _Painter(LottieComposition composition)
      : drawable = LottieDrawable(composition);

  @override
  void paint(Canvas canvas, Size size) {
    var frameCount = 40;
    var columns = 10;
    for (var i = 0; i < frameCount; i++) {
      var destRect = Offset(i % columns * 50.0, i ~/ 10 * 80.0) & (size / 5);
      drawable
        ..setProgress(i / frameCount)
        ..draw(canvas, destRect);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
//---
