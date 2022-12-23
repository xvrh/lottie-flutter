import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: _Page()),
    );
  }
}

class _Page extends StatefulWidget {
  @override
  __PageState createState() => __PageState();
}

class __PageState extends State<_Page> {
  var _animationKey = UniqueKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Lottie.network(
          'https://assets10.lottiefiles.com/datafiles/QeC7XD39x4C1CIj/data.json',
          key: _animationKey,
          fit: BoxFit.contain,
          width: 200,
          height: 200,
        ),
        ElevatedButton(
          onPressed: () {
            Lottie.cache.clear();
            Lottie.cache.maximumSize = 10;
          },
          child: const Text('Clear cache'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _animationKey = UniqueKey();
            });
          },
          child: const Text('Recreate animation'),
        ),
      ],
    );
  }
}
