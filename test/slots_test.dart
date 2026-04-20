import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/model/content/content_model.dart';
import 'package:lottie/src/model/content/shape_fill.dart';
import 'package:lottie/src/model/content/shape_group.dart';

void main() {
  test('color slot overrides fill color', () async {
    final composition = await _loadComposition('single_slot_fill.json');
    expect(composition.colorSlots['primary'], const Color(0xFFFF0000));
    final fills = _collectFills(composition);
    expect(fills, hasLength(1));
    expect(fills.single.color?.keyframes.single.startValue, const Color(0xFFFF0000));
    expect(fills.single.color?.slotId, isNull);
  });

  test('empty slot definition does not crash', () async {
    final composition = await _loadComposition('empty_slot.json');
    expect(composition.colorSlots, isEmpty);
    final fills = _collectFills(composition);
    expect(fills.single.color?.keyframes.single.startValue, const Color(0xFF0000FF));
  });

  test('sid without matching slot keeps encoded color', () async {
    final composition = await _loadComposition('missing_slot.json');
    expect(composition.colorSlots, isEmpty);
    final fills = _collectFills(composition);
    expect(
      fills.single.color?.keyframes.single.startValue,
      const Color(0xFF336699),
    );
    expect(fills.single.color?.slotId, 'missing');
  });

  test('multiple slots resolve independently', () async {
    final composition = await _loadComposition('multiple_slots.json');
    expect(composition.colorSlots['primary'], const Color(0xFFFF0000));
    expect(composition.colorSlots['secondary'], const Color(0xFF00FF00));
    final fills = _collectFills(composition);
    expect(fills, hasLength(2));
    expect(fills[0].color?.keyframes.single.startValue, const Color(0xFFFF0000));
    expect(fills[1].color?.keyframes.single.startValue, const Color(0xFF00FF00));
    expect(fills[0].color?.slotId, isNull);
    expect(fills[1].color?.slotId, isNull);
  });

  test('animated color slot emits warning and keeps encoded color', () async {
    final composition = await _loadComposition('animated_slot.json');
    expect(composition.colorSlots, isEmpty);
    expect(
      composition.warnings,
      anyElement(
        contains('Animated color slot "animatedSlot" is not yet supported'),
      ),
    );
    final fills = _collectFills(composition);
    expect(
      fills.single.color?.keyframes.single.startValue,
      const Color(0xFF808080),
    );
  });
}

Future<LottieComposition> _loadComposition(String fileName) async {
  final bytes = File('test/data/slots/$fileName').readAsBytesSync();
  return LottieComposition.fromBytes(bytes);
}

List<ShapeFill> _collectFills(LottieComposition composition) {
  final out = <ShapeFill>[];
  for (final layer in composition.layers) {
    _collectFillsFromShapes(layer.shapes, out);
  }
  return out;
}

void _collectFillsFromShapes(List<ContentModel> shapes, List<ShapeFill> out) {
  for (final shape in shapes) {
    if (shape is ShapeFill) {
      out.add(shape);
    } else if (shape is ShapeGroup) {
      _collectFillsFromShapes(shape.items, out);
    }
  }
}
