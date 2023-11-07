import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Example(),
      ),
    );
  }
}

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  //--- example
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Lottie.network(
          'https://telegram.org/file/464001484/1/bzi7gr7XRGU.10147/815df2ef527132dd23',
          decoder: LottieComposition.decodeGZip,
        ),
        Lottie.asset(
          'assets/LightningBug_file.tgs',
          decoder: LottieComposition.decodeGZip,
        ),
      ],
    );
  }
  //---
}
