import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Lottie.asset('assets/LottieLogo1.json');
  }
}
