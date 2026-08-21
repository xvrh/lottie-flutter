import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lottie/lottie.dart';

/// Interactive demo to observe the frame-rate throttling of the auto-animation.
///
/// Run with: flutter run -t lib/frame_rate_demo.dart --profile
///
/// The metrics bar at the top shows the *engine* frame rate: the number of
/// frames the whole pipeline (build/paint/composite/raster) produces per
/// second. This is what the throttling reduces and what drives CPU/battery
/// usage. To correlate with CPU, run: `top -pid <pid of the app>`
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _EngineMetrics.install();
  runApp(const FrameRateDemoApp());
}

typedef _MetricsSample = ({int frames, double buildMs, double rasterMs});

class _EngineMetrics {
  // A single record notifier: records compare by field, so an update where any
  // field changed always notifies (three separate ValueNotifiers would skip
  // notification when e.g. the frame count stays constant, freezing the
  // build/raster readouts exactly in steady state).
  static final sample = ValueNotifier<_MetricsSample>((
    frames: 0,
    buildMs: 0,
    rasterMs: 0,
  ));

  static void install() {
    var count = 0;
    var buildSum = 0.0;
    var rasterSum = 0.0;
    SchedulerBinding.instance.addTimingsCallback((timings) {
      count += timings.length;
      for (var t in timings) {
        buildSum += t.buildDuration.inMicroseconds / 1000;
        rasterSum += t.rasterDuration.inMicroseconds / 1000;
      }
    });
    Timer.periodic(const Duration(seconds: 1), (_) {
      sample.value = (
        frames: count,
        buildMs: count > 0 ? buildSum / count : 0,
        rasterMs: count > 0 ? rasterSum / count : 0,
      );
      // ignore: avoid_print
      print('frames/s: $count');
      count = 0;
      buildSum = 0;
      rasterSum = 0;
    });
  }
}

class FrameRateDemoApp extends StatelessWidget {
  const FrameRateDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: FrameRateDemoPage());
  }
}

const _assets = {
  'fireworks (15fps)': 'assets/17297-fireworks.json',
  'tent (24fps)': 'assets/tent.json',
  'battery (25fps)': 'assets/battery_optimizations.json',
  'LottieLogo1 (30fps)': 'assets/LottieLogo1.json',
  'AndroidWave (60fps)': 'assets/AndroidWave.json',
  'TwitterHeart (60fps)': 'assets/TwitterHeartButton.json',
};

const _frameRates = {
  'composition': FrameRate.composition,
  '5fps': FrameRate(5),
  '15fps': FrameRate(15),
  '30fps': FrameRate(30),
  '60fps': FrameRate(60),
  'max': FrameRate.max,
};

class FrameRateDemoPage extends StatefulWidget {
  const FrameRateDemoPage({super.key});

  @override
  State<FrameRateDemoPage> createState() => _FrameRateDemoPageState();
}

class _FrameRateDemoPageState extends State<FrameRateDemoPage>
    with SingleTickerProviderStateMixin {
  var _asset = 'LottieLogo1 (30fps)';
  var _frameRate = 'composition';
  var _animate = true;
  var _repeat = true;
  var _reverse = false;
  var _tickerMode = true;
  var _externalController = false;
  var _count = 1;
  var _stagger = false;
  double? _compositionFrameRate;
  AnimationController? _controller;

  AnimationController get _vsyncController {
    return _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _lottie(int index, {FrameRate? frameRate, double size = 150}) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _assets[_asset]!,
        frameRate: frameRate ?? _frameRates[_frameRate],
        animate: _animate,
        repeat: _repeat,
        reverse: _reverse,
        controller: _externalController ? _vsyncController : null,
        onLoaded: (composition) {
          if (_compositionFrameRate != composition.frameRate) {
            setState(() => _compositionFrameRate = composition.frameRate);
            _controller?.duration = composition.duration;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var displayHz = View.of(context).display.refreshRate;
    return Scaffold(
      appBar: AppBar(title: const Text('Frame rate throttling demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MetricsBar(displayHz: displayHz),
          const SizedBox(height: 8),
          Text(
            'Composition: $_asset'
            '${_compositionFrameRate != null ? ' — fr=$_compositionFrameRate' : ''}'
            ' | Expected engine rate: ${_expectedRate(displayHz)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 32),
          _section('Asset'),
          _choices(
            _assets.keys,
            _asset,
            (v) => setState(() {
              _asset = v;
              _compositionFrameRate = null;
            }),
          ),
          _section('frameRate parameter'),
          _choices(
            _frameRates.keys,
            _frameRate,
            (v) => setState(() => _frameRate = v),
          ),
          _section('Behaviour'),
          Wrap(
            spacing: 8,
            children: [
              _toggle('animate', _animate, (v) => setState(() => _animate = v)),
              _toggle('repeat', _repeat, (v) => setState(() => _repeat = v)),
              _toggle('reverse', _reverse, (v) => setState(() => _reverse = v)),
              _toggle(
                'TickerMode',
                _tickerMode,
                (v) => setState(() => _tickerMode = v),
              ),
              _toggle(
                'external AnimationController (vsync baseline)',
                _externalController,
                (v) => setState(() {
                  _externalController = v;
                  // Stop the vsync controller when unused: an orphaned
                  // repeat() would keep pumping display-rate frames and mask
                  // the throttling this demo exists to show.
                  if (v) {
                    _vsyncController.repeat();
                  } else {
                    _controller?.stop();
                  }
                }),
              ),
            ],
          ),
          _section('Concurrent animations: $_count'),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _count.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  onChanged: (v) => setState(() => _count = v.round()),
                ),
              ),
              _toggle(
                'stagger phases',
                _stagger,
                (v) => setState(() => _stagger = v),
              ),
            ],
          ),
          const Divider(height: 32),
          TickerMode(
            enabled: _tickerMode,
            child: Wrap(
              children: [
                for (var i = 0; i < _count; i++)
                  _DelayedMount(
                    key: ValueKey('$_asset-$i-$_stagger'),
                    delay: _stagger
                        ? Duration(milliseconds: 137 * i)
                        : Duration.zero,
                    placeholderSize: 150,
                    child: _lottie(i),
                  ),
              ],
            ),
          ),
          const Divider(height: 32),
          _section('Side by side: throttled (left) vs every vsync (right)'),
          const Text(
            'Both show the same frames of the same composition; '
            'compare motion smoothness to spot pacing artifacts.',
          ),
          const SizedBox(height: 8),
          TickerMode(
            enabled: _tickerMode,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    _lottie(100, frameRate: FrameRate.composition, size: 180),
                    const Text('FrameRate.composition'),
                  ],
                ),
                Column(
                  children: [
                    _lottie(101, frameRate: FrameRate.max, size: 180),
                    const Text('FrameRate.max'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const _CoverPage(),
                ),
              );
            },
            child: const Text('Push a route on top (TickerMode auto-mute)'),
          ),
          const SizedBox(height: 8),
          const Text(
            'While the route covers this page, the animations below it must '
            'stop producing frames entirely. Also try minimizing the window: '
            'CPU should drop to ~0 (watch with: top -pid <pid>).',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _expectedRate(double displayHz) {
    if (_externalController) return '~${displayHz.round()} (vsync driven)';
    if (!_animate || !_tickerMode) return '~0';
    var fps = _frameRates[_frameRate]!.resolveFps(_compositionFrameRate);
    if (fps == null || fps >= displayHz) {
      return '~${displayHz.round()} (throttle no-op)';
    }
    return '~${fps.round()}';
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _choices(
    Iterable<String> values,
    String selected,
    ValueChanged<String> onChanged,
  ) {
    return Wrap(
      spacing: 8,
      children: [
        for (var value in values)
          ChoiceChip(
            label: Text(value),
            selected: value == selected,
            onSelected: (_) => onChanged(value),
          ),
      ],
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
    );
  }
}

class _MetricsBar extends StatelessWidget {
  final double displayHz;

  const _MetricsBar({required this.displayHz});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ValueListenableBuilder(
          valueListenable: _EngineMetrics.sample,
          builder: (context, sample, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metric(context, 'Engine frames/s', '${sample.frames}'),
                _metric(context, 'Display', '${displayHz.round()}Hz'),
                _metric(
                  context,
                  'avg build',
                  '${sample.buildMs.toStringAsFixed(1)}ms',
                ),
                _metric(
                  context,
                  'avg raster',
                  '${sample.rasterMs.toStringAsFixed(1)}ms',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Mounts [child] after [delay], so that several animations start out of
/// phase: their throttle timers then request frames at different instants,
/// showing how the savings degrade as concurrent timers stop coalescing.
class _DelayedMount extends StatefulWidget {
  final Duration delay;
  final double placeholderSize;
  final Widget child;

  const _DelayedMount({
    super.key,
    required this.delay,
    required this.placeholderSize,
    required this.child,
  });

  @override
  State<_DelayedMount> createState() => _DelayedMountState();
}

class _DelayedMountState extends State<_DelayedMount> {
  Timer? _timer;
  late bool _ready = widget.delay == Duration.zero;

  @override
  void initState() {
    super.initState();
    if (!_ready) {
      _timer = Timer(widget.delay, () => setState(() => _ready = true));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ready
        ? widget.child
        : SizedBox.square(dimension: widget.placeholderSize);
  }
}

class _CoverPage extends StatelessWidget {
  const _CoverPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Covering route')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'The demo page below is covered: TickerMode mutes its\n'
              'animations and no frames should be produced at all.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: _EngineMetrics.sample,
              builder: (context, sample, _) => Text(
                'Engine frames/s: ${sample.frames}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            const Text('(~1 frame/s from this counter itself)'),
          ],
        ),
      ),
    );
  }
}
