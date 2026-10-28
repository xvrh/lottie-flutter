import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// An empty composition of 20x10.
final _composition = LottieComposition.parseJsonBytes(
  utf8.encode(
    '{"v": "5.12.0", "fr": 10, "ip": 0, "op": 10, "w": 20, "h": 10, '
    '"layers": [], "assets": []}',
  ),
);

Future<RenderBox> _render(
  WidgetTester tester, {
  double? width,
  double? height,
}) async {
  await tester.pumpWidget(
    Center(
      child: RawLottie(composition: _composition, width: width, height: height),
    ),
  );
  return tester.renderObject(find.byType(RawLottie));
}

void main() {
  testWidgets('Without a size, only the maximum intrinsic size is set', (
    tester,
  ) async {
    var lottie = await _render(tester);

    expect(lottie.getMinIntrinsicWidth(100), 0);
    expect(lottie.getMinIntrinsicHeight(100), 0);
    // The aspect ratio of the composition.
    expect(lottie.getMaxIntrinsicWidth(100), 200);
    expect(lottie.getMaxIntrinsicHeight(100), 50);
  });

  testWidgets('A height gives the width of the aspect ratio', (tester) async {
    var lottie = await _render(tester, height: 40);

    expect(lottie.getMinIntrinsicWidth(double.infinity), 80);
    expect(lottie.getMaxIntrinsicWidth(double.infinity), 80);
    expect(lottie.getMinIntrinsicHeight(double.infinity), 40);
    expect(lottie.getMaxIntrinsicHeight(double.infinity), 40);
  });

  testWidgets('IntrinsicWidth sizes the animation from its height', (
    tester,
  ) async {
    // Like Image: with a bounded height, IntrinsicWidth uses the maximum one.
    await tester.pumpWidget(
      Column(
        children: [
          IntrinsicWidth(
            child: RawLottie(composition: _composition, height: 40),
          ),
        ],
      ),
    );

    expect(tester.getSize(find.byType(RawLottie)), const Size(80, 40));
  });
}
