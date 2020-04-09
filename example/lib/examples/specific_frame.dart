import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Lottie.asset(
            'assets/LottieLogo1.json',
            controller: _controller,
            onLoaded: (composition) {
              _controller
                ..duration = composition.duration ~/ 5
                ..repeat(min: 0.0, max: 0.2, reverse: true);
            },
          ),
        ),
      ),
    );
  }
}
