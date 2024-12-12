import 'dart:convert';
import 'buffer.dart';
import 'json_scope.dart';
import 'json_utf8_reader.dart';

// ignore_for_file: unintended_html_in_doc_comment

/// Reads a JSON (<a href="http://www.ietf.org/rfc/rfc7159.txt">RFC 7159</a>)
/// encoded value as a stream of tokens. This stream includes both literal
/// values (strings, numbers, booleans, and nulls) as well as the begin and
/// end delimiters of objects and arrays. The tokens are traversed in
/// depth-first order, the same order that they appear in the JSON document.
/// Within JSON objects, name/value pairs are represented by a single token.
///
/// <h3>Parsing JSON</h3>
/// To create a recursive descent parser for your own JSON streams, first create
/// an entry point method that creates a {@code JsonReader}.
///
/// <p>Next, create handler methods for each structure in your JSON text. You'll
/// need a method for each object type and for each array type.
/// <ul>
///   <li>Within <strong>array handling</strong> methods, first call {@link
///       #beginArray} to consume the array's opening bracket. Then create a
///       while loop that accumulates values, terminating when {@link #hasNext}
///       is false. Finally, read the array's closing bracket by calling {@link
///       #endArray}.
///   <li>Within <strong>object handling</strong> methods, first call {@link
///       #beginObject} to consume the object's opening brace. Then create a
///       while loop that assigns values to local variables based on their name.
///       This loop should terminate when {@link #hasNext} is false. Finally,
///       read the object's closing brace by calling {@link #endObject}.
/// </ul>
/// <p>When a nested object or array is encountered, delegate to the
/// corresponding handler method.
///
/// <p>When an unknown name is encountered, strict parsers should fail with an
/// exception. Lenient parsers should call {@link #skipValue()} to recursively
/// skip the value's nested tokens, which may otherwise conflict.
///
/// <p>If a value may be null, you should first check using {@link #peek()}.
/// Null literals can be consumed using either {@link #nextNull()} or {@link
/// #skipValue()}.
///
/// <h3>Example</h3>
/// Suppose we'd like to parse a stream of messages such as the following: <pre> {@code
/// [
///   {
///     "id": 912345678901,
///     "text": "How do I read a JSON stream in Java?",
///     "geo": null,
///     "user": {
///       "name": "json_newb",
///       "followers_count": 41
///      }
///   },
///   {
///     "id": 912345678902,
///     "text": "@json_newb just use JsonReader!",
///     "geo": [50.454722, -104.606667],
///     "user": {
///       "name": "jesse",
///       "followers_count": 2
///     }
///   }
/// ]}</pre>
/// This code implements the parser for the above structure: <pre>   {@code
///
///   public List<Message> readJsonStream(BufferedSource source) throws IOException {
///     JsonReader reader = JsonReader.of(source);
///     try {
///       return readMessagesArray(reader);
///     } finally {
///       reader.close();
///     }
///   }
///
///   public List<Message> readMessagesArray(JsonReader reader) throws IOException {
///     List<Message> messages = new ArrayList<Message>();
///
///     reader.beginArray();
///     while (reader.hasNext()) {
///       messages.add(readMessage(reader));
///     }
///     reader.endArray();
///     return messages;
///   }
///
///   public Message readMessage(JsonReader reader) throws IOException {
///     long id = -1;
///     String text = null;
///     User user = null;
///     List<Double> geo = null;
///
///     reader.beginObject();
///     while (reader.hasNext()) {
///       String name = reader.nextName();
///       if (name.equals("id")) {
///         id = reader.nextLong();
///       } else if (name.equals("text")) {
///         text = reader.nextString();
///       } else if (name.equals("geo") && reader.peek() != Token.NULL) {
///         geo = readDoublesArray(reader);
///       } else if (name.equals("user")) {
///         user = readUser(reader);
///       } else {
///         reader.skipValue();
///       }
///     }
///     reader.endObject();
///     return new Message(id, text, user, geo);
///   }
///
///   public List<Double> readDoublesArray(JsonReader reader) throws IOException {
///     List<Double> doubles = new ArrayList<Double>();
///
///     reader.beginArray();
///     while (reader.hasNext()) {
///       doubles.add(reader.nextDouble());
///     }
///     reader.endArray();
///     return doubles;
///   }
///
///   public User readUser(JsonReader reader) throws IOException {
///     String username = null;
///     int followersCount = -1;
///
///     reader.beginObject();
///     while (reader.hasNext()) {
///       String name = reader.nextName();
///       if (name.equals("name")) {
///         username = reader.nextString();
///       } else if (name.equals("followers_count")) {
///         followersCount = reader.nextInt();
///       } else {
///         reader.skipValue();
///       }
///     }
///     reader.endObject();
///     return new User(username, followersCount);
///   }}</pre>
///
/// <h3>Number Handling</h3>
/// This reader permits numeric values to be read as strings and string values to
/// be read as numbers. For example, both elements of the JSON array {@code
/// [1, "1"]} may be read using either {@link #nextInt} or {@link #nextString}.
/// This behavior is intended to prevent lossy numeric conversions: double is
/// JavaScript's only numeric type and very large values like {@code
/// 9007199254740993} cannot be represented exactly on that platform. To minimize
/// precision loss, extremely large values should be written and read as strings
/// in JSON.
///
/// <p>Each {@code JsonReader} may be used to read a single JSON stream. Instances
/// of this class are not thread safe.
abstract class JsonReader {
  // The nesting stack. Using a manual array rather than an ArrayList saves 20%. This stack will
  // grow itself up to 256 levels of nesting including the top-level document. Deeper nesting is
  // prone to trigger StackOverflowErrors.
  int stackSize = 0;
  List<int> scopes = List<int>.filled(32, 0);
  List<String?> pathNames = List<String?>.filled(32, null);
  List<int> pathIndices = List<int>.filled(32, 0);

  /// True to accept non-spec compliant JSON.
  bool lenient = false;

  /// True to throw a {@link JsonDataException} on any attempt to call {@link #skipValue()}.
  bool failOnUnknown = false;

  /// Returns a new instance that reads UTF-8 encoded JSON from {@code source}.
  static JsonReader fromBytes(List<int> source) {
    return JsonUtf8Reader(Buffer(source));
  }

  static List<T> _copyOf<T>(List<T> source, int newSize, T fill) {
    var newList = List<T>.filled(newSize, fill);
    List.copyRange(newList, 0, source);
    return newList;
  }

  void pushScope(int newTop) {
    if (stackSize == scopes.length) {
      if (stackSize == 256) {
        throw JsonDataException('Nesting too deep at ${getPath()}');
      }
      scopes = _copyOf(scopes, scopes.length * 2, 0);
      pathNames = _copyOf(pathNames, pathNames.length * 2, null);
      pathIndices = _copyOf(pathIndices, pathIndices.length * 2, 0);
    }
    scopes[stackSize++] = newTop;
  }

  /// Throws a new IO exception with the given message and a context snippet
  /// with this reader's content.
  JsonEncodingException syntaxError(String message) {
    throw JsonEncodingException('$message at path ${getPath()}');
  }

  /// Consumes the next token from the JSON stream and asserts that it is the beginning of a new
  /// array.
  void beginArray();

  /// Consumes the next token from the JSON stream and asserts that it is the
  /// end of the current array.
  void endArray();

  /// Consumes the next token from the JSON stream and asserts that it is the beginning of a new
  /// object.
  void beginObject();

  /// Consumes the next token from the JSON stream and asserts that it is the end of the current
  /// object.
  void endObject();

  /// Returns true if the current array or object has another element.
  bool hasNext();

  /// Returns the type of the next token without consuming it.
  Token peek();

  /// Returns the next token, a {@linkplain Token#NAME property name}, and consumes it.
  ///
  /// @throws JsonDataException if the next token in the stream is not a property name.
  String nextName();

  /// If the next token is a {@linkplain Token#NAME property name} that's in {@code options}, this
  /// consumes it and returns its index. Otherwise this returns -1 and no name is consumed.
  int selectName(JsonReaderOptions options);

  /// Skips the next token, consuming it. This method is intended for use when the JSON token stream
  /// contains unrecognized or unhandled names.
  ///
  /// <p>This throws a {@link JsonDataException} if this parser has been configured to {@linkplain
  /// #failOnUnknown fail on unknown} names.
  void skipName();

  /// Returns the {@linkplain Token#STRING string} value of the next token, consuming it. If the next
  /// token is a number, this method will return its string form.
  ///
  /// @throws JsonDataException if the next token is not a string or if this reader is closed.
  String nextString();

  /// Returns the {@linkplain Token#BOOLEAN boolean} value of the next token, consuming it.
  ///
  /// @throws JsonDataException if the next token is not a boolean or if this reader is closed.
  bool nextBoolean();

  /// Returns the {@linkplain Token#NUMBER double} value of the next token, consuming it. If the next
  /// token is a string, this method will attempt to parse it as a double using {@link
  /// Double#parseDouble(String)}.
  ///
  /// @throws JsonDataException if the next token is not a literal value, or if the next literal
  ///     value cannot be parsed as a double, or is non-finite.
  double nextDouble();

  /// Returns the {@linkplain Token#NUMBER int} value of the next token, consuming it. If the next
  /// token is a string, this method will attempt to parse it as an int. If the next token's numeric
  /// value cannot be exactly represented by a Java {@code int}, this method throws.
  ///
  /// @throws JsonDataException if the next token is not a literal value, if the next literal value
  ///     cannot be parsed as a number, or exactly represented as an int.
  int nextInt();

  /// Skips the next value recursively. If it is an object or array, all nested elements are skipped.
  /// This method is intended for use when the JSON token stream contains unrecognized or unhandled
  /// values.
  ///
  /// <p>This throws a {@link JsonDataException} if this parser has been configured to {@linkplain
  /// #failOnUnknown fail on unknown} values.
  void skipValue();

  /// Returns a <a href="http://goessner.net/articles/JsonPath/">JsonPath</a> to
  /// the current location in the JSON value.
  String getPath() {
    return JsonScope.getPath(stackSize, scopes, pathNames, pathIndices);
  }

  void close();
}

/// A set of strings to be chosen with {@link #selectName} or {@link #selectString}. This prepares
/// the encoded values of the strings so they can be read directly from the input source.
class JsonReaderOptions {
  final List<String> strings;
  final List<List<int>> doubleQuoteSuffix;

  JsonReaderOptions(this.strings, this.doubleQuoteSuffix);

  static JsonReaderOptions of(List<String> strings) {
    return JsonReaderOptions(
        strings, strings.map((s) => utf8.encode('$s"')).toList());
  }
}

/// A structure, name, or value type in a JSON-encoded string.
enum Token {
  /// The opening of a JSON array.
  /// and read using {@link JsonReader#beginArray}.
  beginArray,

  /// The closing of a JSON array.
  /// and read using {@link JsonReader#endArray}.
  endArray,

  /// The opening of a JSON object.
  /// and read using {@link JsonReader#beginObject}.
  beginObject,

  /// The closing of a JSON object.
  /// and read using {@link JsonReader#endObject}.
  endObject,

  /// A JSON property name. Within objects, tokens alternate between names and
  /// their values.
  name,

  /// A JSON string.
  string,

  /// A JSON number represented in this API by a Java {@code double}, {@code
  /// long}, or {@code int}.
  number,

  /// A JSON {@code true} or {@code false}.
  boolean,

  /// A JSON {@code null}.
  nullToken,

  /// The end of the JSON stream. This sentinel value is returned by {@link
  /// JsonReader#peek()} to signal that the JSON-encoded value has no more
  /// tokens.
  endDocument
}

class JsonDataException implements Exception {
  final String message;

  JsonDataException(this.message);

  @override
  String toString() => message;
}

class JsonEncodingException implements Exception {
  final String message;

  JsonEncodingException(this.message);

  @override
  String toString() => message;
}
