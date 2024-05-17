import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  tearDown(() {
    Lottie.cache.clear();
  });

  testWidgets('Should settle if no animation', (tester) async {
    var data = File('example/assets/HamburgerArrow.json').readAsBytesSync();
    var composition = await LottieComposition.fromBytes(data);

    await tester.pumpWidget(Lottie(
      composition: composition,
      animate: false,
    ));

    await tester.pumpAndSettle();
  });

  testWidgets('onLoaded called with the correct composition', (tester) async {
    late LottieComposition composition;

    var file = SynchronousFile(File('example/assets/HamburgerArrow.json'));

    await tester.pumpWidget(LottieBuilder.file(
      file,
      onLoaded: (c) {
        composition = c;
      },
    ));

    await tester.pump();

    expect(composition.endFrame, 179.99);
  });

  testWidgets('onLoaded called when remplacing the widget animation',
      (tester) async {
    var hamburgerData =
        Future.value(bytesForFile('example/assets/HamburgerArrow.json'));
    var androidData =
        Future.value(bytesForFile('example/assets/AndroidWave.json'));

    var mockAsset = FakeAssetBundle({
      'hamburger.json': hamburgerData,
      'android.json': androidData,
    });

    var animation = AnimationController(vsync: tester);

    LottieComposition? composition;
    await tester.pumpWidget(
      Lottie.asset(
        'hamburger.json',
        controller: animation,
        bundle: mockAsset,
        onLoaded: (c) {
          composition = c;
        },
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    //expect(find.byType(Lottie), findsOneWidget);
    expect(composition, isNotNull);
    expect(composition!.duration, const Duration(seconds: 6));

    composition = null;

    await tester.pumpWidget(
      Lottie.asset(
        'android.json',
        controller: animation,
        bundle: mockAsset,
        onLoaded: (c) {
          composition = c;
        },
      ),
    );

    await tester.pump();
    expect(composition, isNotNull);
    expect(composition!.duration, const Duration(seconds: 2, milliseconds: 50));
  });

  testWidgets('onLoaded data race 1', (tester) async {
    var hamburgerCompleter = Completer<ByteData>();
    var androidCompleter = Completer<ByteData>();

    var hamburgerData = bytesForFile('example/assets/HamburgerArrow.json');
    var androidData = bytesForFile('example/assets/AndroidWave.json');

    var mockAsset = FakeAssetBundle({
      'hamburger.json': hamburgerCompleter.future,
      'android.json': androidCompleter.future,
    });

    var animation = AnimationController(vsync: tester);

    var onLoadedCount = 0;

    LottieComposition? composition;
    await tester.pumpWidget(
      Lottie.asset(
        'hamburger.json',
        controller: animation,
        bundle: mockAsset,
        onLoaded: (c) {
          composition = c;
          ++onLoadedCount;
        },
      ),
    );
    await tester.pump();
    expect(
        find.byWidgetPredicate((w) => w is RawLottie && w.composition == null),
        findsOneWidget);
    expect(composition, isNull);
    expect(onLoadedCount, 0);

    await tester.pumpWidget(
      Lottie.asset(
        'android.json',
        controller: animation,
        bundle: mockAsset,
        onLoaded: (c) {
          composition = c;
          ++onLoadedCount;
        },
      ),
    );

    await tester.pump();
    expect(composition, isNull);
    expect(onLoadedCount, 0);

    hamburgerCompleter.complete(hamburgerData);

    await tester.pump();
    expect(composition, isNull);
    expect(onLoadedCount, 0);

    androidCompleter.complete(androidData);

    await tester.pump();
    expect(composition!.duration, const Duration(seconds: 2, milliseconds: 50));
    expect(onLoadedCount, 1);
  });

  testWidgets('onLoaded data race 2', (tester) async {
    var hamburgerCompleter = Completer<ByteData>();
    var androidCompleter = Completer<ByteData>();

    var hamburgerData = bytesForFile('example/assets/HamburgerArrow.json');
    var androidData = bytesForFile('example/assets/AndroidWave.json');

    var mockAsset = FakeAssetBundle({
      'hamburger.json': hamburgerCompleter.future,
      'android.json': androidCompleter.future,
    });

    var animation = AnimationController(vsync: tester);

    var onLoadedCount = 0;

    LottieComposition? composition;
    await tester.pumpWidget(
      Lottie.asset(
        'hamburger.json',
        controller: animation,
        bundle: mockAsset,
        onLoaded: (c) {
          composition = c;
          ++onLoadedCount;
        },
      ),
    );
    await tester.pump();
    expect(
        find.byWidgetPredicate((w) => w is RawLottie && w.composition == null),
        findsOneWidget);
    expect(composition, isNull);
    expect(onLoadedCount, 0);

    await tester.pumpWidget(
      Lottie.asset(
        'android.json',
        controller: animation,
        bundle: mockAsset,
        onLoaded: (c) {
          composition = c;
          ++onLoadedCount;
        },
      ),
    );

    await tester.pump();
    expect(composition, isNull);
    expect(onLoadedCount, 0);

    androidCompleter.complete(androidData);

    await tester.pump();
    expect(composition!.duration, const Duration(seconds: 2, milliseconds: 50));
    expect(onLoadedCount, 1);

    hamburgerCompleter.complete(hamburgerData);

    await tester.pump();
    expect(composition!.duration, const Duration(seconds: 2, milliseconds: 50));
    expect(onLoadedCount, 1);
  });

  testWidgets('Should auto animate', (tester) async {
    var composition = await LottieComposition.fromBytes(
        File('example/assets/HamburgerArrow.json').readAsBytesSync());

    await tester.pumpWidget(Lottie(composition: composition));

    await tester.pump();

    var lottie =
        tester.firstWidget<AnimatedBuilder>(find.byType(AnimatedBuilder));
    expect(lottie.listenable, isNotNull);
    expect((lottie.listenable as AnimationController).duration,
        const Duration(seconds: 6));
    expect((lottie.listenable as AnimationController).isAnimating, true);

    await tester.pumpWidget(Lottie(
      composition: composition,
      animate: false,
    ));

    lottie = tester.firstWidget<AnimatedBuilder>(find.byType(AnimatedBuilder));
    expect(lottie.listenable, isNotNull);
    expect((lottie.listenable as AnimationController).duration,
        const Duration(seconds: 6));
    expect((lottie.listenable as AnimationController).isAnimating, false);

    await tester.pumpWidget(Lottie(
      composition: composition,
    ));

    lottie = tester.firstWidget<AnimatedBuilder>(find.byType(AnimatedBuilder));
    expect(lottie.listenable, isNotNull);
    expect((lottie.listenable as AnimationController).duration,
        const Duration(seconds: 6));

    var animationController = AnimationController(
        vsync: tester, duration: const Duration(seconds: 2));

    await tester.pumpWidget(Lottie(
      composition: composition,
      controller: animationController.view,
    ));

    lottie = tester.firstWidget<AnimatedBuilder>(find.byType(AnimatedBuilder));
    expect(lottie.listenable, isNotNull);
    expect((lottie.listenable as AnimationController).duration,
        const Duration(seconds: 2));

    await tester.pumpWidget(Lottie(
      composition: composition,
      controller: animationController.view,
      animate: false,
    ));

    lottie = tester.firstWidget<AnimatedBuilder>(find.byType(AnimatedBuilder));
    expect(lottie.listenable, isNotNull);
    expect((lottie.listenable as AnimationController).duration,
        const Duration(seconds: 2));

    await tester.pumpWidget(Lottie(
      composition: composition,
      animate: false,
    ));

    lottie = tester.firstWidget<AnimatedBuilder>(find.byType(AnimatedBuilder));
    expect(lottie.listenable, isNotNull);
    expect((lottie.listenable as AnimationController).duration,
        const Duration(seconds: 6));
    expect((lottie.listenable as AnimationController).isAnimating, false);
  });

  testWidgets('errorBuilder called when error', (tester) async {
    var hamburgerData =
        Future.value(bytesForFile('example/assets/HamburgerArrow.json'));
    var mockAsset = FakeAssetBundle({
      'hamburger.json': hamburgerData,
    });

    var errorKey = UniqueKey();
    var loadedCall = 0;
    await tester.pumpWidget(LottieBuilder.asset(
      'error.json',
      bundle: mockAsset,
      errorBuilder: (c, e, stackTrace) => Container(key: errorKey),
      onLoaded: (c) {
        ++loadedCall;
      },
    ));

    await tester.pump();
    expect(find.byKey(errorKey), findsOneWidget);
    expect(loadedCall, 0);

    await tester.pumpWidget(LottieBuilder.asset(
      'hamburger.json',
      bundle: mockAsset,
      errorBuilder: (c, e, stackTrace) => Container(key: errorKey),
      onLoaded: (c) {
        ++loadedCall;
      },
    ));
    await tester.pump();

    expect(find.byType(Lottie), findsOneWidget);
    expect(find.byKey(errorKey), findsNothing);
    expect(loadedCall, 1);
  });

  testWidgets('Cache should be synchronous', (tester) async {
    var hamburgerData =
        Future.value(bytesForFile('example/assets/HamburgerArrow.json'));
    var mockAsset = FakeAssetBundle({
      'hamburger.json': hamburgerData,
    });

    var loadedCall = 0;
    var lottieWidget = LottieBuilder.asset(
      'hamburger.json',
      bundle: mockAsset,
      onLoaded: (c) {
        ++loadedCall;
      },
    );

    await tester.pumpWidget(lottieWidget);
    expect(tester.widget<Lottie>(find.byType(Lottie)).composition, isNull);
    await tester.pump();
    expect(tester.widget<Lottie>(find.byType(Lottie)).composition, isNotNull);

    await tester.pumpWidget(Column(
      children: [
        lottieWidget,
        lottieWidget,
      ],
    ));
    expect(tester.widget<Lottie>(find.byType(Lottie).at(0)).composition,
        isNotNull);
    expect(tester.widget<Lottie>(find.byType(Lottie).at(1)).composition,
        isNotNull);
    expect(loadedCall, 3);
  });

  testWidgets('Cache can be cleared', (tester) async {
    var hamburgerData =
        Future.value(bytesForFile('example/assets/HamburgerArrow.json'));
    var mockAsset = FakeAssetBundle({
      'hamburger.json': hamburgerData,
    });

    var loadedCall = 0;
    var lottieWidget = LottieBuilder.asset(
      'hamburger.json',
      bundle: mockAsset,
      onLoaded: (c) {
        ++loadedCall;
      },
    );

    await tester.pumpWidget(lottieWidget);
    expect(tester.widget<Lottie>(find.byType(Lottie)).composition, isNull);
    await tester.pump();
    expect(tester.widget<Lottie>(find.byType(Lottie)).composition, isNotNull);

    Lottie.cache.clear();

    await tester.pumpWidget(Center(
      child: lottieWidget,
    ));
    expect(tester.widget<Lottie>(find.byType(Lottie)).composition, isNull);
    await tester.pump();
    expect(tester.widget<Lottie>(find.byType(Lottie)).composition, isNotNull);
    expect(loadedCall, 2);
  });

  testWidgets('onLoaded is ', (tester) async {
    var hamburgerData =
        Future.value(bytesForFile('example/assets/HamburgerArrow.json'));
    var mockAsset = FakeAssetBundle({
      'hamburger.json': hamburgerData,
    });
    var provider = AssetLottie('hamburger.json', bundle: mockAsset);

    await tester.pumpWidget(KeyedSubtree(
        key: UniqueKey(), child: _LottieWithSetStateInOnLoaded(provider)));
    var state1 = tester.state<__LottieWithSetStateInOnLoadedState>(
        find.byType(_LottieWithSetStateInOnLoaded));
    expect(state1.loadedCount, 1);
    await tester.pump();
    expect(state1.loadedCount, 1);

    await tester.pumpWidget(KeyedSubtree(
        key: UniqueKey(), child: _LottieWithSetStateInOnLoaded(provider)));
    var state2 = tester.state<__LottieWithSetStateInOnLoadedState>(
        find.byType(_LottieWithSetStateInOnLoaded));
    expect(state2.loadedCount, 1);
    await tester.pump();
    expect(state2.loadedCount, 1);
    expect(state1, isNot(state2));
  });

  testWidgets(
    'if composition is static should create Lottie with [animate] false by default',
    (tester) async {
      await tester.pumpWidget(
        LottieBuilder.memory(
          File('test/data/static_lottie.json').readAsBytesSync(),
        ),
      );
      expect(tester.hasRunningAnimations, false);
    },
  );

  testWidgets(
    'if composition is static and [animate] is true, should have animations',
    (tester) async {
      await tester.pumpWidget(
        LottieBuilder.memory(
          File('test/data/static_lottie.json').readAsBytesSync(),
          animate: true,
        ),
      );
      expect(tester.hasRunningAnimations, true);
    },
  );

  testWidgets('AssetLottie uses DefaultAssetBundle', (tester) async {
    var hamburgerData =
        Future.value(bytesForFile('example/assets/HamburgerArrow.json'));
    var mockAsset = FakeAssetBundle({
      'hamburger.json': hamburgerData,
      'other.json': hamburgerData,
    });
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: mockAsset,
        child: Lottie.asset('hamburger.json'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(RawLottie), findsOneWidget);
    expect(
        find.byWidgetPredicate((w) => w is RawLottie && w.composition != null),
        findsOneWidget);

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: mockAsset,
        child: Lottie.asset('other.json'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        find.byWidgetPredicate((w) => w is RawLottie && w.composition != null),
        findsOneWidget);
  });

  testWidgets('expected an int', (tester) async {
    var data = File('example/assets/Tests/kona_splash_animation.json')
        .readAsBytesSync();
    var composition = await LottieComposition.fromBytes(data);

    await tester.pumpWidget(Lottie(
      composition: composition,
      animate: false,
    ));

    await tester.pumpAndSettle();
  });
}

class SynchronousFile extends Fake implements File {
  final File _real;

  SynchronousFile(this._real);

  @override
  String get path => _real.path;

  @override
  Future<Uint8List> readAsBytes() => Future.value(_real.readAsBytesSync());
}

ByteData bytesForFile(String path) =>
    File(path).readAsBytesSync().buffer.asByteData();

class FakeAssetBundle extends Fake implements AssetBundle {
  final Map<String, Future<ByteData>> data;

  FakeAssetBundle(this.data);

  @override
  Future<ByteData> load(String key) {
    return data[key] ?? (Future.error('Asset $key not found'));
  }
}

class _LottieWithSetStateInOnLoaded extends StatefulWidget {
  final LottieProvider lottie;

  const _LottieWithSetStateInOnLoaded(this.lottie);

  @override
  State<_LottieWithSetStateInOnLoaded> createState() =>
      __LottieWithSetStateInOnLoadedState();
}

class __LottieWithSetStateInOnLoadedState
    extends State<_LottieWithSetStateInOnLoaded> {
  var loadedCount = 0;

  @override
  Widget build(BuildContext context) {
    return LottieBuilder(
      lottie: widget.lottie,
      onLoaded: (_) {
        setState(() {
          ++loadedCount;
        });
      },
    );
  }
}
