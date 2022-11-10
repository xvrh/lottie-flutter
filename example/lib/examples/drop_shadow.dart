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
              'assets/Tests/Fill.json',
              height: 300,
              delegates: LottieDelegates(values: [
                ValueDelegate.dropShadow(
                  ['**'],
                  value: const DropShadow(
                    color: Colors.blue,
                    direction: 140,
                    distance: 60,
                    radius: 10,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
