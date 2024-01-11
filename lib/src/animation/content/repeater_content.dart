import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../model/content/repeater.dart';
import '../../model/key_path.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../utils/misc.dart';
import '../../value/lottie_value_callback.dart';
import '../keyframe/base_keyframe_animation.dart';
import '../keyframe/transform_keyframe_animation.dart';
import 'content.dart';
import 'content_group.dart';
import 'drawing_content.dart';
import 'greedy_content.dart';
import 'key_path_element_content.dart';
import 'path_content.dart';

class RepeaterContent
    implements
        DrawingContent,
        PathContent,
        GreedyContent,
        KeyPathElementContent {
  final Matrix4 _matrix = Matrix4.identity();
  final _path = Path();

  final LottieDrawable lottieDrawable;
  final BaseLayer layer;
  final Repeater _repeater;
  final BaseKeyframeAnimation<double, double> _copies;
  final BaseKeyframeAnimation<double, double> _offset;
  final TransformKeyframeAnimation _transform;
  ContentGroup? _contentGroup;

  RepeaterContent(this.lottieDrawable, this.layer, this._repeater)
      : _copies = _repeater.copies.createAnimation(),
        _offset = _repeater.offset.createAnimation(),
        _transform = _repeater.transform.createAnimation() {
    layer.addAnimation(_copies);
    _copies.addUpdateListener(_invalidate);

    layer.addAnimation(_offset);
    _offset.addUpdateListener(_invalidate);

    _transform.addAnimationsToLayer(layer);
    _transform.addListener(_invalidate);
  }

  @override
  void absorbContent(List<Content> contents) {
    // This check prevents a repeater from getting added twice.
    // This can happen in the following situation:
    //    RECTANGLE
    //    REPEATER 1
    //    FILL
    //    REPEATER 2
    // In this case, the expected structure would be:
    //     REPEATER 2
    //        REPEATER 1
    //            RECTANGLE
    //        FILL
    // Without this check, REPEATER 1 will try and absorb contents once it is already inside of
    // REPEATER 2.
    if (_contentGroup != null) {
      return;
    }
    // Fast forward the iterator until after this content.
    var index = contents.lastIndexOf(this) - 1;
    var newContents = <Content>[];
    while (index >= 0) {
      var content = contents[index];
      newContents.add(content);
      contents.removeAt(index);
      --index;
    }
    newContents = newContents.reversed.toList();

    _contentGroup = ContentGroup.copy(
        lottieDrawable, layer, 'Repeater', newContents, null,
        hidden: _repeater.hidden);
  }

  @override
  String? get name => _repeater.name;

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    _contentGroup!.setContents(contentsBefore, contentsAfter);
  }

  @override
  Path getPath() {
    var contentPath = _contentGroup!.getPath();
    _path.reset();
    var copies = _copies.value;
    var offset = _offset.value;
    for (var i = copies.toInt() - 1; i >= 0; i--) {
      _matrix.set(_transform.getMatrixForRepeater(i + offset));
      _path.addPath(contentPath, Offset.zero, matrix4: _matrix.storage);
    }
    return _path;
  }

  @override
  void draw(Canvas canvas, Matrix4 parentMatrix, {required int parentAlpha}) {
    var copies = _copies.value;
    var offset = _offset.value;
    var startOpacity = _transform.startOpacity!.value / 100.0;
    var endOpacity = _transform.endOpacity!.value / 100.0;
    for (var i = copies.toInt() - 1; i >= 0; i--) {
      _matrix.set(parentMatrix);
      _matrix.preConcat(_transform.getMatrixForRepeater(i + offset));
      var newAlpha =
          parentAlpha * lerpDouble(startOpacity, endOpacity, i / copies)!;
      _contentGroup!.draw(canvas, _matrix, parentAlpha: newAlpha.round());
    }
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    return _contentGroup!.getBounds(parentMatrix, applyParents: applyParents);
  }

  void _invalidate() {
    lottieDrawable.invalidateSelf();
  }

  @override
  void resolveKeyPath(KeyPath keyPath, int depth, List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath) {
    MiscUtils.resolveKeyPath(
        keyPath, depth, accumulator, currentPartialKeyPath, this);
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    if (_transform.applyValueCallback(property, callback)) {
      return;
    }

    if (property == LottieProperty.repeaterCopies) {
      _copies.setValueCallback(callback as LottieValueCallback<double>?);
    } else if (property == LottieProperty.repeaterOffset) {
      _offset.setValueCallback(callback as LottieValueCallback<double>?);
    }
  }
}
