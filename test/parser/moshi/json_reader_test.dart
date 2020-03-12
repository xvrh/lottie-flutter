import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/src/parser/moshi/json_reader.dart';

void main() {
  test('Read json', () {
    var s = ';\nvar';
    print(s.codeUnits);

    var reader = JsonReader.fromBytes(utf8.encoder.convert(_simpleJson));
    var messages = readMessagesArray(reader);
    expect(messages, hasLength(2));
    expect(messages.first.user.name, 'var bm_rt;\nvar ampb');
  });
}

class Message {
  final int id;
  final String text;
  final List<double> geo;
  final User user;

  Message(this.id, this.text, this.user, this.geo);
}

class User {
  final String name;
  final int followerCount;

  User(this.name, this.followerCount);
}

List<Message> readMessagesArray(JsonReader reader) {
  var messages = <Message>[];
  reader.beginArray();
  while (reader.hasNext()) {
    messages.add(readMessage(reader));
  }
  reader.endArray();
  return messages;
}

Message readMessage(JsonReader reader) {
  var id = -1;
  String text;
  User user;
  List<double> geo;
  reader.beginObject();
  while (reader.hasNext()) {
    var name = reader.nextName();
    if (name == 'id') {
      id = reader.nextInt();
    } else if (name == 'text') {
      text = reader.nextString();
    } else if (name == 'geo' && reader.peek() != Token.nullToken) {
      geo = readDoublesArray(reader);
    } else if (name == 'user') {
      user = readUser(reader);
    } else {
      reader.skipValue();
    }
  }
  reader.endObject();
  return Message(id, text, user, geo);
}

List<double> readDoublesArray(JsonReader reader) {
  var doubles = <double>[];
  reader.beginArray();
  while (reader.hasNext()) {
    doubles.add(reader.nextDouble());
  }
  reader.endArray();
  return doubles;
}

User readUser(JsonReader reader) {
  String username;
  var followersCount = -1;
  reader.beginObject();
  while (reader.hasNext()) {
    var name = reader.nextName();
    if (name == 'name') {
      username = reader.nextString();
    } else if (name == 'followers_count') {
      followersCount = reader.nextInt();
    } else {
      reader.skipValue();
    }
  }
  reader.endObject();
  return User(username, followersCount);
}

final _simpleJson = '''
[
  {
    "id": 912345678901,
    "text": "How do I read a JSON stream in Java?",
    "geo": null,
    "user": {
      "name": "var bm_rt;\nvar ampb",
      "followers_count": 41
     }
  },
  {
    "id": 912345678902,
    "text": "@json_newb just use JsonReader!",
    "geo": [50.454722, -104.606667],
    "user": {
      "name": "jesse",
      "followers_count": 2
    }
  }
]
''';
