import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() async {
  print(Platform.script);
  runApp(App());
}

class App extends StatelessWidget {
  const App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(''),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Lottie.asset(
                  'assets/Tests/WeAccept.json',
                  imageProviderFactory: (img) =>
                      AssetImage('assets/Images/WeAccept/${img.fileName}'),
                  onLoaded: (composition) {
                    if (composition.warnings.isNotEmpty) {
                      print(composition.warnings.join('\n'));
                    }
                  },
                ),
                Lottie.asset(
                  'assets/Tests/WeAcceptInlineImage.json',
                  onLoaded: (composition) {
                    if (composition.warnings.isNotEmpty) {
                      print(composition.warnings.join('\n'));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
