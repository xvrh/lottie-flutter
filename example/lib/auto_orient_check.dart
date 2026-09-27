import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Scratch entry point to eyeball the auto-orient fix:
/// flutter run -t lib/auto_orient_check.dart
void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Lottie.asset(
            'assets/Tests/Airplane.json',
            width: 400,
            height: 400,
            repeat: true,
          ),
        ),
      ),
    );
  }
}
