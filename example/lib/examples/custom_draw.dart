import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: MyWidget(),
      ),
    );
  }
}

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<LottieComposition> _composition;

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
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

//--- example
class CustomDrawer extends StatelessWidget {
  final LottieComposition composition;

  const CustomDrawer(this.composition, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Painter(composition),
      size: Size(400, 400),
    );
  }
}

class _Painter extends CustomPainter {
  final LottieComposition composition;

  _Painter(this.composition);

  @override
  void paint(Canvas canvas, Size size) {
    var drawable = LottieDrawable(composition);

    for (var i = 0; i < 40; i++) {
      drawable.draw(canvas, Offset(i % 10 * 50.0, i ~/ 10 * 80.0) & (size / 5),
          progress: i / 40);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
//---
