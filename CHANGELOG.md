## [0.4.0+1]
- Support latest version of the `characters` package

## [0.4.0]
- Disable "Merge paths" by default and provide an option to enable them.  
This is the same behavior as in Lottie-android.  
Merge paths currently don't work if the the operand shape is entirely contained within the
first shape. If you need to cut out one shape from another shape, use an even-odd fill type
instead of using merge paths.

Merge paths can be enabled with:
```dart
Lottie.asset('file.json', options: LottieOptions(enableMergePaths: true));
```


## [0.3.6]
- Export the `Marker` class

## [0.3.5]
- Fix a bug with a wrongly clipped rectangle. 

## [0.3.4]
- Fix a bug with dashed path

## [0.3.3]
- Fix a bug with rounded rectangle shape

## [0.3.2]
- Fix a bug with "repeater" content

## [0.3.1]
- Support dashed path

## [0.3.0+1]
- Specify a version range for the dependency on `characters`.

## [0.3.0]
- Add `LottieDelegates` a group of options to customize the lottie animation at runtime.
  ie: Dynamically modify color, position, size, text... of every elements of the animation.
- Correctly display Linear and Radial Gradients
- Integrate latest changes from Lottie-android

## [0.2.2]
- Add a [repeat] parameter to specify if the automatic animation should loop.
- Add the [animate], [reverse], [repeat] properties on `LottieBuilder`
- Fix bug with `onLoaded` callback when the `LottieProvider` is changed

## [0.2.1]
- Fix a big bug in the path transformation code. A lot more animations look correct now.

## [0.2.0+1]
- Improve readme
- (internal) Add golden tests

## [0.2.0]
- Support loading the animation and its images from a zip file
- Breaking: `LottieComposition.fromBytes` and `fromByteData` are now asynchronous.

## [0.1.4]
- Support images in animation
- Basic support for text in animation (work in progress)

## [0.1.3]
- Support Polystar shape
- Reorganize examples.

## [0.1.2]
- Implement `Lottie.network`, `Lottie.file` and `Lottie.memory`

## [0.1.1]
- Fix analysis lints

## [0.1.0]
- Initial conversion of [lottie-android](https://github.com/airbnb/lottie-android) to Dart/Flutter
