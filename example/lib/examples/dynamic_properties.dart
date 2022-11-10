import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:lottie/lottie.dart';

void main() async {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin {
  Color _color = Colors.green;
  double _opacity = 0.5;
  bool _useDelegates = true;

  @override
  Widget build(BuildContext context) {
    var valueDelegates = [
      ValueDelegate.color(['Shape Layer 1', 'Rectangle', 'Fill 1'],
          value: _color),
      ValueDelegate.opacity(['Shape Layer 1', 'Rectangle', 'Fill 1'],
          callback: (_) => (_opacity * 100).round()),
    ];

    return MaterialApp(
      color: Colors.blue,
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Dynamic properties'),
        ),
        body: ListView(
          children: <Widget>[
            SizedBox(
              width: 300,
              height: 300,
              child: Lottie.asset(
                'assets/Tests/Shapes.json',
                delegates: LottieDelegates(
                    values: _useDelegates ? valueDelegates : null),
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
            Center(
              child: SizedBox(
                width: 500,
                child: ColorPicker(
                  pickerColor: _color,
                  onColorChanged: (newColor) {
                    setState(() {
                      _color = newColor;
                    });
                  },
                  labelTypes: const [],
                  enableAlpha: false,
                  pickerAreaHeightPercent: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
