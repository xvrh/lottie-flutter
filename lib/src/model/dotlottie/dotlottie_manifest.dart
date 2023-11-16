import 'dotlottie_animation.dart';

class DotLottieManifest {
  String? generator;
  String? version;
  int? revision;
  String? author;
  List<DotLottieAnimation>? animations;
  Map<String, dynamic>? custom;
  Map<String, dynamic>? states;

  DotLottieManifest({
    this.generator,
    this.version,
    this.revision,
    this.author,
    this.animations,
    this.custom,
    this.states,
  });

  DotLottieManifest.fromJson(Map<String, dynamic> json) {
    generator = json['generator'] as String;
    version = json['version'] as String;
    revision = (json['revision'] ?? 0) as int;
    author = json['author'] as String;

    if (json['animations'] == null) {
      animations = [];
    } else {
      animations = (json['animations'] as List).map((v) => DotLottieAnimation.fromJson(v as Map<String, dynamic>)).toList();
    }

    if (json['custom'] != null) {
      custom = json['custom'] as Map<String, dynamic>;
    }

    if (json['states'] != null) {
      states = json['states'] as Map<String, dynamic>;
    }
  }
}
