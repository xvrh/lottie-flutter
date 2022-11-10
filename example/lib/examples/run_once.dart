import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:lottie/lottie.dart';
import '../src/all_files.g.dart';

void main() async {
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(print);

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            ++_index;
          });
        }
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: Scaffold(
        backgroundColor: Colors.lightBlue,
        appBar: AppBar(
          title: Text('$_index'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Lottie.asset(files[_index % files.length],
                    controller: _animationController, onLoaded: (composition) {
                  _animationController
                    ..duration = composition.duration
                    ..reset()
                    ..forward();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
