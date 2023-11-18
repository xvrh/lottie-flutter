import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
// ignore: implementation_imports
import 'package:lottie/src/render_cache.dart';

void main() {
  globalRenderCache.enableDebugBackground = true;
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

class _Example extends StatefulWidget {
  static String _text(a) => '';

  @override
  State<_Example> createState() => _ExampleState();
}

class _ExampleState extends State<_Example> {
  int _animationCount = 1;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
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
                        enableRenderCache: true,
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
          child: Lottie.asset('assets/Mobilo/A.json',
              height: 200,
              frameRate: const FrameRate(10),
              fit: BoxFit.fill,
              enableRenderCache: true),
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
                      enableRenderCache: true,
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
                      enableRenderCache: true,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RenderCacheDebugPanel extends StatefulWidget {
  const RenderCacheDebugPanel({super.key});

  @override
  State<RenderCacheDebugPanel> createState() => _RenderCacheDebugPanelState();
}

class _RenderCacheDebugPanelState extends State<RenderCacheDebugPanel> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
        stream: globalRenderCache.onUpdate,
        builder: (context, snapshot) {
          return ListView(
            children: [
              Text('Images: ${globalRenderCache.imageCount}'),
              Text(
                  'Memory: ${(globalRenderCache.totalMemory / 1000000).toStringAsFixed(1)}MB'),
              const Divider(),
              ElevatedButton(
                onPressed: () {
                  globalRenderCache.clear();
                },
                child: const Text('Clear'),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Enable debug background'),
                value: globalRenderCache.enableDebugBackground,
                onChanged: (v) {
                  setState(() {
                    globalRenderCache.enableDebugBackground = v;
                  });
                },
              )
            ],
          );
        });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
