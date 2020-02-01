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
            Lottie.asset('assets/LottieLogo1.json'),
            Lottie.network(
                'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/sample_app/assets/Mobilo/A.json'),
          ],
        ),
      ),
    );
  }
}
