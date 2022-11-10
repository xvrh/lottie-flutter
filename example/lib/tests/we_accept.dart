import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() async {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(''),
        ),
        body: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
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
            Lottie.network(
              'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Tests/WeAccept.json',
              onLoaded: (composition) {
                if (composition.warnings.isNotEmpty) {
                  print(composition.warnings.join('\n'));
                }
              },
            ),
            Lottie.network(
              'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Tests/WeAcceptInlineImage.json',
              onLoaded: (composition) {
                if (composition.warnings.isNotEmpty) {
                  print(composition.warnings.join('\n'));
                }
              },
            ),
            Lottie.network(
              'https://github.com/xvrh/lottie-flutter/blob/master/example/assets/Tests/Airbnb.zip?raw=true',
              onLoaded: (composition) {
                if (composition.warnings.isNotEmpty) {
                  print(composition.warnings.join('\n'));
                }
              },
            ),
            Lottie.asset(
              'assets/lottiefiles/angel.zip',
              onLoaded: (composition) {
                if (composition.warnings.isNotEmpty) {
                  print(composition.warnings.join('\n'));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
