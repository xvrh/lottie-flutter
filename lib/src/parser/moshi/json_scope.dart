/// Lexical scoping elements within a JSON reader or writer. */
class JsonScope {
  JsonScope._();

  /// An array with no elements requires no separators or newlines before it is closed. */
  static const int emptyArray = 1;

  /// A array with at least one value requires a comma and newline before the next element. */
  static const int nonEmptyArray = 2;

  /// An object with no name/value pairs requires no separators or newlines before it is closed. */
  static const int emptyObject = 3;

  /// An object whose most recent element is a key. The next element must be a value. */
  static const int danglingName = 4;

  /// An object with at least one name/value pair requires a separator before the next element. */
  static const int nonEmptyObject = 5;

  /// No object or array has been started. */
  static const int emptyDocument = 6;

  /// A document with at an array or object. */
  static const int nonEmptyDocument = 7;

  /// A document that's been closed and cannot be accessed. */
  static const int closed = 8;

  /// Renders the path in a JSON document to a string. The {@code pathNames} and {@code pathIndices}
  /// parameters corresponds directly to stack: At indices where the stack contains an object
  /// (EMPTY_OBJECT, DANGLING_NAME or NONEMPTY_OBJECT), pathNames contains the name at this scope.
  /// Where it contains an array (EMPTY_ARRAY, NONEMPTY_ARRAY) pathIndices contains the current index
  /// in that array. Otherwise the value is undefined, and we take advantage of that by incrementing
  /// pathIndices when doing so isn't useful.
  static String getPath(int stackSize, List<int> stack, List<String?> pathNames,
      List<int> pathIndices) {
    var result = StringBuffer()..write(r'$');
    for (var i = 0; i < stackSize; i++) {
      switch (stack[i]) {
        case emptyArray:
        case nonEmptyArray:
          result
            ..write('[')
            ..write(pathIndices[i])
            ..write(']');

        case emptyObject:
        case danglingName:
        case nonEmptyObject:
          result.write('.');
          if (pathNames[i] != null) {
            result.write(pathNames[i]);
          }

        case nonEmptyDocument:
        case emptyDocument:
        case closed:
          break;
      }
    }
    return result.toString();
  }
}
