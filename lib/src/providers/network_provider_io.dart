import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

final HttpClient _sharedHttpClient = HttpClient()..autoUncompress = false;

Future<Uint8List> load(Uri uri, {Map<String, String> headers}) async {
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
