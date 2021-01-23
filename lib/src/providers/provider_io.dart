import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import '../lottie_image_asset.dart';

final HttpClient _sharedHttpClient = HttpClient()..autoUncompress = false;

Future<Uint8List> loadHttp(Uri uri, {Map<String, String>? headers}) async {
  var request = await _sharedHttpClient.getUrl(uri);
  headers?.forEach((String name, String value) {
    request.headers.add(name, value);
  });
  final response = await request.close();
  if (response.statusCode != HttpStatus.ok) {
    throw Exception('Http error. Status code: ${response.statusCode} for $uri');
  }

  final bytes = await consolidateHttpClientResponseBytes(response);
  if (bytes.lengthInBytes == 0) {
    throw Exception('NetworkImage is an empty file: $uri');
  }

  return bytes;
}

Future<Uint8List> loadFile(Object file) {
  return (file as File).readAsBytes();
}

String filePath(Object file) {
  return (file as File).path;
}

ImageProvider loadImageForFile(Object file, LottieImageAsset lottieImage) {
  var fileIo = file as File;

  var imagePath = p.url
      .join(p.dirname(fileIo.path), lottieImage.dirName, lottieImage.fileName);
  return FileImage(File(imagePath));
}
