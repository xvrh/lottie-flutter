import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../utils.dart';
import 'dotlottie_animation.dart';
import 'dotlottie_manifest.dart';

class DotLottie {
  DotLottieManifest? manifest;
  Map<String, Uint8List> animations;
  Map<String, Uint8List> images;
  var currentIndex = 0;

  Uint8List get currentAnimation => animations.values.toList()[currentIndex];
  Uint8List get currentImage => images.values.toList()[currentIndex];
  DotLottieAnimation? get currentAnimationManifest => manifest?.animations?.toList()[currentIndex];

  DotLottie(this.manifest, this.animations, this.images);

  static Future<DotLottie> fromBytes(Uint8List bytes, {String? name}) async {
    if (!checkCompression(bytes)) {
      throw Exception('It is not compressed');
    }

    DotLottieManifest? manifest;
    var archive = ZipDecoder().decodeBytes(bytes);
    var animations = <String, Uint8List>{};
    var images = <String, Uint8List>{};

    for (final file in archive) {
      if (file.name.toLowerCase() == 'manifest.json') {
        final content = file.content as Uint8List;
        final jsonString = const Utf8Decoder().convert(content.toList());
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        
        manifest = DotLottieManifest.fromJson(jsonData);
      } else if (checkAnimation(file)) {
        animations[file.name.lastSegmentName().withoutExt()] = file.content as Uint8List;
      } else if (checkImage(file)) {
        images[file.name.lastSegmentName()] = file.content as Uint8List;
      }
    }
    
    return DotLottie(manifest, animations, images);
  }

  void setAnimation(String animationId) {
    var animations =  manifest?.animations ?? [];
    var index = animations.indexWhere((element) => element.id == animationId);

    currentIndex = index;
  }

  static bool checkCompression(Uint8List bytes) {
    return bytes[0] == 0x50 && bytes[1] == 0x4B;
  }

  static bool checkAnimation(ArchiveFile target) {
    var fileName = target.name;
    return fileName.startsWith('animations/') || fileName.contains('.json');
  }

  static bool checkImage(ArchiveFile target) {
    var fileName = target.name;
    return fileName.startsWith('images') || fileName.contains('.png') || fileName.contains('.webp');
  }
}
