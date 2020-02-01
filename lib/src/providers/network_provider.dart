import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../composition.dart';
import 'lottie_provider.dart';

class NetworkLottie extends LottieProvider {
  static final HttpClient _sharedHttpClient = HttpClient()
    ..autoUncompress = false;

  NetworkLottie(this.url, {this.headers});

  final String url;
  final Map<String, String> headers;

  @override
  Future<LottieComposition> load() async {
    var cacheKey = 'network-$url';
    return sharedLottieCache.putIfAbsent(cacheKey, () async {
      var resolved = Uri.base.resolve(url);
      var request = await _sharedHttpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
            'Http error. Status code: ${response.statusCode} for $resolved');
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.lengthInBytes == 0) {
        throw Exception('NetworkImage is an empty file: $resolved');
      }

      var composition = LottieComposition.fromBytes(bytes);

      //TODO(xha): load images from composition with NetworkImage provider.

      return composition;
    });
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other is NetworkLottie && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => '$runtimeType(url: $url)';
}

Future<Uint8List> consolidateHttpClientResponseBytes(
  HttpClientResponse response, {
  bool autoUncompress = true,
}) {
  assert(autoUncompress != null);
  final completer = Completer<Uint8List>.sync();

  final output = _OutputBuffer();
  ByteConversionSink sink = output;
  var expectedContentLength = response.contentLength;
  if (expectedContentLength == -1) {
    expectedContentLength = null;
  }
  switch (response.compressionState) {
    case HttpClientResponseCompressionState.compressed:
      if (autoUncompress) {
        // We need to un-compress the bytes as they come in.
        sink = gzip.decoder.startChunkedConversion(output);
      }
      break;
    case HttpClientResponseCompressionState.decompressed:
      // response.contentLength will not match our bytes stream, so we declare
      // that we don't know the expected content length.
      expectedContentLength = null;
      break;
    case HttpClientResponseCompressionState.notCompressed:
      // Fall-through.
      break;
  }

  response.listen((List<int> chunk) {
    sink.add(chunk);
  }, onDone: () {
    sink.close();
    completer.complete(output.bytes);
  }, onError: completer.completeError, cancelOnError: true);

  return completer.future;
}

class _OutputBuffer extends ByteConversionSinkBase {
  List<List<int>> _chunks = <List<int>>[];
  int _contentLength = 0;
  Uint8List _bytes;

  @override
  void add(List<int> chunk) {
    assert(_bytes == null);
    _chunks.add(chunk);
    _contentLength += chunk.length;
  }

  @override
  void close() {
    if (_bytes != null) {
      // We've already been closed; this is a no-op
      return;
    }
    _bytes = Uint8List(_contentLength);
    var offset = 0;
    for (var chunk in _chunks) {
      _bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    _chunks = null;
  }

  Uint8List get bytes {
    assert(_bytes != null);
    return _bytes;
  }
}
