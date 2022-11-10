import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [_Animation()],
        ),
      ),
    );
  }
}

//--- example
class _Animation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/Tests/Shapes.json',
      delegates: LottieDelegates(
        text: (initialText) => '**$initialText**',
        values: [
          ValueDelegate.color(
            const ['Shape Layer 1', 'Rectangle', 'Fill 1'],
            value: Colors.red,
          ),
          ValueDelegate.opacity(
            const ['Shape Layer 1', 'Rectangle'],
            callback: (frameInfo) => (frameInfo.overallProgress * 100).round(),
          ),
          ValueDelegate.position(
            const ['Shape Layer 1', 'Rectangle', '**'],
            relative: const Offset(100, 200),
          ),
        ],
      ),
    );
  }
}
//---
