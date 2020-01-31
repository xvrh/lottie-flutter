import 'dart:math';
import 'dart:ui';

/// Use this instead of {@link android.animation.ArgbEvaluator} because it interpolates through the gamma color
/// space which looks better to us humans.
/// <p>
/// Written by Romain Guy and Francois Blavoet.
/// https://androidstudygroup.slack.com/archives/animation/p1476461064000335
class GammaEvaluator {
  // Opto-electronic conversion function for the sRGB color space
  // Takes a gamma-encoded sRGB value and converts it to a linear sRGB value
  static double _oecfSRgb(double linear) {
    // IEC 61966-2-1:1999
    return linear <= 0.0031308
        ? linear * 12.92
        : ((pow(linear, 1.0 / 2.4) * 1.055) - 0.055).toDouble();
  }

  // Electro-optical conversion function for the sRGB color space
  // Takes a linear sRGB value and converts it to a gamma-encoded sRGB value
  static double _eocfSRgb(double srgb) {
    // IEC 61966-2-1:1999
    return srgb <= 0.04045
        ? srgb / 12.92
        : pow((srgb + 0.055) / 1.055, 2.4).toDouble();
  }

  static Color evaluate(double fraction, Color startColor, Color endColor) {
    if (startColor == endColor) {
      return startColor;
    }
    var startA = startColor.alpha / 255.0;
    var startR = startColor.red / 255.0;
    var startG = startColor.green / 255.0;
    var startB = startColor.blue / 255.0;

    var endA = endColor.alpha / 255.0;
    var endR = endColor.red / 255.0;
    var endG = endColor.green / 255.0;
    var endB = endColor.blue / 255.0;

    // convert from sRGB to linear
    startR = _eocfSRgb(startR);
    startG = _eocfSRgb(startG);
    startB = _eocfSRgb(startB);

    endR = _eocfSRgb(endR);
    endG = _eocfSRgb(endG);
    endB = _eocfSRgb(endB);

    // compute the interpolated color in linear space
    var a = startA + fraction * (endA - startA);
    var r = startR + fraction * (endR - startR);
    var g = startG + fraction * (endG - startG);
    var b = startB + fraction * (endB - startB);

    // convert back to sRGB in the [0..255] range
    a = a * 255.0;
    r = _oecfSRgb(r) * 255.0;
    g = _oecfSRgb(g) * 255.0;
    b = _oecfSRgb(b) * 255.0;

    return Color.fromARGB(a.round(), r.round(), g.round(), b.round());
  }
}
