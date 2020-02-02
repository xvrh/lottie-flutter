import 'dart:ui' as ui;

class LottieImageAsset {
  final int width;
  final int height;
  final String id;
  final String fileName;
  final String dirName;
  ui.Image loadedImage;

  LottieImageAsset(
      {this.width, this.height, this.id, this.fileName, this.dirName});

  @override
  String toString() =>
      'LottieImageAsset(width: $width, height: $height, id: $id, fileName: $fileName, dirName: $dirName)';
}
