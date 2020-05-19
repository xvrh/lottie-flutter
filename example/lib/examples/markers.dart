import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// This example shows how to play the animation between two markers.
/// It is based on this article for lottie-ios:
/// https://medium.com/swlh/controlling-lottie-animation-with-markers-5e9035d94623
void main() async {
  runApp(App());
}

class App extends StatefulWidget {
  const App({Key key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin {
  Future<LottieComposition> _composition;

  @override
  void initState() {
    super.initState();
    _composition = AssetLottie('assets/TwitterHeartButton.json').load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Markers'),
        ),
        body: FutureBuilder<LottieComposition>(
          future: _composition,
          builder: (context, snapshot) {
            if (snapshot.hasError) return ErrorWidget(snapshot.error);
            if (!snapshot.hasData) return CircularProgressIndicator();
            return _LottieDetails(snapshot.data);
          },
        ),
      ),
    );
  }
}

class _LottieDetails extends StatefulWidget {
  final LottieComposition composition;

  const _LottieDetails(this.composition, {Key key}) : super(key: key);

  @override
  _LottieDetailsState createState() => _LottieDetailsState();
}

class _LottieDetailsState extends State<_LottieDetails>
    with TickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Lottie(
          composition: widget.composition,
          controller: _controller,
          height: 150,
        ),
        ListTile(
          title: Text('Composition start frame'),
          trailing: Text(widget.composition.startFrame.toStringAsFixed(1)),
        ),
        ListTile(
          title: Text('Composition duration'),
          trailing: Text(widget.composition.durationFrames.toStringAsFixed(1)),
        ),
        RaisedButton(
          child: Text('touchDownEnd - touchUpCancel'),
          onPressed: () => _playBetween('touchDownEnd', 'touchUpCancel'),
        ),
        RaisedButton(
          child: Text('touchDownStart - touchDownEnd'),
          onPressed: () => _playBetween('touchDownStart', 'touchDownEnd'),
        ),
        RaisedButton(
          child: Text('touchDownEnd - touchUpEnd'),
          onPressed: () => _playBetween('touchDownEnd', 'touchUpEnd'),
        ),
        for (var marker in widget.composition.markers)
          ListTile(
            title: Text(marker.name),
            subtitle: Text(
                '${marker.startFrame.toStringAsFixed(1)} ${marker.durationFrames.toStringAsFixed(1)}'),
            trailing: Text(
                '[${marker.start.toStringAsFixed(2)}-${marker.end.toStringAsFixed(2)}]'),
          ),
      ],
    );
  }

  void _playBetween(String marker1, String marker2) {
    var start = widget.composition.getMarker(marker1).start;
    var end = widget.composition.getMarker(marker2).start;

    _controller.value = start;
    _controller.animateTo(end,
        duration: widget.composition.duration * (end - start).abs());
  }
}
