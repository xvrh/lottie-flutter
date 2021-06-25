import 'dart:html';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import '../lottie_image_asset.dart';

// ignore_for_file: avoid_web_libraries_in_flutter

Future<Uint8List> loadHttp(Uri uri, {Map<String, String>? headers}) async {
  var request = await HttpRequest.request(uri.toString(),
      requestHeaders: headers, responseType: 'blob');

  return _loadBlob(request.response as Blob);
}

Future<Uint8List> loadFile(Object file) {
  return _loadBlob(file as File);
}

Future<Uint8List> _loadBlob(Blob file) async {
  var reader = FileReader();
  reader.readAsArrayBuffer(file);

  await reader.onLoadEnd.first;
  if (reader.readyState != FileReader.DONE) {
    throw Exception('Error while reading blob');
  }

  return reader.result! as Uint8List;
}

String filePath(Object file) {
  return (file as File).relativePath ?? '';
}

ImageProvider loadImageForFile(Object file, LottieImageAsset lottieImage) {
  throw UnimplementedError();
}
