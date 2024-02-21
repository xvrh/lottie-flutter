import 'dart:io';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_static/shelf_static.dart';

void main() async {
  var server = await serve(
      createStaticHandler('build/web'), InternetAddress.loopbackIPv4, 0);
  print('Listen on http://${server.address.host}:${server.port}/index.html');
}
