class DotLottieAnimation {
  late String id;
  double? speed = 1.0;
  String? themeColor;
  bool? loop = false;

  DotLottieAnimation({
    required this.id,
    this.speed,
    this.themeColor,
    this.loop,
  });

  DotLottieAnimation.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String;

    if (json['speed'] != null) {
      speed = double.parse(json['speed'].toString());
    }

    if (json['themeColor'] != null) {
      themeColor = json['themeColor'] as String;
    }

    if (json['loop'] != null) {
      loop = json['loop'] as bool;
    }
  }
}
