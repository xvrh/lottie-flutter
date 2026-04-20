import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/model/content/content_model.dart';
import 'package:lottie/src/model/content/shape_fill.dart';
import 'package:lottie/src/model/content/shape_group.dart';
import 'package:lottie/src/model/content/shape_stroke.dart';

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

  test('color slot overrides stroke color', () async {
    final composition = await _loadComposition('stroke_slot.json');
    expect(composition.colorSlots['strokeColor'], const Color(0xFF3366CC));
    final strokes = _collectStrokes(composition);
    expect(strokes, hasLength(1));
    expect(
      strokes.single.color.keyframes.single.startValue,
      const Color(0xFF3366CC),
    );
    expect(strokes.single.color.slotId, isNull);
  });

  test('color slot resolves inside precomp asset', () async {
    final composition = await _loadComposition('precomp_slot.json');
    expect(composition.colorSlots['primary'], const Color(0xFFFF0000));
    final precompLayers = composition.getPrecomps('comp_1');
    expect(precompLayers, isNotNull);
    final fills = <ShapeFill>[];
    for (final layer in precompLayers!) {
      _collectFillsFromShapes(layer.shapes, fills);
    }
    expect(fills.single.color?.keyframes.single.startValue, const Color(0xFFFF0000));
    expect(fills.single.color?.slotId, isNull);
  });

  test('malformed slot entries are skipped without crashing', () async {
    final composition = await _loadComposition('slot_edge_cases.json');
    expect(composition.colorSlots['primary'], const Color(0xFFFF0000));
    expect(composition.colorSlots.containsKey('stringSlot'), isFalse);
    expect(composition.colorSlots.containsKey('badInner'), isFalse);
    final fills = _collectFills(composition);
    expect(fills.single.color?.keyframes.single.startValue, const Color(0xFFFF0000));
    expect(fills.single.color?.slotId, isNull);
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

List<ShapeStroke> _collectStrokes(LottieComposition composition) {
  final out = <ShapeStroke>[];
  for (final layer in composition.layers) {
    _collectStrokesFromShapes(layer.shapes, out);
  }
  return out;
}

void _collectStrokesFromShapes(
  List<ContentModel> shapes,
  List<ShapeStroke> out,
) {
  for (final shape in shapes) {
    if (shape is ShapeStroke) {
      out.add(shape);
    } else if (shape is ShapeGroup) {
      _collectStrokesFromShapes(shape.items, out);
    }
  }
}
