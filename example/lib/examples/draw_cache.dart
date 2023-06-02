import 'dart:ui';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/material.dart' as material;
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var animation = await AssetLottie('assets/AndroidWave.json').load();
  var cachedAnimation = CachedLottie(const Size(150, 200), animation);
  runApp(_Example(
    lottie: cachedAnimation,
  ));
}

class _Example extends StatelessWidget {
  final CachedLottie lottie;

  const _Example({required this.lottie});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cache'),
        ),
        body: ListView(
          children: [
            for (var i = 0; i < 20; i++)
              Stack(
                children: [
                  for (var j = 0; j < 50; j++)
                    Transform.translate(
                      offset: Offset(j.toDouble() * 20, 0),
                      child: CachedLottiePlayer(
                        lottie: lottie,
                      ),
                    )
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class CachedLottie {
  final Size size;
  final LottieComposition composition;
  final List<Image?> images;
  late final _drawable = LottieDrawable(composition);

  CachedLottie(this.size, this.composition)
      : images = List.filled(composition.durationFrames.ceil(), null);

  Duration get duration => composition.duration;

  Image imageAt(BuildContext context, double progress) {
    var index = (images.length * progress).round() % images.length;
    return images[index] ??= _takeImage(context, progress);
  }

  Image _takeImage(BuildContext context, double progress) {
    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);

    var devicePixelRatio = View.of(context).devicePixelRatio;

    _drawable
      ..setProgress(progress)
      ..draw(canvas, Offset.zero & (size * devicePixelRatio));
    var picture = recorder.endRecording();
    return picture.toImageSync((size.width * devicePixelRatio).round(),
        (size.height * devicePixelRatio).round());
  }
}

class CachedLottiePlayer extends StatefulWidget {
  final CachedLottie lottie;
  final AnimationController? controller;

  const CachedLottiePlayer({
    super.key,
    required this.lottie,
    this.controller,
  });

  @override
  State<CachedLottiePlayer> createState() => _CachedLottiePlayerState();
}

class _CachedLottiePlayerState extends State<CachedLottiePlayer>
    with TickerProviderStateMixin {
  late final AnimationController _autoController =
      AnimationController(vsync: this, duration: widget.lottie.duration)
        ..repeat();

  @override
  Widget build(BuildContext context) {
    var controller = widget.controller ?? _autoController;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        var image = widget.lottie.imageAt(context, controller.value);
        return material.RawImage(
          image: image,
          width: widget.lottie.size.width,
          height: widget.lottie.size.height,
        );
      },
    );
  }

  @override
  void dispose() {
    _autoController.dispose();
    super.dispose();
  }
}
