import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() async {
  runApp(App());
}

class App extends StatefulWidget {
  const App({Key key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: Scaffold(
        backgroundColor: Colors.lightBlue,
        appBar: AppBar(
          title: Text(''),
        ),
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
