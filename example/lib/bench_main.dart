import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lottie/lottie.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  var frames = 0;
  SchedulerBinding.instance.addTimingsCallback((timings) {
    frames += timings.length;
  });
  Timer.periodic(const Duration(seconds: 1), (_) {
    // ignore: avoid_print
    print('frames/s: $frames');
    frames = 0;
  });
  runApp(const BenchApp());
}

class BenchApp extends StatelessWidget {
  const BenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            Lottie.asset(
              const String.fromEnvironment(
                'ASSET',
                defaultValue: 'assets/LottieLogo1.json',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
