import 'dart:html';
import 'dart:typed_data';

Future<Uint8List> load(Uri uri, {Map<String, String> headers}) async {
  var request = await HttpRequest.request(uri.toString(),
      requestHeaders: headers, responseType: 'blob');

  var reader = FileReader();
  reader.readAsArrayBuffer(request.response as Blob);
  await reader.onLoadEnd.first;
  if (reader.readyState != FileReader.DONE) {
    throw Exception('Error while reading $uri');
  }

  return reader.result as Uint8List;
}
