import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/providers/lottie_provider.dart';

void main() {
  tearDown(() {
    sharedLottieCache.clear();
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
