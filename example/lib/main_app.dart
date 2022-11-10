import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:lottie/lottie.dart';
import 'src/all_files.g.dart';

final _logger = Logger('main_app');

void main() {
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(print);
  Lottie.traceEnabled = true;
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //showPerformanceOverlay: true,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Lottie Flutter'),
        ),
        body: GridView.builder(
          primary: true,
          itemCount: files.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4),
          itemBuilder: (context, index) {
            var assetName = files[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (context) => Detail(assetName)));
              },
              child: _Item(
                child: Lottie.asset(
                  assetName,
                  fit: BoxFit.contain,
                  onWarning: (w) => _logger.info('$assetName - $w'),
                  frameBuilder: (context, child, composition) {
                    return AnimatedOpacity(
                      opacity: composition == null ? 0 : 1,
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final Widget child;

  const _Item({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(2, 2),
                  blurRadius: 5)
            ]),
        child: child,
      ),
    );
  }
}

class Detail extends StatefulWidget {
  final String assetName;

  const Detail(this.assetName, {super.key});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> with TickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assetName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Lottie.asset(
                widget.assetName,
                controller: _controller,
                onLoaded: (composition) {
                  _controller.duration = composition.duration;
                  _controller.repeat();
                },
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Row(
                children: <Widget>[
                  Expanded(
                    child: Slider(
                      value: _controller.value,
                      onChanged: (newValue) {
                        _controller.value = newValue;
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(_controller.isAnimating
                        ? Icons.stop
                        : Icons.play_arrow),
                    onPressed: () {
                      setState(() {
                        if (_controller.isAnimating) {
                          _controller.stop();
                        } else {
                          _controller.repeat();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
