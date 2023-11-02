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
            // Load a Lottie file from your assets
            Lottie.asset('assets/LottieLogo1.json'),

            // Load a Lottie file from a remote url
            Lottie.network(
                'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json'),

            // Load a dotlottie file from your assets
            Lottie.asset('assets/lottiefiles/cat.lottie'),

            // Load a dotlottie file from a remote url
            Lottie.network(
                'https://static9.lottiefiles.com/lotties/01_ramen_character.lottie'),

            // Load an animation and its images from a zip file
            Lottie.asset('assets/lottiefiles/angel.zip'),
          ],
        ),
      ),
    );
  }
}
