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
          children: [
            Lottie.asset(
              'assets/AndroidWave.json',
              height: 300,
              delegates: LottieDelegates(values: [
                ValueDelegate.blurRadius(
                  ['**'],
                  value: 20,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
