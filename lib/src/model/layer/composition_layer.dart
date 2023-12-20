import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/value_callback_keyframe_animation.dart';
import '../../composition.dart';
import '../../l.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../utils.dart';
import '../../value/lottie_value_callback.dart';
import '../key_path.dart';
import 'base_layer.dart';
import 'layer.dart';
import 'shape_layer.dart';

class CompositionLayer extends BaseLayer {
  BaseKeyframeAnimation<double, double>? _timeRemapping;
  final List<BaseLayer> _layers = <BaseLayer>[];
  final Paint _layerPaint = Paint();

  bool? _hasMatte;
  bool? _hasMasks;

  CompositionLayer(LottieDrawable lottieDrawable, Layer layerModel,
      List<Layer> layerModels, LottieComposition composition)
      : super(lottieDrawable, layerModel) {
    var timeRemapping = layerModel.timeRemapping;
    if (timeRemapping != null) {
      _timeRemapping = timeRemapping.createAnimation();
      addAnimation(_timeRemapping);
      _timeRemapping!.addUpdateListener(invalidateSelf);
    }

    var layerMap = <int, BaseLayer>{};

    BaseLayer? mattedLayer;
    for (var i = layerModels.length - 1; i >= 0; i--) {
      var lm = layerModels[i];
      var layer = BaseLayer.forModel(this, lm, lottieDrawable, composition);
      if (layer == null) {
        continue;
      }
      layerMap[layer.layerModel.id] = layer;
      if (mattedLayer != null) {
        mattedLayer.setMatteLayer(layer);
        mattedLayer = null;
      } else {
        _layers.insert(0, layer);
        switch (lm.matteType) {
          case MatteType.add:
          case MatteType.invert:
            mattedLayer = layer;
          case MatteType.luma:
          case MatteType.lumaInverted:
          case MatteType.none:
          case MatteType.unknown:
            break;
        }
      }
    }

    for (var key in layerMap.keys) {
      var layerView = layerMap[key];
      // This shouldn't happen but it appears as if sometimes on pre-lollipop devices when
      // compiled with d8, layerView is null sometimes.
      // https://github.com/airbnb/lottie-android/issues/524
      if (layerView == null) {
        continue;
      }
      var parentLayer = layerMap[layerView.layerModel.parentId];
      if (parentLayer != null) {
        layerView.setParentLayer(parentLayer);
      }
    }
  }

  @override
  void drawLayer(Canvas canvas, Matrix4 parentMatrix,
      {required int parentAlpha}) {
    L.beginSection('CompositionLayer#draw');
    var newClipRect = Rect.fromLTWH(0, 0, layerModel.preCompWidth.toDouble(),
        layerModel.preCompHeight.toDouble());
    newClipRect = parentMatrix.mapRect(newClipRect);

    // Apply off-screen rendering only when needed in order to improve rendering performance.
    var isDrawingWithOffScreen =
        lottieDrawable.isApplyingOpacityToLayersEnabled &&
            _layers.length > 1 &&
            parentAlpha != 255;
    if (isDrawingWithOffScreen) {
      _layerPaint.setAlpha(parentAlpha);
      canvas.saveLayer(newClipRect, _layerPaint);
    } else {
      canvas.save();
    }

    var childAlpha = isDrawingWithOffScreen ? 255 : parentAlpha;
    for (var i = _layers.length - 1; i >= 0; i--) {
      if (!newClipRect.isEmpty) {
        canvas.clipRect(newClipRect);
      }

      var layer = _layers[i];
      layer.draw(canvas, parentMatrix, parentAlpha: childAlpha);
    }
    canvas.restore();
    L.endSection('CompositionLayer#draw');
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    var bounds = super.getBounds(parentMatrix, applyParents: applyParents);
    for (var i = _layers.length - 1; i >= 0; i--) {
      var layerBounds = _layers[i].getBounds(boundsMatrix, applyParents: true);
      bounds = bounds.expandToInclude(layerBounds);
    }
    return bounds;
  }

  @override
  void setProgress(double progress) {
    super.setProgress(progress);
    if (_timeRemapping != null) {
      // The duration has 0.01 frame offset to show end of animation properly.
      // https://github.com/airbnb/lottie-android/pull/766
      // Ignore this offset for calculating time-remapping because time-remapping value is based on original duration.
      var durationFrames = lottieDrawable.composition.durationFrames + 0.01;
      var compositionDelayFrames = layerModel.composition.startFrame;
      var remappedFrames =
          _timeRemapping!.value * layerModel.composition.frameRate -
              compositionDelayFrames;
      progress = remappedFrames / durationFrames;
    }

    if (_timeRemapping == null) {
      progress -= layerModel.startProgress;
    }
    //Time stretch needs to be divided if is not "__container"
    if (layerModel.timeStretch != 0 && layerModel.name != '__container') {
      progress /= layerModel.timeStretch;
    }
    for (var i = _layers.length - 1; i >= 0; i--) {
      _layers[i].setProgress(progress);
    }
  }

  bool? get hasMasks {
    if (_hasMasks == null) {
      for (var i = _layers.length - 1; i >= 0; i--) {
        var layer = _layers[i];
        if (layer is ShapeLayer) {
          if (layer.hasMasksOnThisLayer()) {
            _hasMasks = true;
            return true;
          }
        } else if (layer is CompositionLayer && layer.hasMasks!) {
          _hasMasks = true;
          return true;
        }
      }
      _hasMasks = false;
    }
    return _hasMasks;
  }

  bool get hasMatte {
    if (_hasMatte == null) {
      if (hasMatteOnThisLayer()) {
        _hasMatte = true;
        return true;
      }

      for (var i = _layers.length - 1; i >= 0; i--) {
        if (_layers[i].hasMatteOnThisLayer()) {
          _hasMatte = true;
          return true;
        }
      }
      _hasMatte = false;
    }
    return _hasMatte!;
  }

  @override
  void resolveChildKeyPath(KeyPath keyPath, int depth,
      List<KeyPath> accumulator, KeyPath currentPartialKeyPath) {
    for (var i = 0; i < _layers.length; i++) {
      _layers[i]
          .resolveKeyPath(keyPath, depth, accumulator, currentPartialKeyPath);
    }
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    super.addValueCallback(property, callback);

    if (property == LottieProperty.timeRemap) {
      if (callback == null) {
        if (_timeRemapping != null) {
          _timeRemapping!.setValueCallback(null);
        }
      } else {
        _timeRemapping = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<double>, 1);
        _timeRemapping!.addUpdateListener(invalidateSelf);
        addAnimation(_timeRemapping);
      }
    }
  }
}
