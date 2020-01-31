import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../composition.dart';
import 'lottie_provider.dart';

class FileLottie extends LottieProvider {
  FileLottie(this.file);

  final File file;

  @override
  Future<LottieComposition> load() async {
    throw UnimplementedError();
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other is FileLottie && other.file == file;
  }

  @override
  int get hashCode => file.hashCode;

  @override
  String toString() => '$runtimeType(file: ${file.path})';
}
