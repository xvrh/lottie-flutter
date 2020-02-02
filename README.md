# Lottie for Flutter

Lottie is a mobile library for Android and iOS that parses [Adobe After Effects](http://www.adobe.com/products/aftereffects.html) 
animations exported as json with [Bodymovin](https://github.com/bodymovin/bodymovin) and renders them natively on mobile!

This repository is a unofficial conversion of the [Lottie-android](https://github.com/airbnb/lottie-android) library in pure Dart. 

It works on Android, iOS and macOS. ([Web support is coming](https://github.com/xvrh/lottie-flutter#flutter-web))

## Usage

### Simple animation
This example shows how to display a Lottie animation in the simplest way.  
The `Lottie` widget will load the json file and run the animation indefinitely.

```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
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
            Lottie.asset('assets/lottiesfiles/angel.zip'),
          ],
        ),
      ),
    );
  }
}
```

To load an animation from your assets folder, we need to add an `assets` section in the `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/
```

### Specifiy a custom `AnimationController`
This example shows how you can have full control over the animation with a custom `AnimationController`.

```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  AnimationController _controller;

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
            Lottie.network(
              'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/sample_app/assets/Mobilo/C.json',
              controller: _controller,
              onLoaded: (composition) {
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
This example shows how to load and parse a Lottie composition from a json file.  

The `Lottie` widget has several convenient constructors (`Lottie.asset`, `Lottie.network`, `Lottie.memory`) to load, parse and
cache automatically the json file.

Sometime you may prefer to have full control over the loading of the file. Use `LottieComposition.fromByteData` to 
parse the file from a list of bytes.
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<LottieComposition> _composition;

  @override
  void initState() {
    super.initState();

    _composition = _loadComposition();
  }

  Future<LottieComposition> _loadComposition() async {
    var assetData = await rootBundle.load('assets/LottieLogo1.json');
    return await LottieComposition.fromByteData(assetData);
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
          return Center(child: CircularProgressIndicator());
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

  const CustomDrawer(this.composition, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Painter(composition),
      size: Size(400, 400),
    );
  }
}

class _Painter extends CustomPainter {
  final LottieComposition composition;

  _Painter(this.composition);

  @override
  void paint(Canvas canvas, Size size) {
    var drawable = LottieDrawable(composition);

    for (var i = 0; i < 40; i++) {
      drawable.draw(canvas, Offset(i % 10 * 50.0, i ~/ 10 * 80.0) & (size / 5),
          progress: i / 40);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
````

## Limitations
This is a new library so usability, documentation and performance are still work in progress.

The following features are not yet implemented:
- Text in animations has very basic support (unoptimized and buggy) 
- Dash path effects
- Transforms on gradients (stroke and fills)
- Loading an animation and its images from a ZIP file
- Expose `Value callback` to modify dynamically some properties of the animation

## Flutter Web
Run the app with `flutter run -d Chrome --dart-define=FLUTTER_WEB_USE_SKIA=true --release`

The performance are not great and some features are missing.

See a preview here: https://xvrh.github.io/lottie-flutter/index.html

## Complete example
See the Sample app (in the `example` folder) for a complete example of the various possibilities.
