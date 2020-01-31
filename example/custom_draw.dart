import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

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

    for (int i = 0; i < 10; i++) {
      drawable.draw(canvas, Offset(i * 20.0, i * 20.0) & (size / 5),
          progress: i / 10);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
