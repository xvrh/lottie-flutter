import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:lottie/lottie.dart';
import 'src/all_files.g.dart';

void main() {
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(print);
  Lottie.traceEnabled = true;
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //showPerformanceOverlay: true,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Lottie Flutter'),
        ),
        body: GridView.builder(
          itemCount: files.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
          itemBuilder: (context, index) {
            var assetName = files[index];
            return GestureDetector(
              child: _Item(
                child: Lottie.asset(
                  assetName,
                  frameBuilder: (context, child, composition) {
                    return AnimatedOpacity(
                      child: child,
                      opacity: composition == null ? 0 : 1,
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (context) => Detail(assetName)));
              },
            );
          },
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final Widget child;

  const _Item({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: Offset(2, 2),
                  blurRadius: 5)
            ]),
        child: child,
      ),
    );
  }
}

class Detail extends StatefulWidget {
  final String assetName;

  const Detail(this.assetName, {Key? key}) : super(key: key);

  @override
  _DetailState createState() => _DetailState();
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
        title: Text('${widget.assetName}'),
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
