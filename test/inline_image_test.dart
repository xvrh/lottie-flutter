import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('Loads an inline image whose base64 is wrapped over lines', (
    tester,
  ) async {
    var json = jsonDecode(
      File('example/assets/Tests/WeAcceptInlineImage.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    var asset = (json['assets'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((asset) => asset['id'] == 'image_0');
    var dataUri = asset['p'] as String;
    var start = dataUri.indexOf(',') + 1;
    asset['p'] =
        dataUri.substring(0, start) +
        [
          for (var i = start; i < dataUri.length; i += 76)
            dataUri.substring(i, min(i + 76, dataUri.length)),
        ].join('\r\n');

    var composition = (await tester.runAsync(
      () => MemoryLottie(utf8.encode(jsonEncode(json))).load(),
    ))!;

    expect(composition.images['image_0']!.loadedImage, isNotNull);
  });
}
