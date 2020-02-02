import 'dart:ui' as ui;

void setLoadedImage(LottieImageAsset asset, ui.Image image) {
  asset._loadedImage = image;
}

ui.Image getLoadedImage(LottieImageAsset asset) => asset._loadedImage;

class LottieImageAsset {
  final int width;
  final int height;
  final String id;
  final String fileName;
  final String dirName;
  ui.Image _loadedImage;

  LottieImageAsset(
      {this.width, this.height, this.id, this.fileName, this.dirName});

  @override
  String toString() =>
      'LottieImageAsset(width: $width, height: $height, id: $id, fileName: $fileName, dirName: $dirName)';
}
