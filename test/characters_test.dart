import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/src/utils/characters.dart';

void main() {
  test('TrimTrailing characters', () {
    expect('ab c d  '.characters.trimTrailing(' '.characters),
        'ab c d'.characters);
    expect(' '.characters.trimTrailing(' '.characters), ''.characters);
    expect(' a '.characters.trimTrailing(' '.characters), ' a'.characters);
    expect(' aa'.characters.trimTrailing('a'.characters), ' '.characters);
    expect('aabcbc'.characters.trimTrailing('bc'.characters), 'aa'.characters);
    expect('bcbc'.characters.trimTrailing('bc'.characters), ''.characters);
    expect(''.characters.trimTrailing(' '.characters), ''.characters);
    expect(''.characters.trimTrailing('bc'.characters), ''.characters);
    expect(' '.characters.trimTrailing('bc'.characters), ' '.characters);
    expect(' bc'.characters.trimTrailing('bc'.characters), ' '.characters);
  });

  test('TrimLeading characters', () {
    expect(' ab '.characters.trimLeading(' '.characters), 'ab '.characters);
    expect(' '.characters.trimLeading(' '.characters), ''.characters);
    expect('   '.characters.trimLeading(' '.characters), ''.characters);
    expect('   a'.characters.trimLeading(' '.characters), 'a'.characters);
    expect('abc'.characters.trimLeading('ab'.characters), 'c'.characters);
    expect('ababc'.characters.trimLeading('ab'.characters), 'c'.characters);
    expect('abab'.characters.trimLeading('ab'.characters), ''.characters);
    expect('ababcd'.characters.trimLeading('ab'.characters), 'cd'.characters);
    expect(''.characters.trimLeading(''.characters), ''.characters);
  });

  test('Trim characters', () {
    expect(' ab '.characters.trim(' '.characters), 'ab'.characters);
  });
}
