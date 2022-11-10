import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// This example show how to play the Lottie animation in various way:
/// - Start and stop the animation on event callback
/// - Play the animation forward and backward
/// - Loop between two specific frames
///
/// This works by creating an AnimationController instance and passing it
/// to the Lottie widget.
/// The AnimationController class has a rich API to run the animation in various ways.
void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this)
      ..value = 0.5
      ..addListener(() {
        setState(() {
          // Rebuild the widget at each frame to update the "progress" label.
        });
      });
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
        appBar: AppBar(
          title: const Text('Animation control'),
        ),
        body: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            Lottie.asset(
              'assets/LottieLogo1.json',
              controller: _controller,
              height: 300,
              onLoaded: (composition) {
                setState(() {
                  _controller.duration = composition.duration;
                });
              },
            ),
            Text(_controller.value.toStringAsFixed(2)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Play backward
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: () {
                    _controller.reverse();
                  },
                ),
                // Pause
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () {
                    _controller.stop();
                  },
                ),
                // Play forward
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () {
                    _controller.forward();
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Loop between 2 specifics frames

                var start = 0.1;
                var stop = 0.5;
                _controller.repeat(
                  min: start,
                  max: stop,
                  reverse: true,
                  period: _controller.duration! * (stop - start),
                );
              },
              child: const Text('Loop between frames'),
            ),
          ],
        ),
      ),
    );
  }
}
