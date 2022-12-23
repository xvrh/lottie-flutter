import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

void main() async {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: ChameleonLottieDrawer(),
      ),
    );
  }
}

class ChameleonLottieDrawer extends StatefulWidget {
  const ChameleonLottieDrawer({super.key});

  @override
  State<StatefulWidget> createState() => _ChameleonLottieDrawerWidgetState();
}

class _ChameleonLottieDrawerWidgetState extends State<ChameleonLottieDrawer> {
  int? _frameCallbackId;
  final ValueNotifier<double> _repaint = ValueNotifier<double>(0);
  double _lastFrameTime = 0.0;
  _Painter? _painter;

  Future<LottieComposition> _requireLottieComposition() async {
    var assetData = await rootBundle.load('assets/chameleon2.json');
    return LottieComposition.fromByteData(assetData);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LottieComposition>(
        future: _requireLottieComposition(),
        builder: (context, AsyncSnapshot<LottieComposition> snapshot) {
          /*表示数据成功返回*/
          if (snapshot.hasData) {
            _painter = _Painter(snapshot.data!, repaint: _repaint);
            return Listener(
                onPointerMove: (detail) {
                  final offset = detail.position;
                  _painter?.updateTouchPoint(offset);
                  _fireRepaintCommand();
                },
                onPointerHover: (detail) {
                  final offset = detail.position;
                  _painter?.updateTouchPoint(offset);
                  _fireRepaintCommand();
                },
                child: CustomPaint(
                    painter: _painter!, size: const Size(400, 400)));
          } else {
            return const Center(
                child: SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                  strokeWidth: 8.0),
            ));
          }
        });
  }

  void _fireRepaintCommand() {
    _repaint.value = _repaint.value + 1.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _frameCallbackId =
        SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
  }

  @override
  void dispose() {
    if (null != _frameCallbackId) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackId!);
      _frameCallbackId = null;
    }
    super.dispose();
  }

  void beginFrame(Duration timeStamp) {
    final t =
        timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
    if (_lastFrameTime == 0.0) {
      _lastFrameTime = t;
      _frameCallbackId =
          SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
      return;
    }

    var elapsed = t - _lastFrameTime;
    _lastFrameTime = t;
    _painter?.setElapsedTime(elapsed);
    _fireRepaintCommand();
    _frameCallbackId =
        SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
  }
}

class _Layer {
  final String name;
  final double radius;
  final double divisor;

  _Layer({required this.name, required this.radius, required this.divisor});
}

class _EyeData {
  Offset current;
  double distance;
  double eyeAngle;

  _EyeData(
      {required this.current, required this.distance, required this.eyeAngle});
}

class _ChameleonAlphaColor extends ValueNotifier<Color> {
  Color? _newColor;
  int _targetAlpha = 255;

  _ChameleonAlphaColor(super.value) : _targetAlpha = value.alpha;

  void changeColor(final Color color) {
    _newColor = color;
    _targetAlpha = color.alpha;
  }

  void stepAlpha(int stepVal) {
    var alpha = super.value.alpha;
    if (null == _newColor) {
      if (alpha < _targetAlpha) {
        alpha = alpha + stepVal;
        if (alpha > _targetAlpha) {
          alpha = _targetAlpha;
        }
        super.value = super.value.withAlpha(alpha);
      }
    } else {
      if (alpha <= 0) {
        super.value = _newColor!.withAlpha(0);
        _newColor = null;
      } else {
        alpha = alpha - stepVal;
        if (alpha < 0) {
          alpha = 0;
        }
        super.value = super.value.withAlpha(alpha);
      }
    }
  }
}

class _Painter extends CustomPainter {
  late final LottieApi api;
  late final LottieDrawable drawable;
  final LottieComposition composition;
  double _frameTime = 0.0;
  ValueNotifier<bool> isActive = ValueNotifier(false);
  double _elapsed = 0;

  final double degToRads = pi / 180;

  //鼠标或者点击位置的坐标
  ValueNotifier<Offset> touchPoint = ValueNotifier(const Offset(100, 500));
  ValueNotifier<bool> mouseChanged = ValueNotifier(false);
  ValueNotifier<double> distanceToMouse = ValueNotifier(0.0);
  ValueNotifier<double> minTongueRadius = ValueNotifier(405);
  ValueNotifier<double> maxTongueRadius = ValueNotifier(415);
  ValueNotifier<double> angle = ValueNotifier(0.0);

  // 变色龙的颜色 默认 rgba(158, 231, 152, 1);
  _ChameleonAlphaColor chameleonColor =
      _ChameleonAlphaColor(const Color.fromARGB(1, 158, 231, 152));

  // 滑过或者点击的叶片
  String hitLeaf = '';

  // 变色龙变色的定时器
  Timer? camouflageTimeout;

  var leftEyeCircles = [
    _Layer(name: 'Group 12', radius: 27, divisor: 20),
    _Layer(name: 'Group 13', radius: 27, divisor: 20),
    _Layer(name: 'Group 14', radius: 27, divisor: 20),
    _Layer(name: 'Group 15', radius: 23, divisor: 20),
    _Layer(name: 'Group 16', radius: 21, divisor: 35),
    _Layer(name: 'Group 17', radius: 19, divisor: 50),
    _Layer(name: 'Group 18', radius: 17, divisor: 65),
    _Layer(name: 'Group 19', radius: 15, divisor: 80),
    _Layer(name: 'Group 20', radius: 13, divisor: 95),
    _Layer(name: 'Group 21', radius: 5, divisor: 75)
  ];
  var rightEyeCircles = [
    _Layer(name: 'Group 1', radius: 27, divisor: 20),
    _Layer(name: 'Group 2', radius: 27, divisor: 20),
    _Layer(name: 'Group 3', radius: 27, divisor: 20),
    _Layer(name: 'Group 4', radius: 23, divisor: 20),
    _Layer(name: 'Group 5', radius: 21, divisor: 35),
    _Layer(name: 'Group 6', radius: 19, divisor: 50),
    _Layer(name: 'Group 7', radius: 17, divisor: 65),
    _Layer(name: 'Group 8', radius: 15, divisor: 80),
    _Layer(name: 'Group 9', radius: 13, divisor: 95),
    _Layer(name: 'Group 10', radius: 5, divisor: 75)
  ];

  var leaves = ['leaf_1', 'leaf_2', 'leaf_3', 'leaf_4'];

  _Painter(this.composition, {super.repaint}) {
    drawable = LottieDrawable(composition);
    api = LottieApi(drawable);
    drawable.delegates = _requireLottieDelegates();
    var timeout = const Duration(milliseconds: 1000);
    camouflageTimeout = Timer(timeout, () {
      chameleonColor.value = const Color.fromARGB(1, 240, 237, 231);
      camouflageTimeout = null;
    });
  }

  void _leavesHitTest() {
    for (var i = 0; i < leaves.length; i++) {
      var value = leaves[i];
      final keyPath = ['#$value', 'color_group', 'fill_prop'];
      var hit = api.hitTest(keyPath, touchPoint.value);
      if (hit) {
        if ((hitLeaf != value) && (hitLeaf != 'hit$value')) {
          hitLeaf = value;
          if (null != camouflageTimeout) {
            camouflageTimeout?.cancel();
          }
          var timeout = const Duration(milliseconds: 15000);
          camouflageTimeout = Timer(timeout, () {
            hitLeaf = '';
            camouflageTimeout = null;
          });
          break;
        }
      }
    }
  }

  void updateTouchPoint(Offset value) {
    mouseChanged.value = true;
    touchPoint.value = value;
    _leavesHitTest();
  }

  LottieDelegates _requireLottieDelegates() {
    final delegates = <ValueDelegate>[];
    final chameleon = _requireChameleonColorValueDelegates();
    delegates.addAll(chameleon);
    final eyes = _requireEyeCircleDelegates();
    delegates.addAll(eyes);
    final leafs = _requireLeafColorValueDelegates();
    delegates.addAll(leafs);
    final mouthProps = _requireMouthPropertiesDelegates();
    delegates.addAll(mouthProps);
    final arrowProps = _requireArrowPropertiesDelegates();
    delegates.addAll(arrowProps);
    final tongueProps = _requireTonguePropertiesDelegates();
    delegates.addAll(tongueProps);
    return LottieDelegates(
      values: delegates,
    );
  }

  List<ValueDelegate> _requireEyeCircleDelegates() {
    final delegates = <ValueDelegate>[];
    int i, len = leftEyeCircles.length;
    var cachedMouseEyeData =
        _EyeData(current: const Offset(-1, -1), distance: 0, eyeAngle: 0);
    for (i = 0; i < len; i += 1) {
      delegates.add(_requireEyeCircleValueDelegates(
          leftEyeCircles[i], 'left_eye', cachedMouseEyeData));
    }
    len = rightEyeCircles.length;
    cachedMouseEyeData =
        _EyeData(current: const Offset(-1, -1), distance: 0, eyeAngle: 0);
    for (i = 0; i < len; i += 1) {
      delegates.add(_requireEyeCircleValueDelegates(
          rightEyeCircles[i], 'right_eye', cachedMouseEyeData));
    }
    return delegates;
  }

  ValueDelegate _requireEyeCircleValueDelegates(
      _Layer circleData, String eye, _EyeData cachedMouseEyeData) {
    final keyPath = <String>[
      'Loop',
      eye,
      circleData.name,
    ];

    Offset? lastValue;
    double eyeAngle;
    return ValueDelegate.transformPosition(keyPath, callback: (position) {
      var currentValue = position.endValue;
      currentValue ??= position.startValue;
      currentValue ??= const Offset(0, 0);
      lastValue ??= currentValue;
      if (!isActive.value) {
        var point = api.toContainerPoint(touchPoint.value);
        var lp = api.toKeyPathLayerPoint(keyPath, point);
        if (lp.isNotEmpty) {
          point = lp.first;
        }
        cachedMouseEyeData.distance = sqrt(pow(point.dx, 2) + pow(point.dy, 2));
        cachedMouseEyeData.eyeAngle =
            atan2(0 - point.dy, 0 - point.dx) / degToRads + 179;
        cachedMouseEyeData.current = point;
      }
      eyeAngle = cachedMouseEyeData.eyeAngle;
      var distance = cachedMouseEyeData.distance;
      distance = distance > circleData.radius ? circleData.radius : distance;
      var newValueX = currentValue.dx + distance * cos(eyeAngle * degToRads);
      var newValueY = currentValue.dy + distance * sin(eyeAngle * degToRads);
      newValueX =
          lastValue!.dx + (newValueX - lastValue!.dx) / circleData.divisor * 3;
      newValueY =
          lastValue!.dy + (newValueY - lastValue!.dy) / circleData.divisor * 3;
      lastValue = Offset(newValueX, newValueY);
      return lastValue!;
    });
  }

  ValueDelegate _requireLeafColorValueDelegate(final String leaf) {
    final keyPath = <String>['#$leaf', 'color_group', 'fill_prop'];
    return ValueDelegate.color(keyPath, callback: (color) {
      var value = const Color.fromARGB(255, 255, 255, 255);
      if (null != color.endValue) {
        value = color.endValue!;
      } else if (null != color.startValue) {
        value = color.startValue!;
      }
      // 点击坐标检查，如果当前点击坐标在此种颜色的叶子上，则设置颜色为此叶子的颜色
      if (hitLeaf.isEmpty) {
        chameleonColor.changeColor(const Color.fromARGB(1, 240, 237, 231));
        chameleonColor.stepAlpha(5);
      } else if (hitLeaf == leaf) {
        chameleonColor.changeColor(value);
        hitLeaf = 'hit$leaf';
      } else if ('hit$leaf' == hitLeaf) {
        chameleonColor.stepAlpha(5);
      }
      return value;
    });
  }

  List<ValueDelegate> _requireLeafColorValueDelegates() {
    final delegates = <ValueDelegate>[];
    var len = leaves.length;
    for (var i = 0; i < len; i += 1) {
      delegates.add(_requireLeafColorValueDelegate(leaves[i]));
    }
    return delegates;
  }

  List<ValueDelegate> _requireChameleonColorValueDelegates() {
    var chameleonColorPaths = [
      // head
      ['Loop', 'head', 'Group 1', '.chameleon_color'],
      // body
      ['Loop', 'Body Outlines', 'Group 1', '.chameleon_color'],
      ['Loop', 'Body Outlines', 'Group 2', '.chameleon_color'],
      // tail
      ['Loop', 'Tail Outlines', 'Group 1', '.chameleon_color'],
      // legs
      ['Loop', 'LegsFront Outlines', 'Group 1', '.chameleon_color'],
      ['Loop', 'LegsFront Outlines', 'Group 2', '.chameleon_color'],
      ['Loop', 'LegsBack Outlines', 'Group 1', '.chameleon_color'],
      ['Loop', 'LegsBack Outlines', 'Group 2', '.chameleon_color'],
      // belly (腹部）
      ['Loop', 'Belly Outlines', 'Group 1', '.chameleon_color'],
      ['Loop', 'Belly Outlines', 'Group 2', '.chameleon_color'],
      ['Loop', 'Belly Outlines', 'Group 3', '.chameleon_color'],
      ['Loop', 'Belly Outlines', 'Group 4', '.chameleon_color'],
      ['Loop', 'Belly Outlines', 'Group 5', '.chameleon_color'],
      ['Loop', 'Belly Outlines', 'Group 6', '.chameleon_color'],
    ];
    final delegates = <ValueDelegate>[];
    for (var i = 0; i < chameleonColorPaths.length; i++) {
      var keyPath = chameleonColorPaths[i];
      var colors = api.requireColorValueDelegates(keyPath, chameleonColor);
      delegates.addAll(colors);
      var delegate = ValueDelegate.opacity(keyPath, callback: (cb) {
        return (chameleonColor.value.alpha * 100 / 255.0).round();
      });
      delegates.add(delegate);
    }
    return delegates;
  }

  List<ValueDelegate> _requireMouthPropertiesDelegates() {
    final delegates = <ValueDelegate>[];
    final keyPath = <String>['Mouth'];
    var perc = 0.0;
    var delegate = ValueDelegate.timeRemap(keyPath, callback: (currentValue) {
      if (!isActive.value && mouseChanged.value) {
        var point = api.toContainerPoint(touchPoint.value);
        final keyPath = <String>['Mouth', 'ReferencePoint'];
        var point2 = api.toKeyPathLayerPoint(keyPath, point);
        if (point2.isNotEmpty) {
          var p = point2[0];
          angle.value = atan2(0 - p.dy, 0 - p.dx) / degToRads + 170;
          distanceToMouse.value = sqrt(pow(0 - p.dx, 2) + pow(0 - p.dy, 2));
        }
        mouseChanged.value = false;
      }

      if (distanceToMouse.value < minTongueRadius.value) {
        perc = distanceToMouse.value / minTongueRadius.value;
        return perc * 9 / 30;
      } else if (distanceToMouse.value > maxTongueRadius.value) {
        perc = 1 -
            min(
                1,
                (distanceToMouse.value - maxTongueRadius.value) /
                    (maxTongueRadius.value + 100));
        return perc * (9 / 30);
      } else if (distanceToMouse.value >= minTongueRadius.value) {
        return 9 / 30;
      }
      return 0;
    });
    delegates.add(delegate);
    return delegates;
  }

  List<ValueDelegate> _requireArrowPropertiesDelegates() {
    final delegates = <ValueDelegate>[];
    var keyPath = <String>['Mouth', 'Tongue_Comp', '.default_arrow', 'Shape 1'];
    var currentScale = -1.0;
    var currentScaleValue = const Offset(-1.0, -1.0);
    var scale = ValueDelegate.transformScale(keyPath, callback: (value) {
      var currentValue = value.endValue!;
      var scale = currentValue.dx;
      if (currentScale != scale) {
        currentScaleValue = currentScaleValue.scale(scale, scale);
        currentScale = scale;
      }
      return currentScaleValue;
    });

    delegates.add(scale);

    var rotation = ValueDelegate.transformRotation(keyPath, callback: (value) {
      return -angle.value;
    });
    delegates.add(rotation);
    return delegates;
  }

  List<ValueDelegate> _requireTonguePropertiesDelegates() {
    final delegates = <ValueDelegate>[];
    var tongueInitialAnimationTime = 0.0;
    var tongueCurrentTime = 0.0;

    void animateTongue() {
      final now = DateTime.now();
      tongueInitialAnimationTime = now.millisecondsSinceEpoch - 1500 / 30;
      isActive.value = true;
    }

    void resetTongue() {
      isActive.value = false;
    }

    var keyPath = <String>['Mouth', 'Tongue_Comp'];

    var timeRemap = ValueDelegate.timeRemap(keyPath, callback: (currentValue) {
      if (distanceToMouse.value > minTongueRadius.value &&
          distanceToMouse.value < maxTongueRadius.value &&
          !isActive.value) {
        animateTongue();
      }
      if (isActive.value) {
        final now = DateTime.now();
        tongueCurrentTime = 2 *
            (now.millisecondsSinceEpoch - tongueInitialAnimationTime) /
            1000;
      }
      if (tongueCurrentTime > 2) {
        tongueCurrentTime = 0;
        resetTongue();
      }
      return tongueCurrentTime;
    });

    delegates.add(timeRemap);

    keyPath = <String>['Mouth', 'Tongue_Comp'];
    var rotation =
        ValueDelegate.transformRotation(keyPath, callback: (currentValue) {
      return angle.value;
    });
    delegates.add(rotation);
    return delegates;
  }

  void setElapsedTime(double elapsed) {
    _elapsed = elapsed;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _frameTime += _elapsed;
    if (_frameTime > composition.seconds) {
      _frameTime = 0;
    }
    drawable
      ..setProgress(_frameTime / composition.seconds)
      ..draw(canvas, Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
