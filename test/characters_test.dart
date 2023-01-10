

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/src/utils/characters.dart';

void main() {
  test('Trim characters', () {
    expect('ab c d  '.characters.trimTrailing(' '), 'ab c d'.characters);
    expect(' '.characters.trimTrailing(' '), ''.characters);
    expect(' a '.characters.trimTrailing(' '), ' a'.characters);
    expect(' aa'.characters.trimTrailing('a'), ' '.characters);
    expect('aabcbc'.characters.trimTrailing('bc'), 'aa'.characters);
    expect('bcbc'.characters.trimTrailing('bc'), ''.characters);
    expect(''.characters.trimTrailing(' '), ''.characters);
    expect(''.characters.trimTrailing('bc'), ''.characters);
    expect(' '.characters.trimTrailing('bc'), ' '.characters);
  });
}