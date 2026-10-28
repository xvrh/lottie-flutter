import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

void main() async {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin {
  HSVColor _color = HSVColor.fromColor(Colors.green);
  double _opacity = 0.5;
  bool _useDelegates = true;

  @override
  Widget build(BuildContext context) {
    var valueDelegates = [
      ValueDelegate.color([
        'Shape Layer 1',
        'Rectangle',
        'Fill 1',
      ], value: _color.toColor()),
      ValueDelegate.opacity([
        'Shape Layer 1',
        'Rectangle',
        'Fill 1',
      ], callback: (_) => (_opacity * 100).round()),
    ];

    return MaterialApp(
      color: Colors.blue,
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Dynamic properties')),
        body: ListView(
          children: <Widget>[
            SizedBox(
              width: 300,
              height: 300,
              child: Lottie.asset(
                'assets/Tests/Shapes.json',
                delegates: LottieDelegates(
                  values: _useDelegates ? valueDelegates : null,
                ),
              ),
            ),
            Checkbox(
              value: _useDelegates,
              onChanged: (newValue) {
                setState(() {
                  _useDelegates = newValue!;
                });
              },
            ),
            Slider(
              value: _opacity,
              onChanged: (newOpacity) {
                setState(() {
                  _opacity = newOpacity;
                });
              },
            ),
            Slider(
              value: _color.hue,
              max: 360,
              activeColor: _color.toColor(),
              onChanged: (hue) {
                setState(() {
                  _color = _color.withHue(hue);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
