import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:lottie/lottie.dart';

void main() async {
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(print);

  runApp(const MaterialApp(
    color: Colors.lightBlue,
    home: App(),
  ));
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin {
  late Future<Uint8List> _lottieAnimation;

  @override
  void initState() {
    super.initState();

    // Start loading the animation in background here
    _lottieAnimation = _loadAnimation();
  }

  Future<Uint8List> _loadAnimation() async {
    var asset = await rootBundle.load('assets/AndroidWave.json');
    return asset.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      appBar: AppBar(
        title: const Text('Splash screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            var bytes = await _lottieAnimation;
            await Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (context) => AnimationScreen(
                  animationBytes: bytes,
                ),
              ),
            );
          },
          child: const Text('Open splash'),
        ),
      ),
    );
  }
}

class AnimationScreen extends StatelessWidget {
  final Uint8List animationBytes;

  const AnimationScreen({Key? key, required this.animationBytes})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation'),
      ),
      body: Center(
        child: Lottie.memory(animationBytes),
      ),
    );
  }
}
