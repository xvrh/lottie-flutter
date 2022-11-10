import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [_Animation()],
        ),
      ),
    );
  }
}

class _Animation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Lottie.network(
      'https://example.does.not.exist/lottie.json',
      errorBuilder: (context, exception, stackTrace) {
        return const Text('😢');
      },
    );
  }
}
