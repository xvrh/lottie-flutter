# Lottie for Flutter

[![](https://github.com/xvrh/lottie-flutter/workflows/Lottie%20Flutter/badge.svg?branch=master)](https://github.com/xvrh/lottie-flutter)
[![pub package](https://img.shields.io/pub/v/lottie.svg)](https://pub.dev/packages/lottie)

Lottie is a mobile library for Android and iOS that parses [Adobe After Effects](https://www.adobe.com/products/aftereffects.html) 
animations exported as json with [Bodymovin](https://github.com/airbnb/lottie-web) and renders them natively on mobile!

This repository is an unofficial conversion of the [Lottie-android](https://github.com/airbnb/lottie-android) library in pure Dart. 

It works on Android, iOS, macOS, linux, windows and web.

<a href="https://www.buymeacoffee.com/xvrh" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="60" width="217"></a>

## Usage

### Simple animation
This example shows how to display a Lottie animation in the simplest way.  
The `Lottie` widget will load the json file and run the animation indefinitely.

```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            // Load a Lottie file from your assets
            Lottie.asset('assets/LottieLogo1.json'),

            // Load a Lottie file from a remote url
            Lottie.network(
                'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json'),

            // Load an animation and its images from a zip file
            Lottie.asset('assets/lottiefiles/angel.zip'),
          ],
        ),
      ),
    );
  }
}
```

### Specify a custom `AnimationController`
This example shows how to take full control over the animation by providing your own `AnimationController`.

With a custom `AnimationController` you have a rich API to play the animation in various ways: start and stop the animation when you want,
 play forward or backward, loop between specifics points...  

```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            Lottie.asset(
              'assets/LottieLogo1.json',
              controller: _controller,
              onLoaded: (composition) {
                // Configure the AnimationController with the duration of the
                // Lottie file and start the animation.
                _controller
                  ..duration = composition.duration
                  ..forward();
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

[See this file](https://github.com/xvrh/lottie-flutter/blob/master/example/lib/examples/animation_full_control.dart) for a more comprehensive example.

### Control the size of the Widget
The `Lottie` widget takes the same arguments and have the same behavior as the `Image` widget
in term of controlling its size.
```dart
Lottie.asset(
  'assets/LottieLogo1.json',
  width: 200,
  height: 200,
  fit: BoxFit.fill,
)
```

`width` and `height` are optionals and fallback on the size imposed by the parent or on the intrinsic size of the lottie 
animation.

### Custom loading
The `Lottie` widget has several convenient constructors (`Lottie.asset`, `Lottie.network`, `Lottie.memory`) to load, parse and
cache automatically the json file.

Sometime you may prefer to have full control over the loading of the file. Use `AssetLottie` (or `NetworkLottie`, `MemoryLottie`) to load a lottie composition from a json file.

This example shows how to load and parse a Lottie composition from a json file.  

```dart
class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final Future<LottieComposition> _composition;

  @override
  void initState() {
    super.initState();

    _composition = AssetLottie('assets/LottieLogo1.json').load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LottieComposition>(
      future: _composition,
      builder: (context, snapshot) {
        var composition = snapshot.data;
        if (composition != null) {
          return Lottie(composition: composition);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
```

### Custom drawing
This example goes low level and shows you how to draw a `LottieComposition` on a custom Canvas at a specific frame in 
a specific position and size.

````dart
class CustomDrawer extends StatelessWidget {
  final LottieComposition composition;

  const CustomDrawer(this.composition, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Painter(composition),
      size: const Size(400, 400),
    );
  }
}

class _Painter extends CustomPainter {
  final LottieDrawable drawable;

  _Painter(LottieComposition composition)
      : drawable = LottieDrawable(composition);

  @override
  void paint(Canvas canvas, Size size) {
    var frameCount = 40;
    var columns = 10;
    for (var i = 0; i < frameCount; i++) {
      var destRect = Offset(i % columns * 50.0, i ~/ 10 * 80.0) & (size / 5);
      drawable
        ..setProgress(i / frameCount)
        ..draw(canvas, destRect);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
````

### Modify properties at runtime
This example shows how to modify some properties of the animation at runtime. Here we change the text,
the color, the opacity and the position of some layers.
For each `ValueDelegate` we can either provide a static `value` or a `callback` to compute a value for a each frame.

````dart
class _Animation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/Tests/Shapes.json',
      delegates: LottieDelegates(
        text: (initialText) => '**$initialText**',
        values: [
          ValueDelegate.color(
            const ['Shape Layer 1', 'Rectangle', 'Fill 1'],
            value: Colors.red,
          ),
          ValueDelegate.opacity(
            const ['Shape Layer 1', 'Rectangle'],
            callback: (frameInfo) => (frameInfo.overallProgress * 100).round(),
          ),
          ValueDelegate.position(
            const ['Shape Layer 1', 'Rectangle', '**'],
            relative: const Offset(100, 200),
          ),
        ],
      ),
    );
  }
}
````

### Frame rate
By default, the animation is played at the frame rate exported by AfterEffect.
This is the most power-friendly as generally the animation is exported at 10 or 30 FPS compared to the phone's 60 or 120 FPS.
If the result is not good, you can change the frame rate

````dart
Lottie.asset('anim.json',
  // Use the device frame rate (up to 120FPS)
  frameRate: FrameRate.max,
  // Use the exported frame rate (default)
  frameRate: FrameRate.composition,
  // Specific frame rate
  frameRate: FrameRate(10),
)
````

### Telegram Stickers (.tgs) and DotLottie (.lottie)
TGS file can be loaded by providing a special decoder

````dart
Widget build(BuildContext context) {
  return ListView(
    children: [
      Lottie.network(
        'https://telegram.org/file/464001484/1/bzi7gr7XRGU.10147/815df2ef527132dd23',
        decoder: LottieComposition.decodeGZip,
      ),
      Lottie.asset(
        'assets/LightningBug_file.tgs',
        decoder: LottieComposition.decodeGZip,
      ),
    ],
  );
}
````

You can select the correct .json file from a dotlottie (.lottie) archive by providing a custom decoder

````dart
class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/cat.lottie',
      decoder: customDecoder,
    );
  }
}

Future<LottieComposition?> customDecoder(List<int> bytes) {
  return LottieComposition.decodeZip(bytes, filePicker: (files) {
    return files.firstWhereOrNull(
        (f) => f.name.startsWith('animations/') && f.name.endsWith('.json'));
  });
}
````

## Performance or excessive CPU/GPU usage

Version `v3.0` introduced the `renderCache` parameter to help reduce an excessive energy consumption.

In this mode, the frames of the animation are rendered lazily in an offscreen cache. Subsequent runs of the animation 
are cheaper to render. It helps reduce the power usage of the application at the cost of an increased memory usage.

## Limitations
This port supports the same [feature set as Lottie Android](https://airbnb.io/lottie/#/supported-features).

## Flutter Web
Run the app with `flutter run -d chrome --web-renderer canvaskit`

See a preview here: https://xvrh.github.io/lottie-flutter-web/

## More examples
See the `example` folder for more code samples of the various possibilities.
