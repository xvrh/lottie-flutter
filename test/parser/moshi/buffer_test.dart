import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/src/parser/moshi/buffer.dart';

void main() {
  test('Read', () {
    var buffer = Buffer(Uint8List.fromList(List.generate(10, (i) => i)));

    buffer.request(4);
    expect(buffer.readByte(), 0);
    expect(buffer.readByte(), 1);
    expect(buffer.getByte(0), 2);
    expect(buffer.getByte(1), 3);
  });
  test('Skip', () {
    var buffer = Buffer(Uint8List.fromList(List.generate(10, (i) => i)));

    buffer.skip(2);
    buffer.request(1);
    expect(buffer.readByte(), 2);
    expect(buffer.size, 0);
    buffer.skip(2);
    expect(buffer.size, 0);
  });
}
