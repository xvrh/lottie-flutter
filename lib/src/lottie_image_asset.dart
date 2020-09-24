import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

class LottieImageAsset {
  final int width;
  final int height;
  final String id;
  final String fileName;
  final String dirName;
  ui.Image loadedImage;
  ImageProvider provider;

  LottieImageAsset(
      {this.width, this.height, this.id, this.fileName, this.dirName});

  void dispose() {
    provider?.evict();
  }

  @override
  String toString() =>
      'LottieImageAsset(width: $width, height: $height, id: $id, fileName: $fileName, dirName: $dirName)';
}
