import 'moshi/json_reader.dart';

typedef ValueParser<V> = V Function(JsonReader reader, {required double scale});
