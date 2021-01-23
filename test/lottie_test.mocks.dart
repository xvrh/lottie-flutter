import 'dart:async' as _i4;
import 'dart:typed_data' as _i2;
import 'package:flutter/src/services/asset_bundle.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: comment_references

// ignore_for_file: unnecessary_parenthesis

class _FakeByteData extends _i1.Fake implements _i2.ByteData {}

/// A class which mocks [AssetBundle].
///
/// See the documentation for Mockito's code generation for more information.
class MockAssetBundle extends _i1.Mock implements _i3.AssetBundle {
  MockAssetBundle() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i2.ByteData> load(String? key) => (super.noSuchMethod(
          Invocation.method(#load, [key]), Future.value(_FakeByteData()))
      as _i4.Future<_i2.ByteData>);
  @override
  _i4.Future<String> loadString(String? key, {bool? cache = true}) =>
      (super.noSuchMethod(
          Invocation.method(#loadString, [key], {#cache: cache}),
          Future.value('')) as _i4.Future<String>);
  @override
  _i4.Future<T> loadStructuredData<T>(
          String? key, _i4.Future<T> Function(String)? parser) =>
      (super.noSuchMethod(Invocation.method(#loadStructuredData, [key, parser]),
          Future.value(null)) as _i4.Future<T>);
  @override
  void evict(String? key) =>
      super.noSuchMethod(Invocation.method(#evict, [key]));
  @override
  String toString() =>
      (super.noSuchMethod(Invocation.method(#toString, []), '') as String);
}
