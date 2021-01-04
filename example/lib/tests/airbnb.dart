import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() async {
  runApp(App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

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
                Lottie.asset('assets/lottiefiles/airbnb.json',
                    onLoaded: (composition) {
                  if (composition.warnings.isNotEmpty) {
                    print(composition.warnings.join('\n'));
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
