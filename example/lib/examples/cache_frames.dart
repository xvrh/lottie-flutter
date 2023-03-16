import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/material.dart' as material;
import 'package:lottie/lottie.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      showPerformanceOverlay: true,
      home: Scaffold(body: _App()),
    );
  }
}

class _App extends StatefulWidget {
  const _App({super.key});

  @override
  State<_App> createState() => __AppState();
}

class __AppState extends State<_App> {
  static final _animation = AssetLottie('assets/LottieLogo1.json');
  static final _size = const Size(500, 500);
  CachedPictures? _cachedPictures;
  CachedImages? _cachedImages;

  @override
  Widget build(BuildContext context) {
    var cachedPictures = _cachedPictures;
    var cachedImages = _cachedImages;
    Widget animation;
    if (cachedPictures != null) {
      animation = PicturesPlayer(pictures: cachedPictures);
    } else if (cachedImages != null) {
      animation = ImagesPlayer(images: cachedImages);
    } else {
      animation = LottieBuilder(
        lottie: _animation,
        width: _size.width,
        height: _size.height,
      );
    }

    return ListView(
      children: [
        ElevatedButton(
          onPressed: () async {
            var watch = Stopwatch()..start();

            var composition = await _animation.load();

            var pictures = buildLottiePictures(composition, _size);
            setState(() {
              _cachedPictures = pictures;
            });
            print('Build cache in ${watch.elapsed}');
          },
          child: const Text('Create cached pictures'),
        ),
        ElevatedButton(
          onPressed: () async {
            var watch = Stopwatch()..start();
            var composition = await _animation.load();

            var images = buildLottiePictures(composition, _size).toImages();
            setState(() {
              _cachedImages = images;
            });
            print('Build cache in ${watch.elapsed}');
          },
          child: const Text('Create cached pictures'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _cachedPictures = null;
              _cachedImages = null;
            });
          },
          child: Text('Clear cache'),
        ),
        Container(
          height: 300,
          child: Stack(
            children: [
              for (var i = 0; i < 100; i++)
                Positioned(left: i * 2.0, child: animation),
            ],
          ),
        ),
      ],
    );
  }
}

/*class CachedLottie extends StatefulWidget {
  final LottieProvider provider;

  const CachedLottie({super.key, required this.provider});

  @override
  State<CachedLottie> createState() => _CachedLottieState();
}

class _CachedLottieState extends State<CachedLottie>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  late Future<LottieComposition> _composition;

  @override
  void initState() {
    super.initState();
    _composition = widget.provider.load();
  }

  @override
  void didUpdateWidget(covariant CachedLottie oldWidget) {
    if (oldWidget.provider != widget.provider) {
      _controller = null;
      _composition = widget.provider.load();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LottieComposition>(
      future: _composition,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // TODO: Loading placeholder
          return const SizedBox();
        } else {
          if (snapshot.hasError) return ErrorWidget(snapshot.error!);

          var composition = snapshot.requireData;
          var controller = _controller ??= AnimationController(vsync: this)
            ..duration = composition.duration
            ..repeat();
          return _CachedLottie(
            composition,
            controller,
            key: ValueKey(composition),
          );
        }
      },
    );
  }
}

class _CachedLottie extends StatefulWidget {
  final LottieComposition composition;
  final AnimationController controller;

  const _CachedLottie(this.composition, this.controller, {super.key});

  @override
  State<_CachedLottie> createState() => __CachedLottieState();
}

class __CachedLottieState extends State<_CachedLottie> {
  late LottieDrawable _drawable;

  @override
  void initState() {
    super.initState();

    _drawable = LottieDrawable(widget.composition);

    _drawable.draw(canvas, rect);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {});
  }
}*/

class PicturesPlayer extends StatefulWidget {
  final CachedPictures pictures;

  PicturesPlayer({
    super.key,
    required this.pictures,
  });

  @override
  State<PicturesPlayer> createState() => _PicturesPlayerState();
}

class _PicturesPlayerState extends State<PicturesPlayer>
    with TickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: widget.pictures.composition.duration)
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        var picture = widget.pictures.pictureAt(_controller.value);
        return CustomPaint(
          size: widget.pictures.size,
          painter: _PicturePainter(picture),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _PicturePainter extends CustomPainter {
  final Picture picture;

  _PicturePainter(this.picture);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(covariant _PicturePainter oldDelegate) {
    return picture != oldDelegate.picture;
  }
}

class ImagesPlayer extends StatefulWidget {
  final CachedImages images;

  ImagesPlayer({
    super.key,
    required this.images,
  });

  @override
  State<ImagesPlayer> createState() => _ImagesPlayerState();
}

class _ImagesPlayerState extends State<ImagesPlayer>
    with TickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: widget.images.composition.duration)
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        var image = widget.images.imageAt(_controller.value);
        return material.RawImage(
          image: image,
          width: widget.images.size.width,
          height: widget.images.size.height,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class CachedPictures {
  final Size size;
  final LottieComposition composition;
  final List<Picture> pictures;

  CachedPictures(this.size, this.composition, this.pictures)
      : assert(pictures.length == composition.durationFrames.ceil());

  Picture pictureAt(double progress) {
    return pictures[(pictures.length * progress).round() % pictures.length];
  }

  CachedImages toImages() => CachedImages(
      size,
      composition,
      pictures
          .map((p) => p.toImageSync(size.width.round(), size.height.round()))
          .toList());
}

class CachedImages {
  final Size size;
  final LottieComposition composition;
  final List<Image> images;

  CachedImages(this.size, this.composition, this.images)
      : assert(images.length == composition.durationFrames.ceil());

  Image imageAt(double progress) {
    return images[(images.length * progress).round() % images.length];
  }
}

CachedPictures buildLottiePictures(LottieComposition composition, Size size) {
  assert(composition.startFrame <= composition.endFrame);
  var drawable = LottieDrawable(composition);

  var pictures = <Picture>[];
  for (var i = composition.startFrame; i < composition.endFrame; i++) {
    drawable.setProgress(i / composition.durationFrames);

    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);

    drawable.draw(canvas, Offset.zero & size);
    var picture = recorder.endRecording();
    pictures.add(picture);
  }
  return CachedPictures(size, composition, pictures);
}
