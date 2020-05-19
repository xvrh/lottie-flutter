import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() async {
  runApp(App());
}

class App extends StatelessWidget {
  const App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: Scaffold(
        backgroundColor: Colors.lightBlue,
        body: Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: Lottie.asset(
              'assets/LottieLogo1.json',
              animate: true,
              repeat: false,
            ),
          ),
        ),
      ),
    );
  }
}
