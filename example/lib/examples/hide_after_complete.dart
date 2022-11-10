import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() async {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _showAnimation = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _showAnimation = false;
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
          title: Text('Show lottie animation: $_showAnimation'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                if (_showAnimation)
                  Lottie.asset(
                    'assets/LottieLogo1.json',
                    controller: _animationController,
                    width: 200,
                    onLoaded: (composition) {
                      _animationController
                        ..duration = composition.duration
                        ..reset()
                        ..forward();
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
