import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:lottie/lottie.dart';

// This example show how to use a Lottie animation as a SplashScreen for your application
// Since animation are loaded from the assets and can take a few milliseconds to
// load, we instruct flutter to defer the first frame until when the animation
// is actually ready to be displayed.
void main() async {
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(print);

  runApp(const SplashScreen());
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.deferFirstFrame();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: Scaffold(
        backgroundColor: Colors.lightBlue,
        appBar: AppBar(
          title: const Text('Splash screen'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Lottie.asset('assets/AndroidWave.json',
                    onLoaded: (composition) {
                  WidgetsBinding.instance!.allowFirstFrame();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
