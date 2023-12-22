import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: true,
      color: Colors.white,
      home: Column(
        children: [
          Container(
            height: 170,
            color: Colors.white,
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Render cache'),
              ),
              drawer: const Drawer(
                child: Column(
                  children: [
                    Expanded(
                      child: RenderCacheDebugPanel(),
                    ),
                  ],
                ),
              ),
              body: _Example(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _Row(
          builder: (cache) {
            return Lottie.asset('assets/Mobilo/Z.json',
                renderCache: cache, height: 100);
          },
        ),
        for (var fit in [BoxFit.cover, BoxFit.fill, BoxFit.contain])
          _Row(
            builder: (cache) {
              return Lottie.asset(
                'assets/lottiefiles/bb8.json',
                renderCache: cache,
                fit: fit,
                height: 60,
              );
            },
          ),
        _Row(
          builder: (cache) {
            return Lottie.asset(
              'assets/lottiefiles/a_mountain.json',
              renderCache: cache,
              height: 40,
            );
          },
        ),
        for (var align in [
          Alignment.bottomCenter,
          Alignment.center,
          Alignment.topRight
        ])
          _Row(
            builder: (cache) {
              return Lottie.asset('assets/lottiefiles/bomb.json',
                  renderCache: cache, height: 40, alignment: align);
            },
          ),

        /*
        ElevatedButton(
          onPressed: () {
            setState(() {
              ++_animationCount;
            });
          },
          child: Text('Add animation $_animationCount'),
        ),
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  for (var i = 0; i < _animationCount; i++)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: Lottie.asset(
                        'assets/Mobilo/B.json',
                        height: 200,
                        frameRate: const FrameRate(60),
                        fit: BoxFit.cover,
                        delegates: LottieDelegates(
                          text: _Example._text,
                          values: [
                            ValueDelegate.color(['*'], value: Color(i)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Lottie.asset(
                'assets/Mobilo/B.json',
                height: 200,
                frameRate: const FrameRate(10),
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        Lottie.asset(
          'assets/Mobilo/A.json',
          height: 200,
          frameRate: const FrameRate(10),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: Lottie.asset(
            'assets/Mobilo/A.json',
            height: 200,
            frameRate: const FrameRate(10),
            fit: BoxFit.fill,
            renderCache: RenderCache.drawingCommands,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Transform.scale(
                  scale: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Lottie.asset(
                      'assets/Mobilo/A.json',
                      height: 200,
                      renderCache: RenderCache.drawingCommands,
                      frameRate: const FrameRate(10),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Transform.scale(
                  scale: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Lottie.asset(
                      'assets/Mobilo/A.json',
                      height: 200,
                      frameRate: const FrameRate(10),
                      renderCache: RenderCache.drawingCommands,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),*/
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final Widget Function(RenderCache? cache) builder;

  const _Row({required this.builder});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: Colors.green)),
      child: Row(
        children: [
          for (var cache in [
            null,
            RenderCache.raster,
            RenderCache.drawingCommands
          ])
            Expanded(child: builder(cache))
        ],
      ),
    );
  }
}

class RenderCacheDebugPanel extends StatefulWidget {
  const RenderCacheDebugPanel({super.key});

  @override
  State<RenderCacheDebugPanel> createState() => _RenderCacheDebugPanelState();
}

class _RenderCacheDebugPanelState extends State<RenderCacheDebugPanel> {
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();

    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        // refresh
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Images: ${RenderCache.raster.store.imageCount}'),
        Text(
            'Memory: ${(RenderCache.raster.store.totalMemory / 1000000).toStringAsFixed(1)}MB'),
        const Divider(),
      ],
    );
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }
}
