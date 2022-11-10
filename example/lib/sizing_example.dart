import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var composition = await LottieComposition.fromByteData(
      await rootBundle.load('assets/lf20_w2Afea.json'));

  runApp(App(composition: composition));
}

class App extends StatelessWidget {
  final LottieComposition composition;

  const App({super.key, required this.composition});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(''),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                _Lottie(
                  composition,
                ),
                _Lottie(
                  composition,
                  width: 200,
                ),
                _Lottie(
                  composition,
                  height: 200,
                ),
                _Lottie(
                  composition,
                  width: 200,
                  height: 200,
                  alignment: Alignment.bottomRight,
                ),
                _Lottie(
                  composition,
                  width: 200,
                  height: 200,
                  fit: BoxFit.fill,
                ),
                _Lottie(
                  composition,
                  width: 200,
                  height: 200,
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.bottomRight,
                ),
                SizedBox(
                  width: 150,
                  child: _Lottie(composition),
                ),
                Container(
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.green)),
                  child: SizedBox(
                    width: 300,
                    height: 150,
                    child: Align(
                        alignment: Alignment.bottomRight,
                        child: _Lottie(composition)),
                  ),
                ),
                IntrinsicHeight(
                  child: _Lottie(
                    composition,
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Align(child: _Lottie(composition)),
                ),
                IntrinsicWidth(
                  child: _Lottie(
                    composition,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Lottie extends StatefulWidget {
  final LottieComposition composition;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry? alignment;

  const _Lottie(this.composition,
      {this.width, this.height, this.fit, this.alignment});

  @override
  __LottieState createState() => __LottieState();
}

class __LottieState extends State<_Lottie> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: widget.composition.duration)
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.red)),
        child: Lottie(
          composition: widget.composition,
          controller: _controller,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
        ),
      ),
    );
  }
}
