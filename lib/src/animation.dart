import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

class LottieAnimation {
  //TODO(xha): to delete
  LottieAnimation.network(String url);

  LottieAnimation.asset(String path);

  LottieAnimation.memory(List<int> data);

  LottieAnimation.json(Map<String, dynamic> json);
}

class LottiePlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
  }
}
