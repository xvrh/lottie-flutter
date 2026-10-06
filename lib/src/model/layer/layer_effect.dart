import 'dart:math' as math;
import 'dart:ui';

/// Draws Gaussian blur and drop shadow for one layer.
///
/// Callers should use this only when an effect is actually visible. Every
/// other layer keeps drawing directly, with no extra offscreen buffer.
class LayerEffectCompositor {
  static double sigmaForRadius(double radius) {
    if (radius <= 0) {
      return 0;
    }
    // Same radius-to-sigma conversion as lottie-android's BlurMaskFilter.
    return radius * 0.57735 + 0.5;
  }

  /// Keeps the offscreen rect inside the canvas clip so a large glow cannot
  /// allocate a texture bigger than the animation.
  static Rect limitToClip(Canvas canvas, Rect bounds) {
    if (bounds.isEmpty) {
      return Rect.zero;
    }
    var clip = canvas.getLocalClipBounds();
    if (clip.width > 100000 || clip.height > 100000) {
      return bounds;
    }
    var limited = bounds.intersect(clip);
    if (limited.isEmpty) {
      return Rect.zero;
    }
    return limited;
  }

  static void drawBlurred({
    required Canvas canvas,
    required Rect contentBounds,
    required ImageFilter filter,
    required Paint paint,
    required void Function(Canvas canvas) drawContent,
  }) {
    var bounds = limitToClip(canvas, contentBounds);
    if (bounds.isEmpty) {
      return;
    }
    paint
      ..colorFilter = null
      ..imageFilter = filter;
    canvas.saveLayer(bounds, paint);
    drawContent(canvas);
    canvas.restore();
  }

  static void drawDropShadow({
    required Canvas canvas,
    required Rect contentBounds,
    required Offset offset,
    required double sigma,
    required Color color,
    required Paint tintPaint,
    required Paint blurPaint,
    required ImageFilter? blurFilter,
    required Picture content,
  }) {
    if (color.a == 0) {
      return;
    }
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    var spread = math.max(sigma * 3, 1.0);
    var localBounds = limitToClip(canvas, contentBounds.inflate(spread));
    if (localBounds.isEmpty) {
      canvas.restore();
      return;
    }
    if (blurFilter != null) {
      blurPaint
        ..colorFilter = null
        ..imageFilter = blurFilter;
      canvas.saveLayer(localBounds, blurPaint);
    }
    tintPaint
      ..imageFilter = null
      ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    canvas.saveLayer(localBounds, tintPaint);
    canvas.drawPicture(content);
    canvas.restore();
    if (blurFilter != null) {
      canvas.restore();
    }
    canvas.restore();
  }
}
