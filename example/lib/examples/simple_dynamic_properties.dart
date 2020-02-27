import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            // Load a Lottie file from your assets
            Lottie.asset('assets/LottieLogo1.json'),

            // Load a Lottie file from a remote url
            Lottie.network(
                'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json'),

            // Load an animation and its images from a zip file
            Lottie.asset('assets/lottiefiles/angel.zip'),
          ],
        ),
      ),
    );
  }
}

String translate(String input) => '**$input**';

//--- example
class _Animation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/Tests/Shapes.json',
      delegates: LottieDelegates(
          text: (initialText) => translate(initialText),
          values: [
            ValueDelegate.color(
              const ['Shape Layer 1', 'Rectangle', 'Fill 1'],
              value: Colors.red,
            ),
            ValueDelegate.opacity(
              const ['Shape Layer 1', 'Rectangle'],
              callback: (frameInfo) =>
                  (frameInfo.overallProgress * 100).round(),
            ),
          ]),
    );
  }
}
//---
