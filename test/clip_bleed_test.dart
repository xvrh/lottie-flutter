import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'draw() clips artwork that bleeds past the composition bounds',
    () async {
      final bytes = Uint8List.fromList(
        utf8.encode(jsonEncode(_bleedingCompositionJson)),
      );
      final composition = LottieComposition.parseJsonBytes(bytes);
      final drawable = LottieDrawable(composition)..setProgress(0);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const destRect = Rect.fromLTWH(30, 30, 40, 40);

      drawable.draw(canvas, destRect, fit: BoxFit.cover);
      final image = await recorder.endRecording().toImage(100, 100);
      final pixels = await image.toByteData();

      final insideOffset = (50 * 100 + 50) * 4;
      expect(pixels!.getUint8(insideOffset + 3), greaterThan(0));
      final outsideOffset = (5 * 100 + 5) * 4;
      expect(pixels.getUint8(outsideOffset + 3), 0);
    },
  );
}

// Declared on a 100x100 canvas, but the circle itself has a 600 diameter
// centered at (50, 50) — it extends far past the composition's own bounds,
// the way real AE exports often bleed past their frame edges. Without the
// clipRect fix this paints straight through to pixel (5, 5), well outside
// destRect.
const _bleedingCompositionJson = {
  'v': '5.5.2',
  'fr': 30,
  'ip': 0,
  'op': 30,
  'w': 100,
  'h': 100,
  'nm': 'green_circle',
  'ddd': 0,
  'assets': [],
  'layers': [
    {
      'ddd': 0,
      'ind': 1,
      'ty': 4,
      'nm': 'circle_layer',
      'sr': 1,
      'ks': {
        'o': {'a': 0, 'k': 100},
        'r': {'a': 0, 'k': 0},
        'p': {
          'a': 0,
          'k': [50, 50, 0],
        },
        'a': {
          'a': 0,
          'k': [0, 0, 0],
        },
        's': {
          'a': 0,
          'k': [100, 100, 100],
        },
      },
      'ao': 0,
      'shapes': [
        {
          'ty': 'gr',
          'nm': 'Circle Group',
          'it': [
            {
              'ty': 'el',
              'nm': 'bleedingCircle',
              'p': {
                'a': 0,
                'k': [0, 0],
              },
              's': {
                'a': 0,
                'k': [600, 600],
              },
            },
            {
              'ty': 'fl',
              'nm': 'greenFill',
              'c': {
                'a': 0,
                'k': [0, 1, 0, 1],
              },
              'o': {'a': 0, 'k': 100},
            },
            {
              'ty': 'tr',
              'nm': 'Transform',
              'p': {
                'a': 0,
                'k': [0, 0],
              },
              'a': {
                'a': 0,
                'k': [0, 0],
              },
              's': {
                'a': 0,
                'k': [100, 100],
              },
              'r': {'a': 0, 'k': 0},
              'o': {'a': 0, 'k': 100},
            },
          ],
        },
      ],
      'ip': 0,
      'op': 30,
      'st': 0,
      'bm': 0,
    },
  ],
};
