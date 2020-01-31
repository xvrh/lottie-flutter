# Lottie for Flutter

Lottie is a mobile library for Android and iOS that parses [Adobe After Effects](http://www.adobe.com/products/aftereffects.html) 
animations exported as json with [Bodymovin](https://github.com/bodymovin/bodymovin) and renders them natively on mobile!

This repository is a unofficial conversion of the [Lottie-android](https://github.com/airbnb/lottie-android) library in pure Dart. 

It works on Android, iOS and macOS. ([Web support is coming](https://github.com/xvrh/lottie-flutter#flutter-web-support))

## Usage

### Simple animation
This example shows how to display a Lottie animation in the simplest way.  
The `Lottie` widget will load the json file and run the animation indefinitely.

Add a Lottie .json file in your asset folder (example `assets/LottieLogo1.json`).  
Specify the asset folder in your `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/
```

Run this code:
```dart
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Lottie.asset('assets/LottieLogo1.json'),
    );
  }
}
```

### Specifiy a custom `AnimationController`
This example shows how you can have full control over the animation with a custom `AnimationController`.

```dart
void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyApp2State createState() => _MyApp2State();
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
    return Container(
      child: Lottie.asset(
        'assets/LottieLogo1.json',
        controller: _controller,
        onLoaded: (composition) {
          _controller
            ..duration = composition.duration
            ..forward();
        },
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
    return LottieComposition.fromByteData(assetData);
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

    for (int i = 0; i < 10; i++) {
      drawable.draw(canvas, Offset(i * 20.0, i * 20.0) & (size / 5),
          progress: i / 10);
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

The following features are not implemented:
- Images in animations (will come soon)
- Text in animations (will come soon)
- Dash path effects
- Transforms on gradients (stroke and fills)
- Loading an animation and its images from a ZIP file

## Flutter Web support
Run the app with `flutter run -d Chrome --dart-define=FLUTTER_WEB_USE_SKIA=true --release`

The performance are not great, some features are missing and they are a few errors.

## Complete example
See the Sample app (in the `sample_app` folder) for a complete example of the various possibilities.
http://xvrh.github.io/lottie-flutter/sample.html