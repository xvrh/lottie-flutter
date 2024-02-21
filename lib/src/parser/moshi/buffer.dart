import 'dart:convert';
import 'dart:math';

class Buffer {
  Buffer(this.buffer);

  final List<int> buffer;
  int _start = 0, _size = 0;
  int get size => _size;

  static void _checkOffsetAndCount(int size, int offset, int byteCount) {
    if ((offset | byteCount) < 0 ||
        offset > size ||
        size - offset < byteCount) {
      throw Exception('size=$size offset=$offset byteCount=$byteCount');
    }
  }

  /// Removes all bytes from this, decodes them as UTF-8, and returns the string. Returns the empty
  /// string if this source is empty. <pre>{@code
  ///
  ///   Buffer buffer = new Buffer()
  ///       .writeUtf8("Uh uh uh!")
  ///       .writeByte(' ')
  ///       .writeUtf8("You didn't say the magic word!");
  ///
  ///   assertEquals("Uh uh uh! You didn't say the magic word!", buffer.readUtf8());
  ///   assertEquals(0, buffer.size());
  ///
  ///   assertEquals("", buffer.readUtf8());
  ///   assertEquals(0, buffer.size());
  /// }</pre>
  String readUtf8(int byteCount) {
    if (_size < byteCount) throw Exception('size < $byteCount: $_size');

    var string = utf8.decoder.convert(buffer, _start, _start + byteCount);
    _start += byteCount;
    _size -= byteCount;
    return string;
  }

  /// Removes a byte from this source and returns it.
  int readByte() {
    if (_size == 0) throw Exception('size == 0');

    var byte = buffer[_start++];
    --_size;
    return byte;
  }

  /// Returns true when the buffer contains at least {@code byteCount} bytes, expanding it as
  /// necessary. Returns false if the source is exhausted before the requested bytes can be read.
  bool request(int byteCount) {
    if (_start + byteCount > buffer.length) {
      _size = buffer.length - _start;
      return false;
    }
    _size = max(byteCount, _size);
    return true;
  }

  /// Returns the byte at {@code pos}. */
  int getByte(int pos) {
    _checkOffsetAndCount(_size, pos, 1);
    return buffer[_start + pos];
  }

  /// Reads and discards {@code byteCount} bytes from this source. Throws an
  /// [Exception] if the source is exhausted before the
  /// requested bytes can be skipped.
  void skip(int byteCount) {
    _start += byteCount;
    if (_start >= buffer.length) {
      _start = buffer.length - 1;
      throw Exception('source is exhausted');
    }

    _size -= byteCount;
    _size = max(0, _size);
  }

  /// Finds the first string in {@code options} that is a prefix of this buffer, consumes it from
  /// this buffer, and returns its index. If no byte string in {@code options} is a prefix of this
  /// buffer this returns -1 and no bytes are consumed.
  ///
  /// <p>This can be used as an alternative to {@link #readByteString} or even {@link #readUtf8} if
  /// the set of expected values is known in advance. <pre>{@code
  ///
  ///   Options FIELDS = Options.of(
  ///       ByteString.encodeUtf8("depth="),
  ///       ByteString.encodeUtf8("height="),
  ///       ByteString.encodeUtf8("width="));
  ///
  ///   Buffer buffer = new Buffer()
  ///       .writeUtf8("width=640\n")
  ///       .writeUtf8("height=480\n");
  ///
  ///   assertEquals(2, buffer.select(FIELDS));
  ///   assertEquals(640, buffer.readDecimalLong());
  ///   assertEquals('\n', buffer.readByte());
  ///   assertEquals(1, buffer.select(FIELDS));
  ///   assertEquals(480, buffer.readDecimalLong());
  ///   assertEquals('\n', buffer.readByte());
  /// }</pre>
  int select(List<List<int>> options) {
    var index = _selectPrefix(options);
    if (index == -1) return -1;

    var size = options[index].length;
    skip(size);
    return index;
  }

  int _selectPrefix(List<List<int>> options) {
    for (var i = 0; i < options.length; i++) {
      var option = options[i];
      if (_isPrefix(option, buffer, _start)) {
        return i;
      }
    }
    return -1;
  }

  static bool _isPrefix(List<int> search, List<int> buffer, int start) {
    for (var i = 0; i < search.length; i++) {
      if (search[i] != buffer[start + i]) {
        return false;
      }
    }
    return true;
  }

  /// Returns the first index in this buffer that is at or after {@code fromIndex} and that contains
  /// any of the bytes in {@code targetBytes}. This expands the buffer as necessary until a target
  /// byte is found. This reads an unbounded number of bytes into the buffer. Returns -1 if the
  /// stream is exhausted before the requested byte is found. <pre>{@code
  ///
  ///   ByteString ANY_VOWEL = ByteString.encodeUtf8("AEOIUaeoiu");
  ///
  ///   Buffer buffer = new Buffer();
  ///   buffer.writeUtf8("Dr. Alan Grant");
  ///
  ///   assertEquals(4,  buffer.indexOfElement(ANY_VOWEL));    // 'A' in 'Alan'.
  ///   assertEquals(11, buffer.indexOfElement(ANY_VOWEL, 9)); // 'a' in 'Grant'.
  /// }</pre>
  int indexOfElement(List<int> targetBytes, int fromIndex) {
    var i = fromIndex;
    while (_start + i < buffer.length) {
      _size = max(i + 1, _size);

      var bufferByte = buffer[_start + i];
      for (var targetByte in targetBytes) {
        if (targetByte == bufferByte) {
          return i;
        }
      }
      ++i;
    }
    return -1;
  }

  /// Returns the index of the first {@code b} in the buffer at or after {@code fromIndex}. This
  /// expands the buffer as necessary until {@code b} is found. This reads an unbounded number of
  /// bytes into the buffer. Returns -1 if the stream is exhausted before the requested byte is
  /// found. <pre>{@code
  ///
  ///   Buffer buffer = new Buffer();
  ///   buffer.writeUtf8("Don't move! He can't see us if we don't move.");
  ///
  ///   byte m = 'm';
  ///   assertEquals(6,  buffer.indexOf(m));
  ///   assertEquals(40, buffer.indexOf(m, 12));
  /// }</pre>
  int indexOf(int b, int fromIndex) {
    var i = fromIndex;
    while (_start + i < buffer.length) {
      _size = max(i + 1, _size);

      var bufferByte = buffer[_start + i];
      if (b == bufferByte) {
        return i;
      }

      ++i;
    }
    return -1;
  }

  /// Returns the index of the first match for {@code bytes} in the buffer at or after {@code
  /// fromIndex}. This expands the buffer as necessary until {@code bytes} is found. This reads an
  /// unbounded number of bytes into the buffer. Returns -1 if the stream is exhausted before the
  /// requested bytes are found. <pre>{@code
  ///
  ///   ByteString MOVE = ByteString.encodeUtf8("move");
  ///
  ///   Buffer buffer = new Buffer();
  ///   buffer.writeUtf8("Don't move! He can't see us if we don't move.");
  ///
  ///   assertEquals(6,  buffer.indexOf(MOVE));
  ///   assertEquals(40, buffer.indexOf(MOVE, 12));
  /// }</pre>
  int indexOfBytes(List<int> bytes, int fromIndex) {
    var i = fromIndex;
    while (_start + i < buffer.length) {
      _size = max(i + 1, _size);

      if (_isPrefix(bytes, buffer, _start + i)) {
        return i;
      }
      ++i;
    }
    return -1;
  }

  void clear() {}
}
