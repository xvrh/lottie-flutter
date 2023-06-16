import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets('Opacity layer option', (tester) async {
    var size = const Size(500, 800);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    var bytes =
        File('example/assets/Tests/opacity_layers.json').readAsBytesSync();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Lottie.memory(
                bytes,
                options: LottieOptions(enableApplyingOpacityToLayers: true),
              ),
              Lottie.memory(
                bytes,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await expectLater(find.byType(Scaffold),
        matchesGoldenFile(p.join('goldens/opacity_layers.png')));
  });
}
