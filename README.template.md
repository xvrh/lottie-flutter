# Lottie for Flutter

[![](https://github.com/xvrh/lottie-flutter/workflows/Lottie%20Flutter/badge.svg?branch=master)](https://github.com/xvrh/lottie-flutter)
[![pub package](https://img.shields.io/pub/v/lottie.svg)](https://pub.dev/packages/lottie)

Lottie is a mobile library for Android and iOS that parses [Adobe After Effects](http://www.adobe.com/products/aftereffects.html) 
animations exported as json with [Bodymovin](https://github.com/airbnb/lottie-web) and renders them natively on mobile!

This repository is a unofficial conversion of the [Lottie-android](https://github.com/airbnb/lottie-android) library in pure Dart. 

It works on Android, iOS and macOS. ([Web support is coming](https://github.com/xvrh/lottie-flutter#flutter-web))

## Usage

### Simple animation
This example shows how to display a Lottie animation in the simplest way.  
The `Lottie` widget will load the json file and run the animation indefinitely.

```dart
import 'example/lib/examples/main.dart';
```

### Specify a custom `AnimationController`
This example shows how to take full control over the animation by providing your own `AnimationController`.

With a custom `AnimationController` you have a rich API to play the animation in various ways: start and stop the animation when you want,
 play forward or backward, loop between specifics points...  

```dart
import 'example/lib/examples/animation_controller.dart';
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
This example shows how to load and parse a Lottie composition from a json file.  

The `Lottie` widget has several convenient constructors (`Lottie.asset`, `Lottie.network`, `Lottie.memory`) to load, parse and
cache automatically the json file.

Sometime you may prefer to have full control over the loading of the file. Use `LottieComposition.fromByteData` to 
parse the file from a list of bytes.
```dart
import 'example/lib/examples/custom_load.dart#example';
```

### Custom drawing
This example goes low level and shows you how to draw a `LottieComposition` on a custom Canvas at a specific frame in 
a specific position and size.

````dart
import 'example/lib/examples/custom_draw.dart#example';
````

### Modify properties at runtime
This example shows how to modify some properties of the animation at runtime. Here we change the text,
the color, the opacity and the position of some layers.
For each `ValueDelegate` we can either provide a static `value` or a `callback` to compute a value for a each frame.

````dart
import 'example/lib/examples/simple_dynamic_properties.dart#example';
````

## Limitations
This is a new library so usability, documentation and performance are still work in progress.

Only the [supported features of Lottie Android](https://airbnb.io/lottie/#/supported-features)
are supported in this port.

## Flutter Web
Run the app with `flutter run -d Chrome --dart-define=FLUTTER_WEB_USE_SKIA=true --release`

The performance are not great and some features are missing.

See a preview here: https://xvrh.github.io/lottie-flutter/index.html

## Complete example
See the Sample app (in the `example` folder) for a complete example of the various possibilities.
