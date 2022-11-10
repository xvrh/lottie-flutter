import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  late final AnimationController _controller;
  int _repeatIndex = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _repeatIndex++;
          });
          if (_repeatIndex < 5) {
            _controller.reset();
            _controller.forward();
          }
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            Lottie.asset(
              'assets/AndroidWave.json',
              controller: _controller,
              width: 150,
              height: 150,
              onLoaded: (composition) {
                // Configure the AnimationController with the duration of the
                // Lottie file and start the animation.
                _controller.duration = composition.duration;
                _controller.forward();
              },
            ),
            Center(child: Text('Repeat: $_repeatIndex')),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
