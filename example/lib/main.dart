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
            Lottie.network("https://jkpnpgenvlzonmcnsury.supabase.co/storage/v1/object/public/stickers/41+hamburger.tgs?ts=1291291993"),
            Lottie.asset("assets/LightningBug_file_137160385.tgs"),
            Lottie.network('https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json'),

            // Load an animation and its images from a zip file
            Lottie.asset('assets/lottiefiles/angel.zip'),
          ],
        ),
      ),
    );
  }
}
