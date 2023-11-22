import 'dart:ui';
import '../../composition.dart';
import '../../value/keyframe.dart';
import '../animatable/animatable_double_value.dart';
import '../animatable/animatable_text_frame.dart';
import '../animatable/animatable_text_properties.dart';
import '../animatable/animatable_transform.dart';
import '../content/blur_effect.dart';
import '../content/content_model.dart';
import '../content/drop_shadow_effect.dart';
import '../content/mask.dart';

enum LayerType { preComp, solid, image, nullLayer, shape, text, unknown }

enum MatteType { none, add, invert, luma, lumaInverted, unknown }

class Layer {
  final List<ContentModel> shapes;
  final LottieComposition composition;
  final String name;
  final int id;
  final LayerType layerType;
  final int parentId;
  final String? refId;
  final List<Mask> masks;
  final AnimatableTransform transform;
  final int solidWidth;
  final int solidHeight;
  final Color solidColor;
  final double timeStretch;
  final double startFrame;
  final int preCompWidth;
  final int preCompHeight;
  final AnimatableTextFrame? text;
  final AnimatableTextProperties? textProperties;
  final List<Keyframe<double>> inOutKeyframes;
  final MatteType matteType;
  final AnimatableDoubleValue? timeRemapping;
  final bool isHidden;
  final BlurEffect? blurEffect;
  final DropShadowEffect? dropShadowEffect;
  final BlendMode? blendMode;

  double get startProgress {
    return startFrame / composition.durationFrames;
  }

  Layer({
    required this.shapes,
    required this.composition,
    required this.name,
    required this.id,
    required this.layerType,
    required this.parentId,
    this.refId,
    required this.masks,
    required this.transform,
    required this.solidWidth,
    required this.solidHeight,
    required this.solidColor,
    required this.timeStretch,
    required this.startFrame,
    required this.preCompWidth,
    required this.preCompHeight,
    this.text,
    this.textProperties,
    required this.inOutKeyframes,
    required this.matteType,
    this.timeRemapping,
    required this.isHidden,
    this.blurEffect,
    this.dropShadowEffect,
    this.blendMode,
  });

  @override
  String toString() {
    return toStringWithPrefix('');
  }

  String toStringWithPrefix(String prefix) {
    var sb = StringBuffer()
      ..write(prefix)
      ..write(name)
      ..write('\n');
    var parent = composition.layerModelForId(parentId);
    if (parent != null) {
      sb
        ..write('\t\tParents: ')
        ..write(parent.name);
      parent = composition.layerModelForId(parent.parentId);
      while (parent != null) {
        sb
          ..write('->')
          ..write(parent.name);
        parent = composition.layerModelForId(parent.parentId);
      }
      sb
        ..write(prefix)
        ..write('\n');
    }
    if (masks.isNotEmpty) {
      sb
        ..write(prefix)
        ..write('\tMasks: ')
        ..write(masks.length)
        ..write('\n');
    }
    if (solidWidth != 0 && solidHeight != 0) {
      sb
        ..write(prefix)
        ..write('\tBackground: ')
        ..write('${solidWidth}x$solidHeight $solidColor');
    }
    if (shapes.isNotEmpty) {
      sb
        ..write(prefix)
        ..write('\tShapes:\n');
      for (Object shape in shapes) {
        sb
          ..write(prefix)
          ..write('\t\t')
          ..write(shape)
          ..write('\n');
      }
    }
    return sb.toString();
  }
}
