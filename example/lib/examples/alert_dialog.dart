import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) => _showLoader());
  }

  void _showLoader() {
    showDialog<void>(
      context: context,
      builder: (context) => Center(
        child: Lottie.network(
          'https://assets10.lottiefiles.com/datafiles/QeC7XD39x4C1CIj/data.json',
          fit: BoxFit.contain,
          width: 200,
          height: 200,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Center();
  }
}
